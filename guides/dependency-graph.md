# 模块依赖关系图

可视化章节之间的依赖关系，帮助你理解学习顺序和模块间的交互。

## 📊 完整依赖关系图

```
                    ┌──────────────────┐
                    │   00-overview    │ ✅
                    │   (系统总览)      │
                    └────────┬─────────┘
                             │
                ┌────────────┴────────────┐
                │                         │
        ┌───────▼───────┐         ┌──────▼──────┐
        │ 01-runtime    │ ⏳      │ 02-terminal │ ⏳
        │ -foundation   │         │     -ui     │
        │ (运行时基础)   │         │ (终端 UI)   │
        └───────┬───────┘         └──────┬──────┘
                │                         │
                │                  ┌──────▼──────┐
                │                  │  17-vim     │ ⏳
                │                  │   -mode     │
                │                  │ (Vim 模式)  │
                │                  └─────────────┘
        ┌───────▼───────┐
        │  03-type      │ ⏳
        │  -system      │
        │ (类型系统)     │
        └───────┬───────┘
                │
        ┌───────▼───────────────┐
        │   04-tool-system      │ ✅
        │    (工具系统)          │
        └───┬───────────┬───────┘
            │           │
    ┌───────▼──┐    ┌──▼────────────┐
    │   05     │ ⏳ │   12          │ ⏳
    │ command  │    │ permission    │
    │ -system  │    │  -system      │
    └──────────┘    └───┬───────────┘
                        │
                ┌───────▼────────┐
                │   13-mcp       │ ⏳
                │ -integration   │
                └───────┬────────┘
                        │
                ┌───────▼────────┐
                │  14-bridge     │ ⏳
                │   -system      │
                └────────────────┘

        ┌──────────────────────┐
        │  06-query-engine     │ ✅
        │   (查询引擎)          │
        └──────────┬───────────┘
                   │
        ┌──────────▼───────────┐
        │ 07-state-management  │ ✅
        │   (状态管理)          │
        └──────┬───────────────┘
               │
        ┌──────▼──────────┐
        │ 09-session      │ ⏳
        │  -storage       │
        │ (会话存储)       │
        └─────────────────┘

        ┌──────────────────┐
        │ 08-task          │ ✅
        │ -framework       │
        │ (任务框架)        │
        └────┬─────────────┘
             │
    ┌────────┼────────┐
    │        │        │
┌───▼───┐ ┌─▼──┐ ┌───▼────────────────┐
│ 10    │ │ 11 │ │     06-query       │
│ cron  │ │agent│ │     -engine        │
│scheduler│ │coord│ │                  │
│  ⏳   │ │ ⏳ │ └────────────────────┘
└───────┘ └─┬──┘
            │
    ┌───────▼────────┐
    │ 20-remote      │ ⏳
    │ -execution     │
    │ (远程执行)      │
    └────────────────┘

    ┌──────────────────┐
    │ 15-plugin        │ ⏳
    │  -system         │
    │ (插件系统)        │
    └────┬─────────────┘
         │
    ┌────▼─────────┐
    │ 16-skill     │ ⏳
    │  -system     │
    │ (Skill系统)  │
    └──────────────┘

    横切关注点:
    ┌────────────────┐
    │ 18-graceful    │ ⏳
    │  -shutdown     │
    └────────────────┘

    ┌────────────────┐
    │ 19-feature     │ ⏳
    │   -flags       │
    └────────────────┘
```

**图例**:
- ✅ 已完成章节
- ⏳ 计划中章节
- → 表示依赖关系（箭头指向被依赖的模块）

---

## 🎯 核心依赖路径

### 路径 1: 工具执行链

最基础的工具调用流程。

```
00-overview (✅)
    ↓
01-runtime-foundation (⏳)
    ↓
03-type-system (⏳)
    ↓
04-tool-system (✅)
    ↓
执行工具
```

**关键节点**:
- **00-overview**: 理解整体架构
- **01-runtime-foundation**: 提供运行环境
- **03-type-system**: 确保类型安全
- **04-tool-system**: 核心工具机制

**学习建议**: 这是最核心的路径，建议优先掌握。

---

### 路径 2: 查询与状态链

Claude API 调用和状态管理。

```
00-overview (✅)
    ↓
04-tool-system (✅)
    ↓
06-query-engine (✅)
    ↓
07-state-management (✅)
    ↓
09-session-storage (⏳)
```

**关键节点**:
- **06-query-engine**: API 集成和流式响应
- **07-state-management**: 上下文和状态管理
- **09-session-storage**: 会话持久化

