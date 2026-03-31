# 07 - State Management 状态管理

> **摘要**
>
> 本章深入解析 Claude Code CLI 的状态管理系统。AppState 是整个应用的全局状态中心,管理着对话历史、任务状态、权限配置、UI 状态等 70+ 个字段。通过轻量级的 Store 实现和 React 的 useSyncExternalStore Hook,系统实现了高性能的细粒度订阅和 Immutable 更新模式。本章将剖析状态管理的设计理念、核心架构、更新模式以及与其他系统的协作机制。
>
> **关键概念:** AppState、Store 模式、Immutable 更新、选择器模式、状态订阅
>
> **前置知识:** TypeScript 基础、React Hooks、00-overview.md (架构总览)
>
> **源码位置:** `src/state/AppState.tsx`, `src/state/AppStateStore.ts`, `src/state/store.ts`

---

## 第 1 节:概述

### 1.1 AppState 的职责

**AppState** 是 Claude Code CLI 的全局状态中心,负责管理应用运行时的所有关键数据。它是一个单一的、不可变的状态树,包含以下核心领域:

#### 1.1.1 对话状态
- **消息历史**: 虽然主要存储在 QueryEngine 中,但 UI 相关的消息选择状态由 AppState 管理
- **模型配置**: `mainLoopModel` (当前会话模型)、`mainLoopModelForSession` (会话开始时的模型)
- **Thinking 模式**: `thinkingEnabled` 控制是否启用扩展思考模式
- **提示建议**: `promptSuggestion` 存储 AI 生成的下一步建议

#### 1.1.2 任务与 Agent 状态
- **后台任务**: `tasks` 字典存储所有后台任务 (Agent 调用、Shell 命令、Dream 任务)
- **Agent 注册表**: `agentNameRegistry` 维护 Agent 名称到 ID 的映射
- **团队协作**: `teamContext` 存储 Swarm 团队的成员信息、Tmux 会话等
- **任务视图**: `foregroundedTaskId` 和 `viewingAgentTaskId` 控制当前查看的任务

#### 1.1.3 权限与配置
- **权限上下文**: `toolPermissionContext` 包含权限模式、规则、历史决策
- **用户���置**: `settings` 存储用户的所有配置项 (从 `~/.claude/settings.json` 加载)
- **Bridge 状态**: `replBridgeEnabled`、`replBridgeConnected` 等控制远程连接
- **拒绝追踪**: `denialTracking` 跟踪权限拒绝次数,用于模式降级

#### 1.1.4 UI 状态
- **展开视图**: `expandedView` 控制任务列表或团队视图的展开状态
- **Footer 选择**: `footerSelection` 跟踪底部 Pill 的焦点状态 (tasks/tmux/teams/bridge)
- **Spinner 提示**: `spinnerTip` 显示当前正在执行的操作
- **覆盖层管理**: `activeOverlays` 追踪当前打开的对话框 (用于 Escape 键协调)

#### 1.1.5 集成状态
- **MCP 状态**: `mcp.clients`、`mcp.tools` 存储 MCP 服务器连接和工具
- **插件状态**: `plugins.enabled`、`plugins.disabled` 管理插件加载状态
- **Tmux 状态**: `tungstenActiveSession` 存储当前 Tmux 会话信息
- **WebBrowser 状态**: `bagelActive`、`bagelUrl` 管理浏览器工具状态

### 1.2 为什么需要全局状态管理?

在一个复杂的终端应用中,全局状态管理解决了以下关键问题:

#### 1.2.1 跨组件通信
- **问题**: Terminal UI 由多个 React 组件组成 (REPL、Messages、PromptInput、StatusLine),它们分布在不同的层级
- **解决**: 通过 AppState 提供单一数据源,任何组件都可以订阅所需的状态切片

#### 1.2.2 状态同步
- **问题**: 后台任务状态、权限决策、模型配置变更需要同步到多个系统
- **解决**: `onChangeAppState` 钩子监听状态变化,自动触发副作用 (如保存配置、通知 CCR)

