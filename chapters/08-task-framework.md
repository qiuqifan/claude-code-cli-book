# 08 - 任务框架

> **摘要**
>
> 本章深入解析 Claude Code 的任务生命周期管理框架，这是支撑 CLI 长时间任务执行的核心系统。任务框架负责注册、跟踪、执行和清理各类任务（Shell 命令、子 Agent、MCP 监控等），确保任务状态持久化、可恢复，并提供实时输出流式传输能力。
>
> **关键概念:** 任务状态机、增量输出、轮询机制、任务持久化
>
> **前置知识:** 第 6 章（会话存储）、第 7 章（状态管理）
>
> **源码位置:** `src/tasks/types.ts`, `src/utils/task/framework.ts`, `src/utils/task/diskOutput.ts`

---

## 1. 概述

### 1.1 什么是任务框架？

在 Claude Code CLI 中，**任务框架 (Task Framework)** 是管理所有后台运行任务的生命周期系统。它统一处理多种类型的异步任务：

- **Shell 任务** - 后台 Bash 命令执行
- **Agent 任务** - 派生的子 Agent 进程
- **远程任务** - 在远程机器上运行的 Agent
- **MCP 监控** - 长期运行的 MCP 服务器监控
- **Dream 任务** - 低优先级的长期后台任务

### 1.2 为什么需要任务框架？

CLI 中的任务与传统同步调用不同，它们具有以下特点：

1. **长时间运行** - 可能持续数分钟甚至数小时
2. **后台执行** - 用户可以在任务运行时继续交互
3. **需要恢复** - 进程崩溃后能够重新连接
4. **输出流式** - 实时推送输出到用户界面
5. **资源隔离** - 独立进程空间，避免相互干扰

任务框架提供了统一的抽象来解决这些挑战。

### 1.3 核心能力

```
┌─────────────────────────────────────────────────────────┐
│                     Task Framework                       │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────┐    ┌──────────────┐    ┌───────────┐  │
│  │   注册与跟踪  │    │   执行与监控  │    │  输出管理  │  │
│  │              │    │              │    │           │  │
│  │ • 任务注册    │    │ • 进程派生    │    │ • 增量读取 │  │
│  │ • 状态更新    │    │ • 退出监听    │    │ • 流式推送 │  │
│  │ • 清理回收    │    │ • 轮询检查    │    │ • 文件缓存 │  │
│  └──────────────┘    └──────────────┘    └───────────┘  │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

---

## 2. 设计目标与约束

### 2.1 设计目标

| 目标 | 实现方式 |
|------|----------|
| **可靠性** | 任务状态持久化到 AppState，崩溃后可查询 |
| **可恢复性** | 存储 PID 和输出路径，支持重新连接 |
| **可观测性** | 实时推送输出增量，提供状态通知 |
| **低延迟** | 1 秒轮询间隔，平衡实时性与性能 |
| **资源效率** | 使用文件缓存输出，避免内存膨胀 |

### 2.2 关键约束

**约束 1: 不依赖数据库**

```typescript
// 任务状态存储在 AppState（Zustand）中
// 通过 SessionStorage 持久化到磁盘（JSONL）
export type AppState = {
  tasks: Record<string, TaskState>
  // ...
}
```

**约束 2: 输出增量读取**

```typescript
// 任务输出写入磁盘文件
// 使用 outputOffset 追踪已读位置
interface BaseTaskState {
  outputOffset: number  // 避免重复读取
  outputPath: string    // 输出文件路径
}
```

**约束 3: 轮询而非事件驱动**

```typescript
// 使用定时轮询检查任务状态（1000ms）
// 避免复杂的文件监听和进程事件处理
setInterval(async () => {
  const runningTasks = getRunningTasks(appState)
  for (const task of runningTasks) {
    await checkTaskStatus(task)
  }
}, 1000)
```

---

## 3. 核心架构

### 3.1 任务类型系统

任务框架使用 TypeScript 联合类型定义所有任务类型：

```typescript
// 任务状态联合类型
type TaskState =
  | LocalShellTaskState      // Bash 命令
  | LocalAgentTaskState      // 子 Agent
  | RemoteAgentTaskState     // 远程 Agent
  | InProcessTeammateTaskState // 多 Agent 协作
  | DreamTaskState           // 长期后台任务
  | MonitorMcpTaskState      // MCP 监控

