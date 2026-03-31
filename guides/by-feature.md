# 按功能模块导航

按照功能领域组织章节，帮助你快速定位和深入学习特定功能模块。

## 🎯 功能模块概览

### 核心能力 (Core Capabilities)
系统的基础能力和核心功能

### 工具生态 (Tool Ecosystem)
工具的定义、集成和扩展

### 任务编排 (Task Orchestration)
复杂工作流的调度和协调

### 用户交互 (User Interaction)
终端界面和交互体验

### 扩展机制 (Extension Mechanisms)
插件、Skill 和自定义扩展

### 基础设施 (Infrastructure)
底层支撑和系统服务

---

## 📦 详细模块

### 1️⃣ 核心能力 (Core Capabilities)

这些模块构成了系统的核心引擎。

#### ✅ [00. 系统总览](../chapters/00-overview.md)
**状态**: 已完成 | **难度**: ⭐ 入门 | **时间**: 30 分钟

理解系统整体架构和设计理念。

**适用场景**:
- 快速了解系统能力
- 评估是否满足需求
- 理解设计理念

---

#### ✅ [06. 查询引擎](../chapters/06-query-engine.md)
**状态**: 已完成 | **难度**: ⭐⭐⭐ 中级 | **时间**: 70 分钟

与 Claude API 的集成和通信。

**适用场景**:
- 调试 API 调用问题
- 优化响应延迟
- 实现自定义提示词策略

**相关模块**: 07-state-management, 11-agent-coordination

---

#### ✅ [07. 状态管理](../chapters/07-state-management.md)
**状态**: 已完成 | **难度**: ⭐⭐⭐ 中级 | **时间**: 65 分钟

上下文管理、状态同步和持久化。

**适用场景**:
- 实现有状态的工具
- 会话恢复功能
- 调试状态不一致问题

**相关模块**: 09-session-storage, 08-task-framework

---

#### ⏳ [05. 命令系统](../chapters/05-command-system.md)
**状态**: 计划中 | **难度**: ⭐⭐ 初级 | **时间**: 50 分钟

内置命令和自定义命令扩展。

**适用场景**:
- 添加自定义命令
- 理解命令路由
- 扩展 REPL 能力

**相关模块**: 04-tool-system, 15-plugin-system

---

### 2️⃣ 工具生态 (Tool Ecosystem)

工具是系统与外部世界交互的核心。

#### ✅ [04. 工具系统](../chapters/04-tool-system.md)
**状态**: 已完成 | **难度**: ⭐⭐⭐ 中级 | **时间**: 60 分钟

工具定义、注册、执行和组合。

**适用场景**:
- 创建自定义工具
- 理解工具执行流程
- 调试工具调用问题

**相关模块**: 12-permission-system, 13-mcp-integration

---

#### ⏳ [12. 权限系统](../chapters/12-permission-system.md)
**状态**: 计划中 | **难度**: ⭐⭐⭐⭐ 高级 | **时间**: 45 分钟

安全策略、权限检查和授权。

**适用场景**:
- 实现安全工具
- 配置权限策略
- 审计工具调用

**相关模块**: 04-tool-system, 14-bridge-system

---

#### ⏳ [13. MCP 集成](../chapters/13-mcp-integration.md)
**状态**: 计划中 | **难度**: ⭐⭐⭐⭐ 高级 | **时间**: 55 分钟

Model Context Protocol 协议集成。

**适用场景**:
- 集成 MCP 服务
- 创建 MCP 服务器
- 扩展工具生态

**相关模块**: 04-tool-system, 14-bridge-system

---

#### ⏳ [14. 桥接系统](../chapters/14-bridge-system.md)
**状态**: 计划中 | **难度**: ⭐⭐⭐⭐ 高级 | **时间**: 40 分钟

Claude 与外部服务的通信桥接。

**适用场景**:
- 集成第三方服务
- 实现自定义协议
- 调试通信问题

**相关模块**: 13-mcp-integration, 04-tool-system

---

### 3️⃣ 任务编排 (Task Orchestration)

管理复杂的多步骤工作流程。

#### ✅ [08. 任务框架](../chapters/08-task-framework.md)
**状态**: 已完成 | **难度**: ⭐⭐⭐⭐ 高级 | **时间**: 60 分钟

任务调度、依赖管理和并行执行。

**适用场景**:
- 实现复杂工作流
- 管理任务依赖
- 优化并行执行