#### 1.2.3 状态持久化
- **问题**: 用户配置、权限规则需要在会话间保留
- **解决**: 关键状态字段通过 `globalConfig.json` 和 `settings.json` 持久化

#### 1.2.4 可测试性
- **问题**: 直接操作全局变量的代码难以测试
- **解决**: AppState 是纯数据结构,可轻松创建测试用例的初始状态

### 1.3 在架构中的位置

AppState 位于 **Layer 3: 状态管理层**,是所有层级的数据枢纽:

```
┌───────────────────────────────────────────────────┐
│ Layer 5: 交互层                                    │
│   REPL UI, SDK Interface                          │
│   ↓ useAppState(selector)                         │
└───────────────────┬───────────────────────────────┘
                    │ 订阅
                    ↓
┌──────────────────────────────────────────���────────┐
│ Layer 3: 状态管理层                                │
│   ┌─────────────────────────────────────────────┐ │
│   │ AppState (全局状态树)                       │ │
│   │  ├─ tasks: { [id]: TaskState }             │ │
│   │  ├─ toolPermissionContext                  │ │
│   │  ├─ settings: SettingsJson                 │ │
│   │  ├─ mcp: { clients, tools }                │ │
│   │  ├─ expandedView, footerSelection          │ │
│   │  └─ teamContext, agentNameRegistry         │ │
│   └─────────────────────────────────────────────┘ │
│   ┌─────────────────────────────────────────────┐ │
│   │ Store (状态容器)                            │ │
│   │  ├─ getState(): AppState                   │ │
│   │  ├─ setState(updater)                      │ │
│   │  └─ subscribe(listener)                    │ │
│   └─────────────────────────────────────────────┘ │
└───────────────────┬───────────────────────────────┘
                    │ 依赖
                    ↓
┌───────────────────────────────────────────────────┐
│ Layer 4: 应用层                                    │
│   QueryEngine, Task Framework, Permission System  │
│   ↓ setState(prev => ({ ...prev, ... }))         │
└───────────────────────────────────────────────────┘
```

**数据流示例** (用户切换权限模式):

1. **用户操作** → 按 `Shift+Tab` 循环权限模式
2. **REPL UI** → 调用 `setAppState(prev => ({ ...prev, toolPermissionContext: { ...prev.toolPermissionContext, mode: 'auto' } }))`
3. **Store** → 检测到状态变化,调用 `onChangeAppState()`
4. **onChangeAppState** → 通知 CCR 更新 `external_metadata.permission_mode`
5. **Store** → 通知所有订阅者
6. **StatusLine** → `useAppState(s => s.toolPermissionContext.mode)` ��发重渲染,显示新模式

---

## 第 2 节:设计目标与约束

### 2.1 设计目标

#### 目标 1: Immutable 更新模式

**要求**: 所有状态更新必须返回新对象,不能直接修改现有状态。

**理由**:
- **性能优化**: React 通过 `Object.is()` 快速检测变化
- **时间旅行调试**: 保留历史状态快照
- **并发安全**: 避免多个更新路径互相干扰

**实现**:
```typescript
// ✅ 正确: 返回新对象
setState(prev => ({
  ...prev,
  verbose: true
}))

// ❌ 错误: 直接修改
setState(prev => {
  prev.verbose = true  // 破坏了 Immutability!
  return prev
})
```

#### 目标 2: 细粒度订阅

**要求**: 组件应只订阅它们关心的状态切片,避免不必要的重渲染。

**理由**:
- **性能**: 减少 React 重渲染次数
- **可维护性**: 明确组件的依赖关系

**实现**:
```typescript
// ✅ 正确: 只订阅单个字段
const verbose = useAppState(s => s.verbose)
const model = useAppState(s => s.mainLoopModel)

// ❌ 错误: 订阅整个状态树
const state = useAppState(s => s)  // 任何字段变化都会触发重渲染!
```

#### 目标 3: 类型安全

**要求**: 所有状态字段必须有明确的 TypeScript 类型定义。

