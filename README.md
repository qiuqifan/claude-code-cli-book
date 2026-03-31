# Claude Code Deep Dive

> **深入解析 Claude Code CLI 的架构设计**
>
> 系统化的技术文档项目，面向想要深入理解 Claude Code 内部实现的开发者

🎉 **项目状态：** v0.1 Early Preview 已发布 (2026-03-31)

---

## 📖 关于本项目

Claude Code 是 Anthropic 官方推出的 AI 辅助编程 CLI 工具。本项目通过深度源码分析，系统性地解析其架构设计、技术选型和实现细节。

**适合人群：**
- 🎯 想要理解 AI Agent CLI 工具架构的开发者
- 🎯 研究大型 TypeScript 项目设计的工程师
- 🎯 对终端 UI、状态管理、分布式任务等技术感兴趣的读者

---

## 🚀 快速开始

**已完成章节 (v0.1):**

| 章节 | 标题 | 说明 |
|------|------|------|
| [00-overview](chapters/00-overview.md) | 架构总览 | ⭐ 必读 - 系统架构全景图 |
| [04-tool-system](chapters/04-tool-system.md) | Tool 工具系统 | 工具抽象与调用机制 |
| [06-query-engine](chapters/06-query-engine.md) | 查询引擎核心 | AI 查询处理引擎 |
| [07-state-management](chapters/07-state-management.md) | 状态管理 | 全局状态与缓存机制 |
| [08-task-framework](chapters/08-task-framework.md) | 任务框架 | 异步任务调度系统 |

**多维导航索引:**
- [guides/](guides/) - 按主题、难度、技术栈浏览

更多章节陆续更新中...

---

## 🏗️ 项目结构

```
claude-code-cli-book/
├── chapters/           # 21个独立章节
├── guides/            # 多维导航索引
├── assets/            # 图表和资源
├── glossary.md        # 术语表
└── README.md          # 本文件
```

---

## 📜 版本历史

### v0.1 Early Preview (2026-03-31)
- ✅ 完成 5 个核心章节
- ✅ 建立多维导航索引系统
- ✅ 搭建基础项目结构

---

## 📄 License

MIT License - 本项目为教育目的创建

---

**最后更新:** 2026-03-31
