# 多Agent协同编排框架 — 使用手册

让 AI 突破上下文窗口限制，通过多智能体协同完成大型开发任务：主Agent 当**编排器**（不写代码，只调度决策），子Agent 分别负责**计划、开发、测试、审查**，各Agent 之间通过**文件路径**通信，主Agent 上下文始终保持轻量。

> 📌 本仓库包含 **三个平台版本**（Hermes / Claude Code / dsh），先看第二节选版，再按对应章节逐步操作。

---

## 目录

1. [框架是什么](#一框架是什么)
2. [三个版本怎么选](#二三个版本怎么选)
3. [🅱 Hermes 版使用指南](#三hermes-版使用指南默认推荐)
4. [🅰 Claude Code 版使用指南](#四claude-code-版使用指南)
5. [🅲 dsh 版使用指南](#五dsh-版使用指南deepseek-harness)
6. [核心机制速查（三版通用）](#六核心机制速查三版通用)
7. [故障排查速查表](#七故障排查速查表)
8. [仓库文件清单](#八仓库文件清单)

---

## 一、框架是什么

单次会话的上下文窗口有限，大项目动辄几十个文件，代码一多上下文就爆。本框架的思路：

```
用户需求
   │
   ▼
┌────────────┐  计划   ┌────────────┐  任务清单   ┌────────────────┐
│  编排器     │───────→│  planner    │──────────→│  progress.yaml  │
│ (主Agent)   │        │ (子Agent)   │            │  (唯一状态源)    │
│ 不写代码    │        └────────────┘            └────────────────┘
│ 只做调度    │
└─────┬──────┘
      │ 逐个任务
      ▼
┌─────────────────────────────────────────────┐
│ developer(写代码) → tester(实测验收) → PASSED │
│        ↑                    │                │
│        └──── 修复循环(最多N轮) ┘               │
│   + reviewer(可选，一票否决)                  │
└─────────────────────────────────────────────┘
```

**核心规则**：子Agent 只返回**文件路径**，绝不返回代码内容；编排器只读**状态文件**，绝不读代码——这样两边上下文都不会膨胀。

---

## 二、三个版本怎么选

| 对比项 | 🅱 Hermes 版 | 🅰 Claude Code 版 | 🅲 dsh 版 |
|--------|-------------|-------------------|----------|
| 适用平台 | Hermes Agent（Nous Research） | Claude Code（Anthropic CLI） | dsh（DeepSeek Harness） |
| 子Agent 机制 | `delegate_task`（一次性、隔离上下文、后台运行） | Task / subagent（一次性） | send_message / subagent_fork |
| 状态复用方式 | **文件恢复**（status.json）唯一途径 | **文件恢复**（status.json）唯一途径 | **原生复用优先**（续对话/继承上下文），文件恢复兜底 |
| 触发方式 | 直接说"开发完整的XXX"（skill 已内置） | CLAUDE.md 放项目根目录 | CLAUDE.md（若支持）或手动初始化 |
| 需要安装 | ❌ 无需（skill 自带模板） | ✅ 跑一次 install 脚本 | 按平台约定 |
| 模板位置 | 本仓库 `templates/multi-agent/hermes/` | `~/.claude/templates/multi-agent/` | 按平台约定 |
| 编排规范 | `hermes/orchestrator.md` | `claude-code/orchestrator.md` | `dsh/orchestrator.md` |

**新手建议**：默认用 🅱 Hermes 版，零安装，说句话就能跑。

---

## 三、🅱 Hermes 版使用指南（默认推荐）

### 3.1 前置条件

- 已安装 Hermes Agent（桌面版或 CLI 均可）
- 已安装 `multi-agent-orchestrator` skill（本仓库对应的 skill 包）

### 3.2 安装

**无需安装**。模板已内置在 skill 里，运行时自动从 `templates/prompts/` 和 `templates/presets/` 读取。

### 3.3 首次使用（5 步）

**第 1 步：提出需求**

直接对 Hermes 说（任务要大，多模块/多文件才值得编排）：

```
开发一个完整的命令行 TODO 管理器，支持增删改查、数据持久化
```

**第 2 步：选预设**

Hermes 会问你选哪个预设：

| 预设 | 流程 | 什么时候选 |
|------|------|-----------|
| `standard` | 计划→开发→测试 | 常规开发（默认） |
| `with-review` | 计划→开发→测试+审查 | 代码质量要求高/有安全顾虑 |
| `minimal` | 开发→测试 | 需求已经很明确 |
| `ai-competition` | 分析→实验→评估 | AI 比赛方案探索 |

**第 3 步：确认计划**

planner 子Agent 产出 `plan.md`（任务清单）后，Hermes 会暂停展示给你：
- 输入 `Y` 执行，或 `N` 让它修改
- 此时是**唯一一次整体调整任务拆分的机会**，仔细看任务粒度（每个任务应能在单个子Agent会话内完成）

**第 4 步：执行与验收**

Hermes 按依赖顺序逐个任务执行：开发 → 测试（→ 审查）→ 通过或进入修复循环。期间不需要你干预。

**第 5 步：收尾确认**

全部完成后暂停，展示汇总（通过/失败/跳过任务数、产出路径），确认后收尾。

### 3.4 日常开发流程（逐步说明）

```
对每个任务：
① 开发：delegate dev-{N} → 产出 ./output/task-{N}/v1/（代码+acceptance-criteria.md+interface.md+status.json）
         → 编排器 ls 验证路径存在
② 配对检查：delegate tester（→ reviewer）→ 产出 test-report.md（含 evidence 证据文件）
         → 编排器读报告 status 字段（PASSED/FAILED），并校验 evidence 文件非零字节
③ PASSED → 下一个任务
   FAILED → 修复循环：恢复前先校验 status.json 必填字段
         → 新建"dev-N 的延续"子Agent（传 status.json + 报告路径）修复到 v2/
         → 新建"test-N 的延续"子Agent 复验
         → 最多 max_retries 轮（默认3），超限 → escalation.md → 暂停问你
```

**escalation 时四个选项**：

| 选项 | 含义 |
|------|------|
| A) 跳过任务 | 放弃该任务，继续后续 |
| B) 重新设计 | 换思路重做（还是原开发者） |
| C) 接受限制 | 带着已知问题继续 |
| D) 换新开发者接手 | **新建一个不带旧上下文的开发者**，从需求重新设计——适合原开发者陷入思维定式、连修多轮无效的情况 |

### 3.5 配置自定义

项目配置在 `.hermes/orchestrator/`（兼容 `.claude/orchestrator/`）：

**roles.yaml —— 角色与模型**

```yaml
roles:
  developer:
    description: "编写代码实现功能"
    prompt: "prompts/developer.md"
    model: ""                # 留空 = 继承主模型；想用别的模型填名字
    paired_with: [tester]    # 开发完自动配 tester 验收
    max_retries: 3           # 修复上限
    veto_power: false

  reviewer:
    ...
    veto_power: true         # 一票否决：它报 FAILED 即使测试全过也算失败
```

**workflow.yaml —— 流程与并行**

```yaml
workflow:
  init:
    - role: planner          # 计划阶段角色
  per_task:
    - role: developer        # 每个任务依次执行的角色
    - role: tester
  finalize: []               # 收尾角色（如 documenter）
  task_strategy: serial      # serial=串行 | parallel=并行
  max_parallel: 3            # 并行上限（默认3，别超过 config 的 delegation.max_concurrent_children）
```

### 3.6 常见问题

| 问题 | 答案 |
|------|------|
| 任务很小也要编排吗？ | 不要。单文件/一步完成 → 直接做。编排是给大任务用的 |
| 会话断了/重启了怎么办？ | 告诉 Hermes 继续，它会读 progress.yaml 恢复进度 |
| 子Agent 返回代码内容了？ | 提醒它"只返回路径，不要返回内容" |
| 担心子Agent 谎报测试通过？ | 编排器会校验 evidence 文件非零字节+有运行痕迹，空文件直接打回 |

---

## 四、🅰 Claude Code 版使用指南

### 4.1 前置条件

- 已安装 Claude Code 并完成登录/配置

### 4.2 安装模板（一次性，1 分钟）

进入本仓库的 `templates/multi-agent/claude-code/` 目录：

**Windows：**
```bat
install.bat
```

**Mac / Linux：**
```bash
bash install.sh
```

脚本会把以下内容装到 `~/.claude/templates/multi-agent/`：
- `prompts/`：4 个角色模板 + **Claude Code 版编排规范**（orchestrator.md）
- `presets/`：4 个预设 yaml
- `CLAUDE.md`、`README.md`：入口和说明

> ⚠️ **必须安装**。编排规范写在 `~/.claude/templates/multi-agent/prompts/orchestrator.md`，不装的话 CLAUDE.md 引用的规范文件不存在。

### 4.3 项目初始化（每项目一次）

把 `~/.claude/templates/multi-agent/CLAUDE.md` **复制到你的项目根目录**：

```bash
cp ~/.claude/templates/multi-agent/CLAUDE.md 你的项目/
```

> CLAUDE.md 是 Claude Code 每次会话**自动读取**的项目规则文件，放对位置它才会进入编排模式。

### 4.4 触发开发

在项目里正常说：

```
帮我开发一个命令行计算器，支持加减乘除
```

Claude Code 读到 CLAUDE.md → 检测到项目未初始化 → 让你选预设 → 创建 `.claude/orchestrator/` → 开始编排。后续流程与 Hermes 版一致（计划→开发→测试→修复循环→收尾，同样有检查点和证据校验）。

### 4.5 配置自定义

同 Hermes 版（见 3.5），配置目录为 `.claude/orchestrator/`。模型名用 Claude Code 支持的：

```yaml
developer:
  model: sonnet              # 写代码用强模型
tester:
  model: haiku               # 测试用轻量模型，省钱
reviewer:
  model: opus                # 审查用最强推理能力
```

### 4.6 常见问题

| 问题 | 答案 |
|------|------|
| 没跑 install 脚本会怎样？ | CLAUDE.md 找不到 `~/.claude/templates/multi-agent/prompts/orchestrator.md`，编排会卡住。先安装 |
| CLAUDE.md 放错目录？ | 必须放**项目根目录**，子目录不生效 |
| 想给其他项目用？ | 每个项目复制一次 CLAUDE.md 即可（模板只需装一次） |

---

## 五、🅲 dsh 版使用指南（DeepSeek Harness）

### 5.1 前置条件

- 已安装并配置 dsh（DeepSeek Harness）

### 5.2 部署

**方式 A（推荐，若 dsh 支持项目级 CLAUDE.md）**：把 `templates/multi-agent/dsh/CLAUDE.md` 复制到项目根目录。

**方式 B（手动初始化）**：创建 orchestrator 配置目录，从 `templates/multi-agent/presets/` 复制预设写入 `roles.yaml` + `workflow.yaml`。

> ⚠️ dsh 是否自动读取 CLAUDE.md 取决于你的 Harness 版本——不确定就先手动初始化（方式 B）。

### 5.3 使用

触发方式与流程和另外两版相同（说"开发完整的XXX"→ 计划 → 执行 → 修复循环 → 收尾），**唯一的重大区别是状态复用机制**：

```
修复/复验时，dsh 按这个优先级选：
① send_message    给原子Agent 发消息续对话（上下文天然延续）——首选
② subagent_fork   继承原上下文创建新会话（原会话不可用时）
③ 文件恢复        新建子Agent + status.json 恢复上下文（崩溃/跨重启/都不行时兜底）
```

**铁律：无论用哪种方式，status.json 每次都必须更新**——原生复用可能随时失效（会话崩溃、过期），到时候只有文件能救命。

### 5.4 与另外两版的核心区别

| | Hermes / Claude Code 版 | dsh 版 |
|---|---|---|
| 修复时 | 只能新建 + status.json 恢复 | 优先 send_message 续对话 |
| 上下文 | 每次干净上下文（省 token） | 原生复用（上下文延续，但占 token） |
| 风险点 | 恢复文件缺失就断档 | 过度依赖原生会话，崩溃就断档 |

### 5.5 常见问题

| 问题 | 答案 |
|------|------|
| 原会话崩了，status.json 也没有？ | 别强行"恢复"——没有快照的延续等于全新 Agent 会重新设计。标记 needs_replan 报给人类 |
| 原生复用和文件恢复可以混用吗？ | 可以，按 5.3 的优先级走，但 status.json 永远要更新 |
| 并行上限？ | workflow.yaml 的 `max_parallel`（默认3），按 Harness 实际并发能力调整 |

---

## 六、核心机制速查（三版通用）

### 状态文件

| 文件 | 谁写 | 谁读 | 用途 |
|------|------|------|------|
| `progress.yaml` | 编排器 | 编排器 | **唯一进度真相源**（会话丢失后靠它恢复） |
| `status.json` | 子Agent | 子Agent+编排器 | 上下文快照（必填字段：task_id / agent_name / phase / context_digest） |
| `plan.md` | planner | 全部 | 任务清单（id/名称/描述/验收条件/depends_on） |
| `test-report.md` | tester | 编排器+修复方 | 判定依据（读 status 字段） |
| `review-report.md` | reviewer | 编排器+修复方 | 判定依据（critical 非空→FAILED） |
| `escalation.md` | 编排器 | 用户 | 超限升级报告 |

### 防幻觉三件套

1. **路径验证**：子Agent 返回的路径必须 `ls` 验证存在
2. **证据校验**：PASSED 报告引用的 evidence 文件必须非零字节 + 含实际运行命令/输出痕迹
3. **诚实规则**：修不好要如实记录，谎报"已修复"违反铁律

### 人类检查点（必须暂停，不自动通过）

- 计划产出 plan.md 后（Y执行 / N修改）
- 全部任务完成后（确认汇总）
- 任何任务 escalation 时（A跳过 / B重新设计 / C接受限制 / D换新开发者接手）

### 任务拆分原则（planner 遵守）

- 每个任务 1-4 小时工作量；**单任务应能在单个子Agent 会话内完成**（单模块、约 10 个文件以内）
- 总任务数 3-8 个；能并行的任务（无依赖）分开列出

---

## 七、故障排查速查表

| 症状 | 原因 | 解决 |
|------|------|------|
| 子Agent 返回的路径不存在 | 幻觉/未验证 | 打回重做，提醒"返回前 ls 验证" |
| evidence 文件是空的 | 伪造证据 | 按规则2 打回，提醒写入实际运行命令+输出 |
| 修复无限循环烧钱 | 没设上限 | roles.yaml 设 max_retries，超限必走 escalation |
| 恢复的子Agent 重新设计/重复犯错 | 没传 status.json | 必须传旧 status.json + 写明"你是 xx 的延续" |
| status.json 缺失/损坏 | 状态漂移 | 从报告文件/旧版本重建；重建不了标 needs_replan 报人 |
| progress.yaml 丢失 | 意外删除 | 扫描 output/ 下所有 status.json 重建 |
| 编排器自己写代码了 | 忘了身份 | 记住：你是项目经理，不是程序员 |
| 计划任务拆得太大/太小 | planner 没遵守粒度 | 重新规划，见"任务拆分原则" |

---

## 八、仓库文件清单

```
多agent协同方案/
├── README.md                    ← 本手册
└── templates/multi-agent/
    ├── prompts/                 ← 三版共用：角色模板
    │   ├── developer.md         │   开发（写代码，含诚实记录规则）
    │   ├── planner.md           │   计划（拆任务，含粒度约束）
    │   ├── tester.md            │   测试（实测+证据，含证据内容要求）
    │   └── reviewer.md          │   审查（一票否决权）
    ├── presets/                 ← 三版共用：预设
    │   ├── standard.yaml        │   计划→开发→测试
    │   ├── with-review.yaml     │   计划→开发→测试+审查
    │   ├── minimal.yaml         │   开发→测试
    │   └── ai-competition.yaml  │   分析→实验→评估
    ├── hermes/                  ← 🅱 Hermes 版（skill 内置，无需安装）
    │   └── orchestrator.md      │   编排规范（delegate_task 适配）
    ├── claude-code/             ← 🅰 Claude Code 版
    │   ├── CLAUDE.md            │   触发器（复制到项目根目录）
    │   ├── orchestrator.md      │   编排规范（Task/subagent 适配）
    │   └── install.sh/.bat      │   安装脚本（装到 ~/.claude/templates/）
    └── dsh/                     ← 🅲 dsh 版
        ├── CLAUDE.md            │   触发器（若 dsh 支持）
        └── orchestrator.md      │   编排规范（send_message/subagent_fork 原生复用优先）
```

---

## 许可

MIT