**实现**:
- `AppState` 类型由 `AppStateStore.ts` 集中定义
- 使用 `DeepImmutable<T>` 工具类型标记不可变字段
- 特殊字段 (如 `tasks`) 排除在 `DeepImmutable` 外,因为包含函数类型

#### 目标 4: 副作用隔离

**要求**: 状态更新本身不应触发副作用,副作用应在 `onChangeAppState` 中集中处理。

**理由**:
- **可预测性**: 状态更新是纯函数,易于测试
- **单一职责**: 副作用逻辑与状态逻辑分离

### 2.2 技术约束

#### 约束 1: 不使用 Redux/MobX

**原因**:
- **复杂度**: Redux 需要定义 Actions、Reducers、Middleware,增加样板代码
- **体积**: MobX 依赖较大,不适合 CLI 应用
- **控制**: 自定义 Store 更灵活,可完全控制更新逻辑

**解决方案**: 实现轻量级 Store (只有 35 行代码),基于 React 的 `useSyncExternalStore`。

#### 约束 2: 避免嵌套状态的深度复制

**原因**: 深度嵌套对象 (如 `mcp.clients[0].tools`) 频繁更新时,需要复制整个路径。

**解决方案**:
- **选择性更新**: 只复制变化的路径
- **引用保留**: 未变化的子对象保持原引用
- **Immer.js 考量**: 未引入 Immer 是因为 CLI 应用对体积敏感,手动更新足够

#### 约束 3: 非持久化字段

**设计决策**: 大部分状态是临时的,不持久化到磁盘。

**持久化字段** (仅限):
- `settings` → `~/.claude/settings.json`
- `verbose`, `expandedView` → `~/.claude/globalConfig.json`
- `mainLoopModel` → `~/.claude/settings.json` (作为 `model` 字段)

**非持久化字段** (会话特定):
- `tasks`, `messages`, `notifications`
- `replBridgeConnected`, `remoteSessionUrl`
- `promptSuggestion`, `speculation`

### 2.3 非目标

以下是 **明确不包含** 在状态管理系统中的内容:

#### 非目标 1: 对话历史存储
- **理由**: 消息数组在 QueryEngine 中管理,AppState 只存储引用或 UI 相关的索引
- **例外**: `foregroundedTaskId` 指向哪个任务的消息应显示

#### 非目标 2: 文件系统状态
- **理由**: 文件内容不存储在内存中,每次读取都直接访问磁盘
- **例外**: `fileHistory` 存储文件快照的元数据 (路径、时间戳),但不存储内容

#### 非目标 3: 网络请求缓存
- **理由**: API 响应不缓存在 AppState 中
- **例外**: MCP 资源 (`mcp.resources`) 缓存服务器提供的资源列表

---

## 第 3 节:核心架构

### 3.1 AppState 类型定义

`AppState` 是一个包含 70+ 字段的大型类型,以下是关键字段分类:

#### 3.1.1 配置与模型
```typescript
export type AppState = DeepImmutable<{
  // 用户配置 (从 settings.json 加载)
  settings: SettingsJson

  // 当前会话的主模型 (可通过 /model 命令修改)
  mainLoopModel: ModelSetting  // null 表示使用默认模型

  // 会话开始时的模型 (用于恢复)
  mainLoopModelForSession: ModelSetting

  // Verbose 模式 (显示详细日志)
  verbose: boolean

  // Thinking 模式 (扩展推理)
  thinkingEnabled: boolean | undefined

  // Agent 名称 (从 --agent 参数或 settings 读取)
  agent: string | undefined
}>
```

#### 3.1.2 权限系统
```typescript
export type AppState = DeepImmutable<{
  // 权限上下文 (包含模式、规则、历史)
  toolPermissionContext: ToolPermissionContext

  // 权限拒绝追踪 (用于自动降级)
  denialTracking?: DenialTrackingState

  // 初始消息 (携带权限模式)
  initialMessage: {
    message: UserMessage
    mode?: PermissionMode
    allowedPrompts?: AllowedPrompt[]  // 计划模式的预批准提示
  } | null
}>
```

