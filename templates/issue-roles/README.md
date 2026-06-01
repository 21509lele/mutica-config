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
| `audit` | `audit-agent.md` | 仅承接真实浏览器验证、回归检查、安全/体验审计等行为证据任务 | plain Codex，可按实际环境补充浏览器或审计能力 |
| `audit` 或独立评审流程 | `reviewer-agent.md` | 基于 diff 的技术评审，并在通过后向 GitHub 提交/维护指向 `dev` 的 PR 与合并请求 | 普通 Codex 审查；默认走 PR 收口，不默认直接 merge |
| 人工 | `human-owner.md` | 升级裁决、风险确认、最终关闭 | 不受 runtime 约束 |

## 4. 主 Issue 多层级显式编排流程

当前模板明确假设：Multica 平台目前支持多层级父子 Issue 拆分，但**不具备可靠的自动调度 / 自动接管能力**。因此：

- `Issue Manager` / `Requirement Analyst` 必须把父子关系、依赖、恢复条件、输入绑定写成可执行规则。
- 下游 Issue 的启动、恢复、回收和上卷，当前仍以新的触发评论、手动重触发、或执行角色显式 `@` 通知为准。
- 若未来平台补齐自动调度能力，这些规则可直接作为自动化编排输入；但在当前模板中，不得把自动接管写成既有能力。

若子 Issue 之间存在串行关系，Issue 文本必须把依赖写成可执行硬约束，而不能只写语义上的先后顺序。多层级拆分时，缺失依赖、恢复条件或输入绑定的节点，必须保持 `todo` / `backlog` / `blocked`，不得被假定为可自动启动。

### 4.1 当前平台约束

当前平台下，以下动作都**不会自动发生**：

- 子 Issue 进入 `in_review` 或 `done` 后，父 Issue 自动再运行
- 一个子 Issue 完成后，其兄弟 / 后继 / 审计子 Issue 自动入队
- 多层级子 Issue 完成后，祖先 Issue 自动上卷汇总
- 角色切换后，平台自动为下一角色创建唯一队列任务

### 4.2 面向未来自动化的规则定义

虽然当前没有自动调度，但多层级编排仍必须提前写出未来可自动化的规则，至少包括：

- 启动条件：什么情况下某个下游 Issue 可以开始
- 恢复条件：什么事件发生后，一个被阻塞节点可以恢复
- 输入绑定：该节点必须消费哪个上游 Issue 的 branch、commit、评论结论、附件或交付物
- 接管对象：该节点应交给哪个角色 / agent / runtime
- 去重约束：未来若做自动调度，同一 Issue/agent 不应重复入队

这些规则在当前阶段的作用，是指导人工显式编排，而不是触发平台自动执行。

### 4.3 当前阶段的显式接管动作

在现状下，接管动作必须由角色显式触发：

1. 将目标 Issue 状态推进到 `todo` 或 `in_progress`
2. 在目标 Issue 或父 Issue 留下评论，至少写明：
   - 触发原因
   - 来源 Issue
   - 依赖满足情况
   - 输入绑定对象
   - 目标角色 / agent / runtime
3. 使用平台可触发的显式 `@` 通知下一持有者或父 Issue 持有者
4. 若是审计 / 回收类节点，必须把上游实现结果作为明确输入，而不是仅对父分支当前状态做静态判断

### 4.4 多层级回收与上卷

在当前平台下，子 Issue 完成后不会自动回收，因此必须由 `Issue Manager` 或当前执行角色显式完成：

- 当某 Issue 的直接子 Issue 全部满足完成条件后，显式恢复其父 Issue
- 父 Issue 恢复后显式汇总子 Issue 评论、交付物和风险
- 若仍有兄弟节点或依赖节点未满足，父 Issue 只做阶段性汇总，不得提前 `done`
- 若全部叶子节点完成且无未决阻塞，再由父 Issue 持有者或 Human Owner 做最终关闭裁决

### 4.5 标准执行顺序