**相关模块**: 10-cron-scheduler, 11-agent-coordination

---

#### ⏳ [10. Cron 调度器](../chapters/10-cron-scheduler.md)
**状态**: 计划中 | **难度**: ⭐⭐⭐ 中级 | **时间**: 45 分钟

定时任务和周期性调度。

**适用场景**:
- 实现定时任务
- 后台任务调度
- 会话恢复后的任务继续

**相关模块**: 08-task-framework, 09-session-storage

---

#### ⏳ [11. Agent 协调](../chapters/11-agent-coordination.md)
**状态**: 计划中 | **难度**: ⭐⭐⭐⭐⭐ 专家 | **时间**: 70 分钟

多 Agent 协同工作和通信。

**适用场景**:
- 实现多 Agent 系统
- 任务分解和并行
- 复杂问题求解

**相关模块**: 08-task-framework, 06-query-engine, 20-remote-execution

---

### 4️⃣ 用户交互 (User Interaction)

终端界面和用户体验设计。

#### ⏳ [02. 终端 UI 系统](../chapters/02-terminal-ui.md)
**状态**: 计划中 | **难度**: ⭐⭐⭐ 中级 | **时间**: 40 分钟

基于 Ink 和 React 的终端 UI。

**适用场景**:
- 自定义 UI 组件
- 美化命令输出
- 实现交互式界面

**相关模块**: 17-vim-mode, 01-runtime-foundation

---

#### ⏳ [17. Vim 模式](../chapters/17-vim-mode.md)
**状态**: 计划中 | **难度**: ⭐⭐ 初级 | **时间**: 40 分钟

Vim 风格的键盘导航和快捷键。

**适用场景**:
- 配置快捷键
- 自定义键盘映射
- 提高操作效率

**相关模块**: 02-terminal-ui, 05-command-system

---

### 5️⃣ 扩展机制 (Extension Mechanisms)

系统的可扩展性设计。

#### ⏳ [15. 插件系统](../chapters/15-plugin-system.md)
**状态**: 计划中 | **难度**: ⭐⭐⭐⭐ 高级 | **时间**: 55 分钟

插件加载、生命周期和 API 设计。

**适用场景**:
- 开发插件
- 扩展系统能力
- 理解插件架构

**相关模块**: 04-tool-system, 16-skill-system

---

#### ⏳ [16. Skill 系统](../chapters/16-skill-system.md)
**状态**: 计划中 | **难度**: ⭐⭐⭐ 中级 | **时间**: 50 分钟

预定义的高级功能模块。

**适用场景**:
- 使用内置 Skill
- 创建自定义 Skill
- 组合 Skill 构建工作流

**相关模块**: 15-plugin-system, 08-task-framework

---

### 6️⃣ 基础设施 (Infrastructure)

底层支撑和运行环境。

#### ⏳ [01. 运行时基础](../chapters/01-runtime-foundation.md)
**状态**: 计划中 | **难度**: ⭐⭐⭐ 中级 | **时间**: 45 分钟

REPL 核心运行机制。

**适用场景**:
- 理解启动流程
- 调试运行时问题
- 优化性能

**相关模块**: 18-graceful-shutdown, 09-session-storage

---

#### ⏳ [03. 类型系统](../chapters/03-type-system.md)
**状态**: 计划中 | **难度**: ⭐⭐⭐ 中级 | **时间**: 50 分钟

TypeScript 类型定义和运行时验证。

**适用场景**:
- 理解类型设计
- 实现类型安全的工具
- 调试类型错误

**相关模块**: 04-tool-system, 07-state-management

---

#### ⏳ [09. 会话存储](../chapters/09-session-storage.md)
**状态**: 计划中 | **难度**: ⭐⭐ 初级 | **时间**: 35 分钟

会话持久化和恢复。

**适用场景**:
- 实现会话恢复
- 调试持久化问题
- 优化存储策略

**相关模块**: 07-state-management, 10-cron-scheduler

---

#### ⏳ [18. 优雅关闭](../chapters/18-graceful-shutdown.md)
**状态**: 计划中 | **难度**: ⭐⭐ 初级 | **时间**: 35 分钟

信号处理和资源清理。

**适用场景**:
- 确保数据不丢失
- 实现清理逻辑
- 调试关闭问题

**相关模块**: 01-runtime-foundation, 09-session-storage

---