`ToolPermissionContext` 的核心字段:
```typescript
type ToolPermissionContext = {
  mode: PermissionMode  // 'default' | 'auto' | 'plan' | 'bypassPermissions'
  rules: PermissionRule[]  // 用户定义的规则
  recentDecisions: Decision[]  // 最近的权限决策历史
  isBypassPermissionsModeAvailable: boolean  // 是否可用 Bypass 模式
}
```

#### 3.1.3 任务与 Agent
```typescript
export type AppState = {
  // 任务字典 (不使用 DeepImmutable,因为包含函数)
  tasks: { [taskId: string]: TaskState }

  // Agent 名称到 ID 的映射
  agentNameRegistry: Map<string, AgentId>

  // 当前前台任务 ID
  foregroundedTaskId?: string

  // 当前查看的 Agent 任务 ID
  viewingAgentTaskId?: string

  // 团队上下文 (Swarm 模式)
  teamContext?: {
    teamName: string
    leadAgentId: string
    teammates: {
      [teammateId: string]: {
        name: string
        tmuxSessionName: string
        tmuxPaneId: string
        cwd: string
        spawnedAt: number
      }
    }
  }
}
```

#### 3.1.4 UI 状态
```typescript
export type AppState = DeepImmutable<{
  // 状态栏文本
  statusLineText: string | undefined

  // 展开视图 ('none' | 'tasks' | 'teammates')
  expandedView: 'none' | 'tasks' | 'teammates'

  // Footer Pill 选择
  footerSelection: FooterItem | null  // 'tasks' | 'tmux' | 'teams' | 'bridge' | 'companion'

  // Spinner 提示文本
  spinnerTip?: string

  // 活动覆盖层 (用于 Escape 键协调)
  activeOverlays: ReadonlySet<string>

  // Coordinator 任务面板选择索引
  coordinatorTaskIndex: number
}>
```

#### 3.1.5 MCP 与插件
```typescript
export type AppState = {
  mcp: {
    clients: MCPServerConnection[]  // MCP 服务器连接
    tools: Tool[]  // MCP 提供的工具
    commands: Command[]  // MCP 提供的命令
    resources: Record<string, ServerResource[]>  // MCP 资源
    pluginReconnectKey: number  // 触发 MCP 重连的计数器
  }

  plugins: {
    enabled: LoadedPlugin[]
    disabled: LoadedPlugin[]
    commands: Command[]
    errors: PluginError[]
    installationStatus: {
      marketplaces: Array<{ name: string; status: string }>
      plugins: Array<{ id: string; name: string; status: string }>
    }
    needsRefresh: boolean  // 是否需要 /reload-plugins
  }
}
```

#### 3.1.6 提示与通知
```typescript
export type AppState = DeepImmutable<{
  // 提示建议 (AI 生成的下一步建议)
  promptSuggestion: {
    text: string | null
    promptId: 'user_intent' | 'stated_intent' | null
    shownAt: number
    acceptedAt: number
    generationRequestId: string | null
  }

  // 推测执行状态
  speculation: SpeculationState

  // 通知队列
  notifications: {
    current: Notification | null
    queue: Notification[]
  }

  // Skill 改进建议
  skillImprovement: {
    suggestion: {
      skillName: string
      updates: { section: string; change: string; reason: string }[]
    } | null
  }
}>
```

#### 3.1.7 Bridge 与远程连接
```typescript
export type AppState = DeepImmutable<{
  // Bridge 启用状态
  replBridgeEnabled: boolean
  replBridgeConnected: boolean  // 环境已注册
  replBridgeSessionActive: boolean  // WebSocket 已连接
  replBridgeReconnecting: boolean  // 错误重试中

  // Bridge 连接信息
  replBridgeConnectUrl: string | undefined  // 供用户访问的 URL
  replBridgeSessionUrl: string | undefined  // claude.ai 上的会话 URL
  replBridgeEnvironmentId: string | undefined
  replBridgeSessionId: string | undefined
  replBridgeError: string | undefined

  // Remote Viewer 状态 (claude assistant 命令)
  remoteSessionUrl: string | undefined
  remoteConnectionStatus: 'connecting' | 'connected' | 'reconnecting' | 'disconnected'
  remoteBackgroundTaskCount: number
}>
```

