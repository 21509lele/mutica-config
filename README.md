# Workerspace

本项目用于本地运行一组基于 Codex / Multica 的 worker 容器，分别承担需求分析、编码实现、审计验证和 Issue 编排职责。

当前运行时特征：

- `worker-coding` 预装 `oh-my-codex`，默认启用 OMX 能力
- 所有 worker 在镜像构建时下载固定版本的 `superpowers` 插件，并在启动时自动同步到当前 `.codex` 目录
- 已移除项目内的 `gstack` 运行时依赖
- `worker-codex` 镜像构建时默认安装最新版 `codex-cli`

## 目录结构

```text
.
├── docker-compose.yml
├── worker-base/
│   ├── Dockerfile
│   └── entrypoint.sh
├── worker-codex/
│   └── Dockerfile
├── codex-configs/
│   ├── requirement/
│   ├── coding/
│   ├── audit/
│   └── issue-management/
├── workspaces/
│   ├── requirement/
│   ├── coding/
│   ├── audit/
│   └── issue-management/
└── templates/
    └── issue-roles/
```

## Worker 说明

| 服务 | 角色 | 说明 |
| --- | --- | --- |
| `worker-requirement` | Requirement Analyst | 负责需求澄清、拆分子 Issue、定义验收标准 |
| `worker-coding` | Coding Agent | 负责代码实现、配置改动、验证和提交 |
| `worker-audit` | Audit / Reviewer | 负责行为验证、回归检查、审计和评审 |
| `worker-issue-management` | Issue Manager | 负责主 Issue 编排、派发、回收和状态推进 |
| `worker-base-build` | 基础镜像构建 | 提供通用 Ubuntu + Node.js + Multica CLI 运行时 |

## 运行方式

镜像分两层：

1. `worker-base/Dockerfile`
   提供基础运行环境：
   - Ubuntu 24.04
   - Node.js
   - Python 3
   - Git / tmux / curl 等基础工具
   - Multica CLI

2. `worker-codex/Dockerfile`
   在基础镜像上额外安装：
   - `@openai/codex`
   - `oh-my-codex`
   - 固定版本的 `superpowers` 插件资产

`docker-compose.yml` 负责把不同角色的配置目录、工作区目录和 SSH 凭据挂进各个容器。`superpowers` 插件则在镜像构建时从上游固定 release 下载，由入口脚本在启动时写入 worker 当前使用的 `.codex` 目录。

## 前置条件

启动前需要确保宿主机具备：

- Docker Desktop
- 可用的 Docker Compose
- 宿主机存在 `C:\Users\MR\.ssh`
- `.env` 中已经配置：
  - `MULTICA_SERVER_URL`
  - `MULTICA_APP_URL`
  - `OPENAI_API_KEY`
  - `GIT_USER_NAME`
  - `GIT_USER_EMAIL`
  - `GIT_SSH_KEY_FILE`
  - 各个 worker 的 `MULTICA_TOKEN`

## 首次构建

在项目根目录执行：

```powershell
docker compose build worker-base-build worker-requirement worker-coding worker-audit worker-issue-management
docker compose up -d worker-requirement worker-coding worker-audit worker-issue-management
```

如果希望强制拉起最新版 `codex-cli` 并忽略缓存：

```powershell
docker compose build --no-cache worker-base-build worker-requirement worker-coding worker-audit worker-issue-management
docker compose up -d worker-requirement worker-coding worker-audit worker-issue-management
```

## 常用操作

查看容器状态：

```powershell
docker compose ps
```

查看 `codex-cli` 版本：

```powershell
docker compose exec worker-coding codex --version
```

确认 `superpowers` 已写入容器当前 `.codex` 目录：

```powershell
docker compose exec worker-coding sh -lc "ls -1 /root/.codex/plugins/cache/openai-curated/superpowers/004da724/skills"
```

只重建一类 worker：

```powershell
docker compose build worker-coding
docker compose up -d worker-coding
```

停止全部 worker：

```powershell
docker compose down
```

## 配置约定

### `codex-configs/`

每个 worker 都有自己的 `.codex` 目录挂载点：

- `codex-configs/requirement`
- `codex-configs/coding`
- `codex-configs/audit`
- `codex-configs/issue-management`

这些目录用于保存：

- `auth.json`
- `config.toml`
- skills / prompts / agents
- 会话缓存和插件缓存

### `workspaces/`

每个 worker 有独立的工作目录：

- `workspaces/requirement`
- `workspaces/coding`
- `workspaces/audit`
- `workspaces/issue-management`

### SSH

宿主机的 `${USERPROFILE}/.ssh` 以只读方式挂载到容器内 `/host-ssh`，再由 [worker-base/entrypoint.sh](/C:/Users/MR/Desktop/tools/workerspace/worker-base/entrypoint.sh) 复制到 `/root/.ssh` 并生成 git 配置。

## 入口脚本行为

[worker-base/entrypoint.sh](/C:/Users/MR/Desktop/tools/workerspace/worker-base/entrypoint.sh) 会在容器启动时完成这些事情：

- 写入 Codex 配置和鉴权文件
- 初始化 SSH 和 git 用户信息
- 对 `worker-coding` 执行 `omx setup`
- 配置 Multica server/app 地址
- 使用 token 登录 Multica
- 启动对应角色的 `multica daemon`

## 当前设计取向

这个仓库当前是以 `OMX + superpowers + plain Codex` 为核心能力组合维护的。

- `coding` worker 偏向复杂实现和多 agent 执行
- `audit` worker 偏向验证和审计，但不再假设项目内置浏览器框架
- `issue-management` 和 `requirement` worker 默认按 plain Codex 路径工作

如果后续要补充新的浏览器自动化、审计工具或额外插件，建议继续通过 `docker-compose.yml` 的只读挂载方式接入，而不是重新在仓库里维护一套重型运行时。