1. 用户提出主 Issue，由 `issue-management` worker 接收。
2. `Issue Manager` 读取主 Issue、历史评论、仓库信息，推进主 Issue 到 `in_progress`。
3. `Issue Manager` 将主 Issue 拆成可执行的多层级子 Issue 树，并为每个节点写明角色、依赖、恢复触发条件、输入绑定和验收标准。
4. `Requirement Analyst` 补充需求边界、非目标、依赖、DoD，并在必要时继续向下拆分更细粒度子 Issue。
5. `Issue Manager` 或当前执行角色根据依赖和状态，显式触发可执行的 `Coding Agent` / `Audit Agent` / `Reviewer Agent` 节点。
6. `Coding Agent` 在 `coding` worker 中执行实现。
7. `Audit Agent` 或 `Reviewer Agent` 在 `audit` worker 中做验证、浏览器检查、diff 评审。
   其中明确的 `review` / `code review` / `diff review` / `审阅` / `评审` 应优先进入 `Reviewer Agent`；只有明确要求真实浏览器、QA、交互回归、安全审计、体验审计、冒烟检查等行为证据的任务才进入 `Audit Agent`。
   审核通过后的标准实现分支，统一由 `Reviewer Agent` 向 GitHub 提交或维护指向 `dev` 的 PR；PR 记录必须写明源分支名、commit 标题和对应 Issue 标号，保证后续 git 历史可读。
   若 `multica repo checkout` 产生的 worktree 无法直接写入底层 gitdir，这只影响“直接 merge 到权威分支”的路径，不影响 reviewer 在可写工作区中另建可写 clone、复用现有分支并发起 PR。
8. 每个执行节点完成后，由当前节点或 `Issue Manager` 使用显式 `@` 和评论留痕通知下一持有者或恢复父 Issue。
9. `Issue Manager` 在收到新的触发评论或手动重触发后继续回收所有子 Issue 结果，完成上卷汇总；若无阻塞且父 Issue 持有者确认结论后再推进主 Issue 到 `done`，否则升级 `Human Owner`。

## 5. OMX 与验证能力的使用约定

- `OMX`：
  仅对 `coding` worker 视为默认可用能力。模板应鼓励在复杂实现、并行子任务、计划/执行分离时使用 OMX 的 `AGENTS.md`、skills、hooks、native subagents。
- 浏览器 / 审计增强能力：
  对 `audit` 或 `review` 路由，仅能把实际存在的浏览器、截图、审计工具视为可用能力，不能预设某个特定工具一定存在。
- `issue-management`：
  不假设 OMX 或额外验证能力已安装完成。该角色应通过派发给具备能力的 worker 来间接使用这些能力，而不是强行在自身 runtime 中执行。

## 6. 项目规则读取约定

所有角色在进入项目工作前，都必须先读取并遵守项目内已有规则文件与文档规则，至少包括：

- 项目根目录或相关子目录中的 `AGENTS.md`
- 与当前环境等价的规则文件，如 `CLAUDE.md`、`GEMINI.md`、`README.md`、项目级开发说明
- 与当前任务直接相关的规范文档、运行文档、验收文档、架构文档

执行要求：

- 在评论或内部步骤中明确“已读取哪些规则文件”
- 若多个目录存在不同层级规则，应遵循更贴近当前工作目录的规则，并保留与上层规则的一致性
- 若规则冲突，必须先评论澄清或升级 Human Owner，不得自行猜测
- 未读取项目规则前，不得开始编辑代码、审阅代码、执行审计结论或做关键状态推进
## 7. 工作区与留痕文件

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

## 8. 每一步必须沉淀到 Issue 评论的交接信息

- 当前角色
- 当前 worker runtime
- 关联 Issue ID / 父子 Issue 关系
- 已读取的项目规则文件 / 文档规则
- 串行依赖条件、恢复触发条件和输入绑定
- 本次显式接管原因 / 恢复原因
- 若未来自动化，应满足的接管规则
- 使用的工作区路径
- 使用的关键能力
  `OMX` / plain Codex / 其他实际存在的验证能力
- 已完成动作
- 产出文件或修改文件
- 验证命令与结果
- 下一步交接对象
- 已执行的显式 `@` 通知对象与通知位置
- 阻塞项与风险

## 9. 角色选择规则

- 主 Issue 接收与编排：`issue-manager.md`
- 需求分析、拆分、验收标准：`requirement-analyst.md`
- 明确子 Issue 的实现：`coding-agent.md`
- 浏览器验证、回归、体验、安全检查，且任务文本中明确要求真实行为证据：`audit-agent.md`
- 已有提交后的技术评审，以及通过后向 GitHub 提交/维护指向 `dev` 的 PR（包含 `review` / `code review` / `diff review` / `审阅` / `评审`）：`reviewer-agent.md`
- 争议、授权、上线和关闭裁决：`human-owner.md`

## 10. 维护约定

- 模板必须反映当前 worker 能力，不得假设未安装的 runtime 能力。
- 模板必须与“多层级拆分 + 当前显式编排 + 面向未来自动化的规则预留 + 评论留痕”流程保持一致。
- 模板变更时，优先保持状态流转、评论字段、交接记录格式一致。
- 若 worker 配置变化，应同步更新本目录中的 runtime 对应关系。
