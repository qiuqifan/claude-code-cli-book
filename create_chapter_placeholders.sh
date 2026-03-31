#!/bin/bash

chapters=(
  "00-overview:架构总览:⭐ 入门"
  "01-runtime-foundation:Bun 运行时基础:⭐⭐ 进阶"
  "02-terminal-ui:Ink 终端 UI 系统:⭐⭐ 进阶"
  "03-type-system:TypeScript 类型系统设计:⭐⭐⭐ 高级"
  "04-tool-system:Tool 工具系统架构:⭐⭐ 进阶"
  "05-command-system:Command 命令系统:⭐⭐ 进阶"
  "06-query-engine:QueryEngine 查询引擎核心:⭐⭐⭐ 高级"
  "07-state-management:状态管理:⭐⭐ 进阶"
  "08-task-framework:任务生命周期管理:⭐⭐⭐ 高级"
  "09-session-storage:会话持久化:⭐⭐ 进阶"
  "10-cron-scheduler:定时任务调度:⭐⭐⭐ 高级"
  "11-agent-coordination:多 Agent 协调与通信:⭐⭐⭐ 高级"
  "12-permission-system:工具权限管理:⭐⭐ 进阶"
  "13-mcp-integration:MCP 协议集成:⭐⭐⭐ 高级"
  "14-bridge-system:IDE Bridge 架构:⭐⭐⭐ 高级"
  "15-plugin-system:插件架构:⭐⭐ 进阶"
  "16-skill-system:Skill 技能系统:⭐⭐ 进阶"
  "17-vim-mode:Vim 模式实现:⭐⭐ 进阶"
  "18-graceful-shutdown:优雅关闭机制:⭐⭐⭐ 高级"
  "19-feature-flags:特性开关:⭐ 入门"
  "20-remote-execution:远程会话与执行:⭐⭐⭐ 高级"
)

for chapter in "${chapters[@]}"; do
  IFS=':' read -r filename title difficulty <<< "$chapter"

  cat > "chapters/${filename}.md" << TEMPLATE
# ${filename##*-} - ${title}

> **摘要**
>
> 🚧 本章节正在编写中...
>
> **关键概念:** TBD
>
> **前置知识:** TBD
>
> **源码位置:** \`src/\`

---

## 状态

📝 **开发状态:** 计划中

**预计完成:** TBD

---

## 占位内容

本章将深入解析 ${title} 的设计与实现。

敬请期待！

---

**章节信息**
- **难度:** ${difficulty}
- **最后更新:** 2026-03-31
TEMPLATE

done

echo "✅ 已创建 ${#chapters[@]} 个章节占位文件"