### 3.2 Store 实现

Store 是一个轻量级的状态容器,提供三个核心方法:

#### 3.2.1 Store 类型定义

**文件**: `src/state/store.ts`

```typescript
type Listener = () => void
type OnChange<T> = (args: { newState: T; oldState: T }) => void

export type Store<T> = {
  getState: () => T
  setState: (updater: (prev: T) => T) => void
  subscribe: (listener: Listener) => () => void
}
```

**核心方法**:
1. **getState()**: 获取当前状态快照 (同步操作)
2. **setState(updater)**: 通过 updater 函数更新状态
3. **subscribe(listener)**: 订阅状态变化,返回取消订阅函数

#### 3.2.2 createStore 实现

```typescript
export function createStore<T>(
  initialState: T,
  onChange?: OnChange<T>,
): Store<T> {
  let state = initialState
  const listeners = new Set<Listener>()

  return {
    getState: () => state,

    setState: (updater: (prev: T) => T) => {
      const prev = state
      const next = updater(prev)
      if (Object.is(next, prev)) return  // 优化: 未变化则跳过
      state = next
      onChange?.({ newState: next, oldState: prev })  // 触发副作用
      for (const listener of listeners) listener()  // 通知订阅者
    },

    subscribe: (listener: Listener) => {
      listeners.add(listener)
      return () => listeners.delete(listener)  // 返回取消订阅函数
    },
  }
}
```

**关键设计决策**:
- **`Object.is()` 检查**: 如果 updater 返回相同引用,跳过通知 (性能优化)
- **`onChange` 钩子**: 在通知 listeners 之前执行,用于副作用 (如持久化)
- **Set 存储 listeners**: 避免重复订阅,O(1) 添加/删除

### 3.3 React 集成 (AppStateProvider)

#### 3.3.1 Context 设置

**文件**: `src/state/AppState.tsx`

```typescript
const AppStoreContext = React.createContext<AppStateStore | null>(null)

export function AppStateProvider({
  children,
  initialState,
  onChangeAppState,
}: Props): React.ReactNode {
  // Store 在组件生命周期内保持稳定
  const [store] = useState(() =>
    createStore<AppState>(
      initialState ?? getDefaultAppState(),
      onChangeAppState,
    ),
  )

  return (
    <AppStoreContext.Provider value={store}>
      <MailboxProvider>
        <VoiceProvider>{children}</VoiceProvider>
      </MailboxProvider>
    </AppStoreContext.Provider>
  )
}
```

**关键点**:
- **单例 Store**: `useState(() => createStore(...))` 确保 Store 只创建一次
- **稳定 Context 值**: Store 引用不变,Provider 不会触发不必要的重渲染
- **嵌套 Providers**: MailboxProvider 和 VoiceProvider 依赖 AppState

#### 3.3.2 useAppState Hook

```typescript
export function useAppState<T>(selector: (state: AppState) => T): T {
  const store = useAppStore()  // 从 Context 获取 Store

  const get = () => {
    const state = store.getState()
    return selector(state)
  }

  // 使用 React 18 的 useSyncExternalStore
  return useSyncExternalStore(store.subscribe, get, get)
}
```

**工作原理**:
1. **selector 函数**: 用户提供选择器,提取状态切片
2. **useSyncExternalStore**: React 18 新 Hook,支持外部 Store
   - 第一个参数: 订阅函数 (`store.subscribe`)
   - 第二个参数: 获取当前值的函数 (`get`)
   - 第三个参数: 服务端渲染的获取函数 (这里与第二个相同)
3. **自动重渲染**: 当 `selector` 返回的值变化时 (通过 `Object.is` 比较),组件重新渲染

**使用示例**:
```typescript
function StatusLine() {
  const mode = useAppState(s => s.toolPermissionContext.mode)
  const verbose = useAppState(s => s.verbose)

  return <Text>{mode} | {verbose ? 'verbose' : 'quiet'}</Text>
}
```

