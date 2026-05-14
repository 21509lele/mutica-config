# Issue 角色提示词模板包

## 1. 模板包用途

本目录用于沉淀 Multica 协作中常见角色的提示词模板，帮助在创建或分配 Issue 时快速复制指令，统一以下内容：

- 角色定位与职责边界
- 角色可处理 / 不可处理的 Issue 类型
- Issue 管理权限
- 状态流转约束
- 评论交付格式

本模板包只包含文档模板，不包含运行时配置、脚本或自动化逻辑。

## 2. 目录结构

```text
templates/issue-roles/
├── README.md
├── requirement-analyst.md
├── coding-agent.md
├── reviewer-agent.md
└── human-owner.md
```

## 3. 使用方式

1. 根据 Issue 目标选择一个角色模板。
2. 将模板内容复制到 Agent 指令或任务说明中。
3. 按实际项目补充：Issue ID、仓库、分支规范、验收标准。
4. 保留模板中的“禁止行为”和“必须输出字段”，避免越界执行。

## 4. 角色选择规则

- 需求还不清晰、需要拆分任务：优先使用 `requirement-analyst.md`
- 已有明确子 Issue，需要实现代码或文档：使用 `coding-agent.md`
- 子 Issue 已提交代码，需要基于 diff 审核：使用 `reviewer-agent.md`
- 需要业务裁决、风险确认、最终合并与关闭：由 `human-owner.md` 处理

## 5. 权限边界总览

| 角色 | 可改代码 | 可创建子 Issue | 可改状态 | 可关闭 Issue | 可审核代码 |
| --- | --- | --- | --- | --- | --- |
| Requirement Analyst | 否 | 是（主 Issue 拆分） | 是（分析相关状态） | 否 | 否 |
| Coding Agent | 是（仅当前子 Issue） | 否（除非明确授权） | 是（coding/ready-for-review） | 否 | 否 |
| Reviewer Agent | 否（默认） | 否 | 是（review 相关状态） | 否（主 Issue） | 是 |
| Human Owner | 视情况 | 是 | 是 | 是 | 是（最终裁决） |

## 6. 维护约定

- 模板变更应保持角色边界一致，不得互相冲突。
- 如需新增角色，必须补齐与现有模板同级的字段结构。
- 若平台权限模型变化，应先由 Human Owner 确认后再更新模板。