**学习建议**: 理解 Claude 如何被调用以及状态如何管理。

---

### 路径 3: 任务编排链

复杂工作流的管理和调度。

```
00-overview (✅)
    ↓
07-state-management (✅)
    ↓
08-task-framework (✅)
    ↓
┌────────┼────────┐
│        │        │
10-cron  11-agent 20-remote
(⏳)     (⏳)     (⏳)
```

**关键节点**:
- **08-task-framework**: 任务定义和依赖管理
- **10-cron-scheduler**: 定时调度
- **11-agent-coordination**: 多 Agent 协作
- **20-remote-execution**: 分布式执行

**学习建议**: 从简单任务开始，逐步理解复杂编排。

---

### 路径 4: 扩展机制链

系统的可扩展性设计。

```
00-overview (✅)
    ↓
04-tool-system (✅)
    ↓
13-mcp-integration (⏳)
    ↓
14-bridge-system (⏳)

04-tool-system (✅)
    ↓
15-plugin-system (⏳)
    ↓
16-skill-system (⏳)
```

**关键节点**:
- **13-mcp-integration**: MCP 协议支持
- **14-bridge-system**: 外部服务桥接
- **15-plugin-system**: 插件架构
- **16-skill-system**: 高级功能模块

**学习建议**: 理解如何扩展系统能力。

---

### 路径 5: UI 交互链

终端界面和用户交互。

```
00-overview (✅)
    ↓
01-runtime-foundation (⏳)
    ↓
02-terminal-ui (⏳)
    ↓
17-vim-mode (⏳)

04-tool-system (✅)
    ↓
05-command-system (⏳)
```

**关键节点**:
- **02-terminal-ui**: Ink 和 React 集成
- **17-vim-mode**: 键盘导航
- **05-command-system**: 命令处理

**学习建议**: 关注用户体验和交互设计。

---

## 📚 模块分组

### 独立模块 (可单独学习)

这些模块相对独立，可以根据需要学习。

- ⏳ **17-vim-mode** (Vim 模式)
  - 依赖: 02-terminal-ui
  - 适合: 需要配置快捷键的用户

- ⏳ **18-graceful-shutdown** (优雅关闭)
  - 依赖: 01-runtime-foundation
  - 适合: 关注稳定性的开发者

- ⏳ **19-feature-flags** (特性开关)
  - 依赖: 07-state-management
  - 适合: 需要动态配置的场景

---

### 核心模块 (必须学习)

这些模块是系统的基础，强烈建议学习。

- ✅ **00-overview** (系统总览)
  - 无依赖
  - 建立整体认知

- ✅ **04-tool-system** (工具系统)
  - 依赖: 01-runtime-foundation, 03-type-system
  - 核心交互机制

- ✅ **06-query-engine** (查询引擎)
  - 依赖: 04-tool-system
  - Claude API 集成

- ✅ **07-state-management** (状态管理)
  - 依赖: 01-runtime-foundation
  - 系统状态管理

- ✅ **08-task-framework** (任务框架)
  - 依赖: 07-state-management
  - 工作流编排

---

### 高级模块 (深入学习)

这些模块提供高级功能，适合有一定基础后学习。

- ⏳ **11-agent-coordination** (Agent 协调)
  - 依赖: 08-task-framework, 06-query-engine
  - 多 Agent 系统

- ⏳ **13-mcp-integration** (MCP 集成)
  - 依赖: 04-tool-system
  - 工具生态扩展

- ⏳ **15-plugin-system** (插件系统)
  - 依赖: 04-tool-system
  - 系统扩展能力

- ⏳ **20-remote-execution** (远程执行)
  - 依赖: 11-agent-coordination
  - 分布式能力

---

## 🔍 依赖分析

### 被依赖最多的模块 (Foundation Modules)

这些模块是其他模块的基础，建议优先学习。

1. ✅ **00-overview** (系统总览)
   - 被依赖: 所有其他模块
   - 重要性: ⭐⭐⭐⭐⭐

2. ✅ **04-tool-system** (工具系统)
   - 被依赖: 05, 12, 13, 15
   - 重要性: ⭐⭐⭐⭐⭐

3. ✅ **07-state-management** (状态管理)
   - 被依赖: 08, 09, 19
   - 重要性: ⭐⭐⭐⭐

4. ⏳ **01-runtime-foundation** (运行时基础)
   - 被依赖: 03, 02, 18
   - 重要性: ⭐⭐⭐⭐