**性能优化**:
```typescript
// ✅ 好: 选择单个字段
const verbose = useAppState(s => s.verbose)

// ✅ 好: 选择嵌套对象的引用
const { text, promptId } = useAppState(s => s.promptSuggestion)

// ❌ 坏: 创建新对象 (每次 selector 调用都返回新引用)
const data = useAppState(s => ({ verbose: s.verbose, model: s.mainLoopModel }))
// 这会导致每次状态更新都触发重渲染!
```

#### 3.3.3 useSetAppState Hook

```typescript
export function useSetAppState(): (updater: (prev: AppState) => AppState) => void {
  return useAppStore().setState
}
```

**使用场景**: 组件只需要更新状态,不需要订阅状态。

**示例**:
```typescript
function ToggleVerboseButton() {
  const setAppState = useSetAppState()

  return (
    <Button
      onClick={() => {
        setAppState(prev => ({ ...prev, verbose: !prev.verbose }))
      }}
    >
      Toggle Verbose
    </Button>
  )
}
```

**优势**: 组件不会因为 `verbose` 的变化而重渲染 (因为没有调用 `useAppState`)。

### 3.4 选择器模式

为了提高代码复用性和可测试性,常用的选择器应提取为独立函数。

**文件**: `src/state/selectors.ts`

```typescript
/**
 * 获取当前查看的 Teammate 任务
 */
export function getViewedTeammateTask(
  appState: Pick<AppState, 'viewingAgentTaskId' | 'tasks'>,
): InProcessTeammateTaskState | undefined {
  const { viewingAgentTaskId, tasks } = appState

  if (!viewingAgentTaskId) return undefined

  const task = tasks[viewingAgentTaskId]
  if (!task || !isInProcessTeammateTask(task)) return undefined

  return task
}

/**
 * 确定用户输入应路由到哪里
 */
export function getActiveAgentForInput(
  appState: AppState,
): ActiveAgentForInput {
  const viewedTask = getViewedTeammateTask(appState)
  if (viewedTask) {
    return { type: 'viewed', task: viewedTask }
  }

  const { viewingAgentTaskId, tasks } = appState
  if (viewingAgentTaskId) {
    const task = tasks[viewingAgentTaskId]
    if (task?.type === 'local_agent') {
      return { type: 'named_agent', task }
    }
  }

  return { type: 'leader' }
}
```

**使用示例**:
```typescript
function PromptInput() {
  const appState = useAppState(s => s)  // 或者传递 getState
  const activeAgent = getActiveAgentForInput(appState)

  if (activeAgent.type === 'viewed') {
    // 将输入发送给查看的 Agent
    submitToAgent(activeAgent.task.id, input)
  } else {
    // 发送给主会话
    submitToMain(input)
  }
}
```

### 3.5 架构图

以下是 State Management 系统的整体架构。架构图已创建在 `assets/diagrams/state-architecture.mmd` 中。

---

## 第 4 节:关键实现

### 4.1 Immutable 更新模式

所有状态更新必须遵循 Immutable 原则:返回新对象,不修改原对象。

#### 4.1.1 浅层更新

**场景**: 更新根级别的字段。

**示例**: 切换 Verbose 模式
```typescript
setState(prev => ({
  ...prev,
  verbose: !prev.verbose
}))
```

**关键点**:
- `...prev` 展开所有字段
- 新的 `verbose` 覆盖旧值
- 其他字段保持原引用

#### 4.1.2 深层更新

**场景**: 更新嵌套对象的字段。

**示例**: 更改权限模式
```typescript
setState(prev => ({
  ...prev,
  toolPermissionContext: {
    ...prev.toolPermissionContext,
    mode: 'auto'
  }
}))
```

**路径**: `AppState` → `toolPermissionContext` → `mode`

**复制路径**: 必须复制整个路径上的对象。

#### 4.1.3 数组更新

**场景**: 添加、删除或修改数组元素。

**示例 1**: 添加 MCP 客户端
```typescript
setState(prev => ({
  ...prev,
  mcp: {
    ...prev.mcp,
    clients: [...prev.mcp.clients, newClient]
  }
}))
```