// 基础任务接口
interface BaseTaskState {
  id: string                  // UUID
  type: TaskType
  status: 'pending' | 'running' | 'completed' | 'failed' | 'killed'
  toolUseId?: string          // 关联的工具调用 ID
  description: string
  startTime: number
  endTime?: number
  outputOffset: number        // 输出读取偏移
  notified: boolean           // 是否已通知用户
}

// Shell 任务扩展
interface LocalShellTaskState extends BaseTaskState {
  type: 'local_shell'
  command: string
  pid?: number               // 进程 ID（用于重连）
  isBackgrounded: boolean
  outputPath: string         // 输出文件路径
}
```

### 3.2 任务状态机

```
pending ──────> running ──────> completed
                  │                 │
                  │                 │
                  └─────> failed    │
                  │                 │
                  └─────> killed ───┘
```

**状态转换规则:**

- `pending` → `running`: 任务启动时
- `running` → `completed`: 任务成功完成（exit code 0）
- `running` → `failed`: 任务失败（exit code ≠ 0）
- `running` → `killed`: 用户主动终止
- 终态 (`completed/failed/killed`) → 任务被清理（`evictTerminalTask`）

### 3.3 任务注册流程

```typescript
// 1. 注册任务到全局状态
export function registerTask(
  task: TaskState,
  setAppState: SetAppState
): void {
  setAppState(prev => ({
    ...prev,
    tasks: {
      ...prev.tasks,
      [task.id]: task
    }
  }))

  // 2. 发送任务启动事件
  enqueueSdkEvent({
    type: 'system',
    subtype: 'task_started',
    task_id: task.id,
    description: task.description
  })
}
```

---

## 4. 关键实现

### 4.1 后台任务执行

以 Bash 工具为例，展示后台任务的完整生命周期：

```typescript
// 后台 Bash 命令执行
async function executeBackgroundBash(
  command: string,
  options: BashOptions,
  context: ToolUseContext
): Promise<ToolResult> {
  // 1. 生成任务 ID 和输出路径
  const taskId = randomUUID()
  const outputPath = getTaskOutputPath(taskId)

  // 2. 创建任务状态
  const task: LocalShellTaskState = {
    id: taskId,
    type: 'local_shell',
    status: 'running',
    command,
    description: `Running: ${command}`,
    startTime: Date.now(),
    outputOffset: 0,
    notified: false,
    isBackgrounded: true,
    outputPath
  }

  // 3. 注册任务
  registerTask(task, context.setAppState)

  // 4. 启动子进程
  const child = spawn('bash', ['-c', command], {
    stdio: ['ignore', 'pipe', 'pipe'],
    detached: true  // 独立进程组
  })

  // 5. 输出重定向到文件
  const outputStream = createWriteStream(outputPath)
  child.stdout.pipe(outputStream)
  child.stderr.pipe(outputStream)

  // 6. 监听进程退出
  child.on('exit', (code) => {
    updateTaskState(taskId, context.setAppState, task => ({
      ...task,
      status: code === 0 ? 'completed' : 'failed',
      endTime: Date.now()
    }))
  })

  // 7. 返回轻量级结果
  return {
    type: 'text',
    text: `Task started (ID: ${taskId}). Running in background.`
  }
}
```

### 4.2 任务状态更新

```typescript
// 原子更新任务状态
export function updateTaskState<T extends TaskState>(
  taskId: string,
  setAppState: SetAppState,
  updater: (task: T) => T
): void {
  setAppState(prev => {
    const task = prev.tasks?.[taskId] as T | undefined
    if (!task) return prev

    const updated = updater(task)
    if (updated === task) return prev  // 无变化，跳过更新

    return {
      ...prev,
      tasks: {
        ...prev.tasks,
        [taskId]: updated
      }
    }
  })
}
```

### 4.3 输出增量读取

```typescript
// 增量读取任务输出
export async function getTaskOutputDelta(
  taskId: string,
  currentOffset: number
): Promise<{ content: string; newOffset: number }> {
  const outputPath = getTaskOutputPath(taskId)

  // 获取文件大小
  const stats = await stat(outputPath)
  const fileSize = stats.size

  if (fileSize <= currentOffset) {
    return { content: '', newOffset: currentOffset }
  }

  // 只读取新增部分
  const fd = await fsOpen(outputPath, 'r')
  const buffer = Buffer.alloc(fileSize - currentOffset)
  await fd.read(buffer, 0, buffer.length, currentOffset)
  await fd.close()

  return {
    content: buffer.toString('utf8'),
    newOffset: fileSize
  }
}