5. ✅ **08-task-framework** (任务框架)
   - 被依赖: 10, 11, 20
   - 重要性: ⭐⭐⭐⭐

---

### 依赖最多的模块 (Leaf Modules)

这些模块依赖较多，建议在掌握基础后学习。

1. ⏳ **20-remote-execution** (远程执行)
   - 依赖: 11-agent-coordination
   - 复杂度: ⭐⭐⭐⭐⭐

2. ⏳ **11-agent-coordination** (Agent 协调)
   - 依赖: 08-task-framework, 06-query-engine
   - 复杂度: ⭐⭐⭐⭐⭐

3. ⏳ **14-bridge-system** (桥接系统)
   - 依赖: 13-mcp-integration
   - 复杂度: ⭐⭐⭐⭐

4. ⏳ **16-skill-system** (Skill 系统)
   - 依赖: 15-plugin-system
   - 复杂度: ⭐⭐⭐

---

## 📈 学习路线建议

### 策略 1: 自底向上 (Bottom-Up)

从最基础的模块开始，逐步构建知识体系。

```
第 1 阶段: 基础层
✅ 00-overview
⏳ 01-runtime-foundation
⏳ 03-type-system

第 2 阶段: 核心层
✅ 04-tool-system
✅ 06-query-engine
✅ 07-state-management

第 3 阶段: 应用层
✅ 08-task-framework
⏳ 15-plugin-system

第 4 阶段: 高级层
⏳ 11-agent-coordination
⏳ 20-remote-execution
```

**优点**: 扎实的基础，理解深入
**缺点**: 初期可能感觉抽象

---

### 策略 2: 自顶向下 (Top-Down)

从应用场景开始，按需学习依赖。

```
场景 1: 使用工具
✅ 00-overview → ✅ 04-tool-system

场景 2: 构建工作流
✅ 08-task-framework → ✅ 07-state-management

场景 3: 集成服务
⏳ 13-mcp-integration → ✅ 04-tool-system

场景 4: 多 Agent 协作
⏳ 11-agent-coordination → ✅ 08-task-framework
```

**优点**: 快速上手，目标明确
**缺点**: 可能遗漏细节

---

### 策略 3: 关键路径 (Critical Path)

专注于最重要的依赖链。

```
核心路径:
✅ 00-overview
    ↓
⏳ 01-runtime-foundation
    ↓
✅ 04-tool-system
    ↓
✅ 06-query-engine
    ↓
✅ 07-state-management
    ↓
✅ 08-task-framework
```

**优点**: 高效掌握核心能力
**缺点**: 部分模块需后续补充

---

## 🎯 特定目标的依赖路径

### 目标 1: 创建自定义工具

```
✅ 00-overview
    ↓
⏳ 03-type-system
    ↓
✅ 04-tool-system
    ↓
⏳ 12-permission-system
```

---

### 目标 2: 构建任务编排系统

```
✅ 00-overview
    ↓
✅ 07-state-management
    ↓
✅ 08-task-framework
    ↓
⏳ 10-cron-scheduler
```

---

### 目标 3: 集成外部服务

```
✅ 00-overview
    ↓
✅ 04-tool-system
    ↓
⏳ 13-mcp-integration
    ↓
⏳ 14-bridge-system
```

---

### 目标 4: 开发插件

```
✅ 00-overview
    ↓
✅ 04-tool-system
    ↓
⏳ 15-plugin-system
    ↓
⏳ 16-skill-system
```

---

## 💡 依赖管理技巧

### 1. 前置学习检查

在学习一个章节前，确保已掌握其依赖:

```bash
# 示例: 学习 08-task-framework 前
已完成 ✅ 00-overview
已完成 ✅ 07-state-management
→ 可以开始学习 08-task-framework
```

---

### 2. 循环依赖处理

少数模块可能存在循环依赖，建议:

1. 先学习其中一个模块的基础部分
2. 再学习另一个模块
3. 回头深入第一个模块

**示例**:
- 06-query-engine 和 11-agent-coordination
  - 先学 06 的基础 API 调用
  - 再学 11 的协调机制
  - 回头学 06 的多轮对话

---

### 3. 渐进式学习

对于复杂依赖链:

1. **第一遍**: 快速浏览整条链，建立认知
2. **第二遍**: 深入每个模块的核心功能
3. **第三遍**: 理解模块间的交互细节

---

## 🔗 相关导航

- [按架构层次导航](./by-layer.md)
- [按功能模块导航](./by-feature.md)
- [按难度级别导航](./by-difficulty.md)