**示例 2**: 更新数组中的元素 (按条件)
```typescript
setState(prev => ({
  ...prev,
  mcp: {
    ...prev.mcp,
    clients: prev.mcp.clients.map(c =>
      c.name === targetName
        ? { ...c, status: 'connected' }  // 更新匹配的元素
        : c  // 保持原引用
    )
  }
}))
```

**示例 3**: 删除元素
```typescript
setState(prev => ({
  ...prev,
  notifications: {
    ...prev.notifications,
    queue: prev.notifications.queue.filter(n => n.id !== notificationId)
  }
}))
```

#### 4.1.4 条件更新

**场景**: 只有在满足条件时才更新状态。

**示例**: 避免不必要的更新
```typescript
setState(prev => {
  const nextMode = computeNextMode(prev.toolPermissionContext)

  // 如果模式未变化,返回原状态 (跳过通知)
  if (nextMode === prev.toolPermissionContext.mode) {
    return prev
  }

  return {
    ...prev,
    toolPermissionContext: {
      ...prev.toolPermissionContext,
      mode: nextMode
    }
  }
})
```

**优势**: Store 的 `Object.is()` 检查会跳过通知,避免不必要的重渲染。

### 4.2 副作用处理 (onChangeAppState)

`onChangeAppState` 是一个中央副作用处理器,在每次状态变化后执行。

**文件**: `src/state/onChangeAppState.ts`

#### 4.2.1 权限模式同步

```typescript
export function onChangeAppState({
  newState,
  oldState,
}: {
  newState: AppState
  oldState: AppState
}) {
  // 检测权限模式变化
  const prevMode = oldState.toolPermissionContext.mode
  const newMode = newState.toolPermissionContext.mode

  if (prevMode !== newMode) {
    // 转换为外部模式 (隐藏内部模式如 'bubble')
    const prevExternal = toExternalPermissionMode(prevMode)
    const newExternal = toExternalPermissionMode(newMode)

    if (prevExternal !== newExternal) {
      // 通知 CCR (Cloud Code Runner)
      notifySessionMetadataChanged({
        permission_mode: newExternal,
      })
    }

    // 通知 SDK 监听器
    notifyPermissionModeChanged(newMode)
  }
}
```

**触发场景**:
- 用户按 `Shift+Tab` 循环模式
- 执行 `/plan` 命令进入计划模式
- ExitPlanModePermissionRequest 对话框选择模式
- Bridge 远程控制设置模式

#### 4.2.2 配置持久化

```typescript
export function onChangeAppState({ newState, oldState }) {
  // mainLoopModel 变化 → 保存到 settings.json
  if (
    newState.mainLoopModel !== oldState.mainLoopModel &&
    newState.mainLoopModel !== null
  ) {
    updateSettingsForSource('userSettings', {
      model: newState.mainLoopModel
    })
  }

  // verbose 变化 → 保存到 globalConfig.json
  if (newState.verbose !== oldState.verbose) {
    saveGlobalConfig(current => ({
      ...current,
      verbose: newState.verbose,
    }))
  }
}
```

---

## 第 5 节:设计权衡

### 5.1 为什么不用 Zustand?

虽然本章标题提到了"Zustand-like Store",但 Claude Code CLI 实际上 **没有使用 Zustand 库**,而是实现了一个轻量级的自定义 Store。

#### 对比分析

| 维度 | 自定义 Store | Zustand |
|------|-------------|---------|
| **代码量** | 35 行 | ~1,000 行 (压缩后 ~2KB) |
| **依赖** | 0 | 1 个 NPM 包 |
| **功能** | getState, setState, subscribe | 中间件、DevTools、持久化、Immer 集成 |
| **学习曲线** | 几乎为 0 | 需要学习 API |
| **控制度** | 完全控制 | 受限于库设计 |
| **类型安全** | 完全类型化 | 需要额外配置 |

#### 为什么选择自定义实现?

**原因 1: 体积敏感**
- Claude Code CLI 是命令行工具,启动时间很重要
- 每个依赖都会增加打包体积和启动延迟
- 35 行代码提供了所需的全部功能

