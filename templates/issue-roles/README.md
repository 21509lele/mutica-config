# Issue 角色提示词模板包

## 1. 模板包用途

本目录用于定义 Multica Issue 显式编排流程中的角色模板，使主 Issue 从进入系统到完成交付时，具备以下特性：

- 角色职责、权限边界、状态流转规则一致
- 角色与 worker runtime 能力对应
- Issue 评论中持续沉淀交接记录、验证结果、工作区路径与风险
- 文档可直接展示“当前作业流程”和“agent 之间的显式交接痕迹”

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
| `issue-management` | `issue-manager.md` | 主 Issue 接收、拆分、派发、回收、收尾 | 普通 Codex；不假设额外能力已加载 |
| `requirement` | `requirement-analyst.md` | 澄清范围、拆分子 Issue、定义验收标准 | plain Codex，必要时补充外部资料分析 |
| `coding` | `coding-agent.md` | 实现代码、配置、测试、文档改动 | OMX 自动加载，适合多 agent 编排与执行流 |
| `audit` | `audit-agent.md` | 浏览器验证、回归检查、安全/体验审计 | plain Codex，可按实际环境补充浏览器或审计能力 |
| `audit` 或独立评审流程 | `reviewer-agent.md` | 基于 diff 的技术评审 | 普通 Codex 审查，可按实际环境补充验证 |
| 人工 | `human-owner.md` | 升级裁决、风险确认、最终关闭 | 不受 runtime 约束 |

## 4. 主 Issue 显式编排流程

当前 Multica 平台不假设父子 Issue 存在自动编排机制：子 Issue 进入 `in_review` 或 `done` 不会自动触发父 Issue 再运行，也不会自动完成父 Issue 的回收、汇总或状态推进。主 / 父 Issue 的继续推进依赖新的触发评论、手动重触发，或平台中明确存在的其他显式调度机制。

若子 Issue 之间存在串行关系，Issue 文本必须把依赖写成可执行硬约束，而不能只写语义上的先后顺序。当前平台没有自动流水线依赖管理；若未写出硬依赖、恢复触发条件和输入绑定，平台默认会把子 Issue 视为可并行处理。

1. 用户提出主 Issue，由 `issue-management` worker 接收。
2. `Issue Manager` 读取主 Issue、历史评论、仓库信息，推进主 Issue 到 `in_progress`。
3. `Issue Manager` 将主 Issue 拆成可执行子 Issue，并为每个子 Issue 指定角色、依赖、恢复触发条件、输入绑定和验收标准。
4. `Requirement Analyst` 补充需求边界、非目标、依赖、DoD。
5. `Coding Agent` 在 `coding` worker 中执行实现。
6. `Audit Agent` 或 `Reviewer Agent` 在 `audit` worker 中做验证、浏览器检查、diff 评审。
7. 子 Issue 完成后，执行角色必须在当前 Issue 或父 Issue 中使用平台可触发的显式 `@` 通知下一持有者 / 父 Issue 持有者继续推进，不能只写“建议下一步由谁处理”。
8. `Issue Manager` 在显式触发后亲自回收所有子 Issue 结果，汇总到主 Issue；若无阻塞且父 Issue 持有者确认结论后再推进主 Issue 到 `done`，否则升级 `Human Owner`。

## 5. OMX 与验证能力的使用约定

- `OMX`：
  仅对 `coding` worker 视为默认可用能力。模板应鼓励在复杂实现、并行子任务、计划/执行分离时使用 OMX 的 `AGENTS.md`、skills、hooks、native subagents。
- 浏览器 / 审计增强能力：
  对 `audit` 或 `review` 路由，仅能把实际存在的浏览器、截图、审计工具视为可用能力，不能预设某个特定工具一定存在。
- `issue-management`：
  不假设 OMX 或额外验证能力已安装完成。该角色应通过派发给具备能力的 worker 来间接使用这些能力，而不是强行在自身 runtime 中执行。

## 6. 工作区与留痕文件

流程文档和 Issue 评论中，默认要求记录以下路径，便于展示 agent 显式交接痕迹：

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

## 7. 每一步必须沉淀到 Issue 评论的交接信息

- 当前角色
- 当前 worker runtime
- 关联 Issue ID / 父子 Issue 关系
- 串行依赖条件、恢复触发条件和输入绑定
- 使用的工作区路径
- 使用的关键能力
  `OMX` / plain Codex / 其他实际存在的验证能力
- 已完成动作
- 产出文件或修改文件
- 验证命令与结果
- 下一步交接对象
- 已执行的显式 `@` 通知对象与通知位置
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