// 获取任务输出文件路径
export function getTaskOutputPath(taskId: string): string {
  return join(getProjectRoot(), '.claude', 'task_outputs', `${taskId}.txt`)
}
```

### 4.4 轮询机制

```typescript
// 任务输出轮询（1 秒间隔）
setInterval(async () => {
  const runningTasks = getRunningTasks(appState)

  for (const task of runningTasks) {
    // 读取新输出
    const delta = await getTaskOutputDelta(task.id, task.outputOffset)

    if (delta.content) {
      // 更新偏移量
      updateTaskState(task.id, setAppState, t => ({
        ...t,
        outputOffset: delta.newOffset
      }))

      // 生成通知
      enqueuePendingNotification({
        type: 'task_output',
        taskId: task.id,
        content: delta.content
      })
    }
  }
}, POLL_INTERVAL_MS)  // 1000ms
```

### 4.5 任务清理

```typescript
// 清理终态任务
export function evictTerminalTask(
  taskId: string,
  setAppState: SetAppState
): void {
  setAppState(prev => {
    const task = prev.tasks?.[taskId]
    if (!task || !isTerminalTaskStatus(task.status)) return prev
    if (!task.notified) return prev  // 等待用户确认

    // 移除任务
    const { [taskId]: _, ...remainingTasks } = prev.tasks
    return { ...prev, tasks: remainingTasks }
  })
}
```

---

## 5. 设计权衡

### 5.1 为什么需要持久化任务状态？

**问题:** 如果任务状态仅在内存中，CLI 崩溃后用户无法查询任务结果。

**解决方案:** 将任务状态注册到 `AppState`，通过 `SessionStorage` 持久化到磁盘（JSONL）。

```typescript
// 任务状态持久化流程
registerTask(task, setAppState)  // 写入 AppState
  ↓
AppState 变化触发 SessionStorage 更新
  ↓