**原因 2: 简单需求**
- 不需要 Zustand 的高级功能 (中间件、DevTools、时间旅行)
- `useSyncExternalStore` (React 18) 已提供订阅机制
- 副作用通过 `onChangeAppState` 集中处理,不需要中间件

**原因 3: 完全控制**
- 可自定义 `Object.is()` 优化策略
- 可插入自定义日志、性能监控
- 可适配特殊需求 (如 DeepImmutable 类型)

### 5.2 Immutable 更新的优缺点

#### 优点

**1. 性能优化**
- React 通过 `Object.is()` 快速判断变化 (O(1))
- 避免深度比较整个状态树 (O(n))
- 细粒度订阅只在相关字段变化时触发重渲染

**2. 可预测性**
- 状态变化是��向的 (oldState → newState)
- 不会有隐式修改导致的 Bug
- 便于推理和调试

#### 缺点

**1. 内存开销**
- 每次更新都创建新对象 (虽然未变化的子对象保持引用)
- 大型嵌套结构 (如 `mcp.clients`) 需要复制整个路径

**2. 代码冗长**
- 深层更新需要手动展开每一层

---

## 第 6 节:与其他系统的关联

### 6.1 被 Task Framework 依赖

**关系**: Task Framework 通过 AppState 管理所有后台任务的状态。

#### 任务生命周期

```typescript
// 任务创建
setState(prev => ({
  ...prev,
  tasks: {
    ...prev.tasks,
    [taskId]: {
      type: 'local_shell',
      id: taskId,
      status: 'running',
      command: 'npm install',
      cwd: '/path/to/project',
      spawnedAt: Date.now(),
    }
  }
}))
```

### 6.2 被 Permission System 依赖

**关系**: 权限系统的所有状态 (模式、规则、历史决策) 存储在 `toolPermissionContext` 中。

### 6.3 被 Bridge System 依赖

**关系**: Bridge 系统通过 AppState 管理连接状态和会话信息。

---

## 第 7 节:总结

### 7.1 核心要点回顾

**1. AppState 是全局状态中心**
- 管理 70+ 字段,涵盖对话、任务、权限、UI、集成等所有领域
- 所有组件通过 `useAppState(selector)` 细粒度订阅
- 所有系统通过 `setState(updater)` 更新状态

**2. 轻量级 Store 实现**
- 只有 35 行代码,基于 React 的 `useSyncExternalStore`
- 提供 `getState`、`setState`、`subscribe` 三个核心 API
- 通过 `Object.is()` 优化,跳过不必要的通知

**3. Immutable 更新模式**
- 所有更新返回新对象,不修改原状态
- 支持浅层、深层、数组、Map/Set 的更新模式
- 通过 `onChangeAppState` 集中处理副作用

**4. 与其他系统协作**
- **Task Framework**: 管理所有后台任务状态
- **Permission System**: 存储权限模式、规则、历史决策
- **Bridge System**: 管理远程连接状态和会话信息
- **QueryEngine**: 提供模型配置、推测执行、提示建议

**5. 设计权衡**
- **不用 Zustand/Redux/MobX**: 自定义 Store 更轻量、更灵活
- **不用 Immer**: 手动更新足够,避免额外依赖
- **Immutable 优先**: 性能和可预测性优于代码简洁性

### 7.2 推荐阅读

**相关章节**:
- **04-tool-system.md**: Tool 系统如何读取权限上下文
- **08-task-framework.md**: Task Framework 如何管理任务状态
- **12-permission-system.md**: 权限系统如何使用 AppState

**外部资源**:
- [React useSyncExternalStore 文档](https://react.dev/reference/react/useSyncExternalStore)
- [Immutable Update Patterns](https://redux.js.org/usage/structuring-reducers/immutable-update-patterns)

---

**下一章预告**: 在 [08-task-framework.md](./08-task-framework.md) 中,我们将深入解析任务框架如何管理后台任务的生命周期,以及如何与 AppState 协作实现任务状态的实时更新。
