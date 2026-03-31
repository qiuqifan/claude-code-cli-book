# 术语表

本文档定义 Claude Code Deep Dive 项目中使用的关键术语。

---

## A

**Agent（代理）**
独立运行的 AI 实例，可以派生为子进程执行任务。Claude Code 支持多 Agent 协作。

**AppState（应用状态）**
全局状态管理对象，基于 Zustand 实现，存储任务、配置、UI 状态等。

## C

**Command（命令）**
用户在 REPL 中通过 `/` 前缀调用的功能，如 `/commit`、`/review`。

**Cron Scheduler（定时调度器）**
定时任务调度系统，支持标准 5 字段 cron 表达式。

## H

**Harness（任务执行框架）**
Claude Code 的核心框架层，负责任务生命周期管理、状态持久化、定时调度等。

## I

**Ink**
基于 React 的终端 UI 框架，将 React 组件渲染为终端 ANSI 序列。

## J

**JSONL（JSON Lines）**
每行一条 JSON 记录的文件格式，用于增量追加会话历史。

## M

**MCP (Model Context Protocol)**
Anthropic 推出的协议，用于连接外部工具和服务。

## Q

**Query Engine（查询引擎）**
核心 LLM 交互循环，处理用户输入、调用 API、执行 Tool、返回结果。

## S

**Session（会话）**
一次 Claude Code 运行实例，包含对话历史、工作目录、任务列表等。

## T

**Task（任务）**
长时间运行的操作（如后台 Bash 命令、子 Agent），具有独立的生命周期。

**Tool（工具）**
Claude 可以调用的功能单元，如 Read、Write、Bash、Grep 等。每个 Tool 有输入 schema 和执行逻辑。

## Z

**Zustand**
轻量级 React 状态管理库，Claude Code 用它管理 AppState。

---

**持续更新中...**