追加到 transcript.jsonl
```

**权衡:**

- ✅ 优点: 崩溃恢复、历史查询
- ❌ 缺点: 磁盘 I/O 开销（通过批量写入缓解）

### 5.2 为什么使用轮询而非事件驱动？

**备选方案:**

1. **文件监听 (chokidar)** - 监听输出文件变化
2. **进程事件 (child.on('data'))** - 直接监听 stdout

**选择轮询的原因:**

- **简单可靠** - 避免文件监听的边缘情况（大文件、快速写入）
- **统一接口** - 本地任务和远程任务使用相同的轮询逻辑
- **可恢复性** - 进程重启后可以继续轮询，无需重建事件监听器

**权衡:**

- ✅ 优点: 实现简单、易于调试、支持恢复
- ❌ 缺点: 1 秒延迟（对 CLI 场景可接受）

### 5.3 为什么任务框架独立于 Session？

**设计决策:** 任务框架不直接访问 `SessionStorage`，而是通过 `AppState` 交互。

**原因:**

1. **解耦** - 任务框架可以在非会话场景使用（例如测试）
2. **状态一致性** - 所有状态变更通过 `setAppState` 统一管理
3. **可扩展性** - 未来可以支持跨会话的任务（例如全局后台任务）

---

## 6. 与其他系统的关联

### 6.1 依赖的系统

Task Framework 依赖以下系统提供支撑:

#### 1. [07-state-management.md](./07-state-management.md) - 状态管理
**依赖关系**: Task Framework 通过 AppState 管理所有任务状态。

**依赖点**:
- `AppState.tasks`: 存储所有任务状态（任务字典）
- `registerTask()`: 将任务注册到 AppState
- `updateTaskState()`: 原子更新任务状态
- `evictTerminalTask()`: 清理完成的任务

**数据流**: `创建任务` → `注册到 AppState.tasks` → `轮询更新` → `清理任务`

**建议阅读顺序**: 先阅读 07 章了解 AppState 的结构和更新模式，再学习任务框架如何使用它。

#### 2. [09-cron-scheduler.md](./09-cron-scheduler.md) - 定时调度器
**依赖关系**: Task Framework 的轮询机制基于定时调度。

**依赖点**:
- 使用 1 秒间隔的轮询检查任务状态
- 定时读取任务输出增量
- 定时通知用户任务完成

**数据流**: `Cron 触发` → `检查任务状态` → `读取输出增量` → `更新 AppState`

**阅读建议**: 理解定时调度机制后，更容易理解任务轮询的实现。

### 6.2 被依赖的系统

以下系统依赖 Task Framework 管理后台任务:

#### 1. [10-multi-agent.md](./10-multi-agent.md) - 多 Agent 系统
**被依赖关系**: Agent Tool 使用 Task Framework 管理子 Agent 进程。

**依赖点**:
- 子 Agent 作为 `LocalAgentTaskState` 注册到任务框架
- 通过任务框架跟踪 Agent 的生命周期
- 轮询 Agent 的输出和状态变化

**数据流**: `派生 Agent` → `注册为任务` → `轮询状态` → `通知完成`

**示例代码**:
```typescript
// AgentTool 使用任务框架
const task: LocalAgentTaskState = {
  type: 'local_agent',
  id: agentId,
  status: 'running',
  agentName: 'researcher',
  // ...
}

registerTask(task, context.setAppState)
```

**阅读建议**: 理解任务框架后，阅读 10 章了解子 Agent 如何作为任务管理。

#### 2. [11-bash-tool.md](./11-bash-tool.md) - Bash 工具
**被依赖关系**: Bash Tool 使用 Task Framework 管理后台命令。

**依赖点**:
- 后台命令作为 `LocalShellTaskState` 注册到任务框架
- 通过任务框架跟踪命令执行状态
- 轮询命令的输出和退出码

**数据流**: `后台命令` → `注册为任务` → `轮询输出` → `命令完成`

**集成示例**:
```typescript
// BashTool 使用任务框架
export function BashTool({
  command,
  run_in_background,
  context
}: BashToolProps): ToolResult {
  if (run_in_background) {
    // 1. 创建任务状态
    const task = createShellTask(command)

    // 2. 注册到任务框架
    registerTask(task, context.setAppState)

    // 3. 启动后台进程
    const child = spawnBackgroundProcess(command, task.outputPath)

    // 4. 监听退出
    child.on('exit', (code) => {
      updateTaskState(task.id, context.setAppState, t => ({
        ...t,
        status: code === 0 ? 'completed' : 'failed'
      }))
    })

    return { type: 'text', text: `Task ${task.id} started` }
  } else {
    // 前台执行（同步）
    return execSync(command)
  }
}
```

### 6.3 协作关系

Task Framework 与多个系统密切协作，以下是典型的协作场景:

#### 场景 1: 后台命令执行

```
用户输入: "后台运行 npm install"
  ↓
QueryEngine 调用 Bash Tool (run_in_background: true)
  ↓
Bash Tool:
  ├→ 创建 LocalShellTaskState
  ├→ registerTask(task, setAppState)
  │   └→ AppState.tasks[taskId] = task
  ├→ 启动子进程 (detached: true)
  ├→ 输出重定向到文件
  └→ 返回 "Task started" 消息
  ↓
Task Framework 轮询 (1000ms 间隔):
  ├→ 读取 AppState.tasks
  ├→ 检查进程状态 (通过 PID)
  ├→ 读取输出增量
  │   └→ getTaskOutputDelta(taskId, currentOffset)
  ├→ 更新 AppState.tasks[taskId]
  │   └→ outputOffset, status
  └→ 推送通知给用户
  ↓