#### ⏳ [19. 特性开关](../chapters/19-feature-flags.md)
**状态**: 计划中 | **难度**: ⭐⭐ 初级 | **时间**: 30 分钟

动态配置和特性切换。

**适用场景**:
- 灰度发布功能
- A/B 测试
- 降级策略

**相关模块**: 07-state-management, 15-plugin-system

---

### 7️⃣ 高级特性 (Advanced Features)

面向复杂场景的高级功能。

#### ⏳ [20. 远程执行](../chapters/20-remote-execution.md)
**状态**: 计划中 | **难度**: ⭐⭐⭐⭐⭐ 专家 | **时间**: 60 分钟

分布式执行和远程协作。

**适用场景**:
- 分布式任务执行
- 远程协作开发
- 云端集成

**相关模块**: 11-agent-coordination, 08-task-framework

---

## 🔍 快速查找

### 按使用场景查找

**我想实现自定义工具**
→ [04-tool-system](../chapters/04-tool-system.md) → [12-permission-system](../chapters/12-permission-system.md)

**我想构建复杂工作流**
→ [08-task-framework](../chapters/08-task-framework.md) → [10-cron-scheduler](../chapters/10-cron-scheduler.md)

**我想集成外部服务**
→ [13-mcp-integration](../chapters/13-mcp-integration.md) → [14-bridge-system](../chapters/14-bridge-system.md)

**我想开发插件**
→ [15-plugin-system](../chapters/15-plugin-system.md) → [16-skill-system](../chapters/16-skill-system.md)

**我想优化性能**
→ [07-state-management](../chapters/07-state-management.md) → [06-query-engine](../chapters/06-query-engine.md)

**我想自定义界面**
→ [02-terminal-ui](../chapters/02-terminal-ui.md) → [17-vim-mode](../chapters/17-vim-mode.md)

### 按技术栈查找

**TypeScript/类型系统**
→ [03-type-system](../chapters/03-type-system.md)

**React/UI 开发**
→ [02-terminal-ui](../chapters/02-terminal-ui.md)

**API 集成**
→ [06-query-engine](../chapters/06-query-engine.md)

**状态管理**
→ [07-state-management](../chapters/07-state-management.md)

**任务调度**
→ [08-task-framework](../chapters/08-task-framework.md)

**安全/权限**
→ [12-permission-system](../chapters/12-permission-system.md)

---

## 📝 学习路径推荐

### 路径 1: 工具开发者
**目标**: 创建和集成自定义工具

1. [00-overview](../chapters/00-overview.md) - 理解整体架构
2. [04-tool-system](../chapters/04-tool-system.md) - 学习工具系统
3. [03-type-system](../chapters/03-type-system.md) - 掌握类型定义
4. [12-permission-system](../chapters/12-permission-system.md) - 实现安全控制
5. [13-mcp-integration](../chapters/13-mcp-integration.md) - 集成外部服务

### 路径 2: 工作流编排者
**目标**: 构建复杂的任务编排系统

1. [00-overview](../chapters/00-overview.md) - 理解整体架构
2. [07-state-management](../chapters/07-state-management.md) - 掌握状态管理
3. [08-task-framework](../chapters/08-task-framework.md) - 学习任务框架
4. [10-cron-scheduler](../chapters/10-cron-scheduler.md) - 实现定时任务
5. [11-agent-coordination](../chapters/11-agent-coordination.md) - 多 Agent 协调

### 路径 3: UI 定制者
**目标**: 自定义终端界面和交互

1. [00-overview](../chapters/00-overview.md) - 理解整体架构
2. [02-terminal-ui](../chapters/02-terminal-ui.md) - 学习 UI 系统
3. [17-vim-mode](../chapters/17-vim-mode.md) - 配置快捷键
4. [05-command-system](../chapters/05-command-system.md) - 扩展命令

### 路径 4: 插件开发者
**目标**: 开发可复用的插件和 Skill

1. [00-overview](../chapters/00-overview.md) - 理解整体架构
2. [04-tool-system](../chapters/04-tool-system.md) - 学习工具系统
3. [15-plugin-system](../chapters/15-plugin-system.md) - 掌握插件架构
4. [16-skill-system](../chapters/16-skill-system.md) - 创建 Skill
5. [07-state-management](../chapters/07-state-management.md) - 管理插件状态

---

## 🔗 相关导航

- [按架构层次导航](./by-layer.md)
- [按难度级别导航](./by-difficulty.md)
- [依赖关系图](./dependency-graph.md)
