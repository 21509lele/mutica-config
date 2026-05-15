# Issue 角色提示词模板包

## 1. 模板包用途

本目录用于定义 Multica 自动化 Issue 流水线中的角色模板，使主 Issue 从进入系统到完成交付时，具备以下特性：

- 角色职责、权限边界、状态流转规则一致
- 角色与 worker runtime 能力对应
- Issue 评论中持续沉淀交接记录、验证结果、工作区路径与风险
- 文档可直接展示“当前作业流程”和“agent 之间的流转痕迹”

本目录只包含角色模板与流程文档，不直接包含平台脚本实现。

## 2. 目录结构

```text
templates/issue-roles/
├── README.md
├── issue-manager.md
├── requirement-analyst.md
├── coding-agent.md
├── audit-agent.md
├── reviewer-agent.md
└── human-owner.md
```

## 3. worker 与角色映射

| worker runtime | 主要角色模板 | 默认职责 | 特殊能力 |
| --- | --- | --- | --- |
| `issue-management` | `issue-manager.md` | 主 Issue 接收、拆分、派发、回收、收尾 | 普通 Codex；不假设 OMX/gstack 已加载 |
| `requirement` | `requirement-analyst.md` | 澄清范围、拆分子 Issue、定义验收标准 | 可选 gstack，适合需要浏览器/外部资料辅助的需求分析 |
| `coding` | `coding-agent.md` | 实现代码、配置、测试、文档改动 | OMX 自动加载，适合多 agent 编排与执行流 |
| `audit` | `audit-agent.md` | 浏览器验证、回归检查、安全/体验审计 | 可选 gstack，适合 `/browse`、`/qa`、`/review` 类技能 |
| `audit` 或独立评审流程 | `reviewer-agent.md` | 基于 diff 的技术评审 | 可结合 gstack 或普通 Codex 审查 |
| 人工 | `human-owner.md` | 升级裁决、风险确认、最终关闭 | 不受 runtime 约束 |

## 4. 主 Issue 自动流水线

1. 用户提出主 Issue，由 `issue-management` worker 接收。
2. `Issue Manager` 读取主 Issue、历史评论、仓库信息，推进主 Issue 到 `in_progress`。
3. `Issue Manager` 将主 Issue 拆成可执行子 Issue，并为每个子 Issue 指定角色、依赖和验收标准。
4. `Requirement Analyst` 补充需求边界、非目标、依赖、DoD。
5. `Coding Agent` 在 `coding` worker 中执行实现。
6. `Audit Agent` 或 `Reviewer Agent` 在 `audit` worker 中做验证、浏览器检查、diff 评审。
7. `Issue Manager` 回收所有子 Issue 结果，汇总到主 Issue；若无阻塞则推进主 Issue 到 `done`，否则升级 `Human Owner`。

## 5. OMX 与 gstack 的使用约定

- `OMX`：
  仅对 `coding` worker 视为默认可用能力。模板应鼓励在复杂实现、并行子任务、计划/执行分离时使用 OMX 的 `AGENTS.md`、skills、hooks、native subagents。
- `gstack`：
  仅对启用了 `GSTACK_INSTALL_ON_START=true` 且完成 setup 的 worker 视为可用。模板应将其视为“浏览器/QA/审计增强能力”，而非所有任务的默认依赖。
- `issue-management`：
  不假设 OMX 或 gstack 已安装完成。该角色应通过派发给具备能力的 worker 来间接使用这些能力，而不是强行在自身 runtime 中执行。

## 6. 工作区与留痕文件

流水线文档和 Issue 评论中，默认要求记录以下路径，便于展示 agent 流转痕迹：

- 工作区：
  `workspaces/requirement`
  `workspaces/coding`
  `workspaces/audit`
  `workspaces/issue-management`
- Codex 配置：
  `codex-configs/requirement`
  `codex-configs/coding`
  `codex-configs/audit`
  `codex-configs/issue-management`
- gstack 资源：
  `runtime-assets/gstack`

## 7. 每一步必须沉淀到 Issue 评论的交接信息

- 当前角色
- 当前 worker runtime
- 关联 Issue ID / 父子 Issue 关系
- 使用的工作区路径
- 使用的关键能力
  `OMX` / `gstack` / plain Codex
- 已完成动作
- 产出文件或修改文件
- 验证命令与结果
- 下一步交接对象
- 阻塞项与风险

## 8. 角色选择规则

- 主 Issue 接收与编排：`issue-manager.md`
- 需求分析、拆分、验收标准：`requirement-analyst.md`
- 明确子 Issue 的实现：`coding-agent.md`
- 浏览器验证、回归、体验、安全检查：`audit-agent.md`
- 已有提交后的技术评审：`reviewer-agent.md`
- 争议、授权、上线和关闭裁决：`human-owner.md`

## 9. 维护约定

- 模板必须反映当前 worker 能力，不得假设未安装的 runtime 能力。
- 模板变更时，优先保持状态流转、评论字段、交接记录格式一致。
- 若 worker 配置变化，应同步更新本目录中的 runtime 对应关系。