任务完成:
  ├→ updateTaskState(taskId, ..., { status: 'completed' })
  ├→ 用户确认通知
  └→ evictTerminalTask(taskId)
      └→ 从 AppState.tasks 中移除
```

**涉及章节**:
- [04-tool-system.md](./04-tool-system.md): Bash Tool 的实现
- [07-state-management.md](./07-state-management.md): AppState 的状态管理
- [09-cron-scheduler.md](./09-cron-scheduler.md): 轮询机制

#### 场景 2: 子 Agent 管理

```
用户输入: "派生一个 Agent 研究项目"
  ↓
QueryEngine 调用 Agent Tool
  ↓
Agent Tool:
  ├→ 创建 LocalAgentTaskState
  ├→ registerTask(task, setAppState)
  ├→ 派生子进程 (fork)
  │   └→ 子进程运行独立的 QueryEngine
  └→ 返回 "Agent started" 消息
  ↓
Task Framework 轮询:
  ├→ 读取 Agent 输出增量
  ├→ 检查 Agent 状态
  ├→→ 更新 AppState.tasks[agentId]
  └→ 推送 Agent 消息给用户
  ↓
Agent 完成:
  ├→ updateTaskState(agentId, ..., { status: 'completed' })
  ├→ 返回 Agent 最终结果
  └→ 清理 Agent 任务
```

**涉及章节**:
- [10-multi-agent.md](./10-multi-agent.md): Agent Tool 的实现
- [07-state-management.md](./07-state-management.md): Agent 状态管理

### 6.4 阅读路径建议

**前置阅读** (理解上下文):
1. [07-state-management.md](./07-state-management.md) - 了解 AppState 的结构和更新模式
2. [09-cron-scheduler.md](./09-cron-scheduler.md) - 可选，了解定时调度机制

**后续阅读** (深入应用):
1. [10-multi-agent.md](./10-multi-agent.md) - 了解子 Agent 如何作为任务管理
2. [11-bash-tool.md](./11-bash-tool.md) - 了解后台命令如何使用任务框架

---

## 7. 总结

### 7.1 核心要点

1. **任务框架是 Harness 的核心组件**，负责所有后台任务的生命周期管理
2. **使用 AppState 持久化任务状态**，支持崩溃恢复和历史查询
3. **输出增量读取 + 轮询机制**，平衡实时性与性能
4. **文件缓存输出**，避免大输出导致内存膨胀
5. **统一抽象**，支持多种任务类型（Shell、Agent、远程、MCP）

### 7.2 关键指标

| 指标 | 值 | 说明 |
|------|-----|------|
| 任务轮询间隔 | 1000ms | 平衡实时性与 CPU 使用 |
| 输出读取方式 | 增量 | 避免重复读取大文件 |
| 任务清理时机 | 用户确认后 | 防止过早释放资源 |
| 进程隔离 | `detached: true` | 独立进程组，避免信号传播 |

### 7.3 最佳实践

**✅ 正确使用:**

```typescript
// 1. 始终注册任务
registerTask(task, setAppState)

// 2. 使用原子更新
updateTaskState(taskId, setAppState, t => ({ ...t, status: 'completed' }))

// 3. 在终态后清理
if (task.status === 'completed' && task.notified) {
  evictTerminalTask(taskId, setAppState)
}
```

**❌ 避免:**

```typescript
// 直接修改任务对象（破坏不可变性）
task.status = 'completed'  // ❌

// 跳过注册直接启动进程（无法追踪）
spawn('bash', ['-c', command])  // ❌

// 不清理终态任务（内存泄漏）
// ❌
```

### 7.4 扩展阅读

- 第 6 章: 会话存储 - 了解任务状态如何持久化
- 第 7 章: 状态管理 - 了解 AppState 架构
- 第 9 章: 定时调度器 - 了解定时任务如何触发

---

**章节信息**
- **难度:** ⭐⭐⭐ 高级
- **字数:** ~3800 字
- **代码行数:** ~180 行
- **最后更新:** 2026-03-31
