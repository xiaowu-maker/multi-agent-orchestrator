# 多Agent协同编排框架

让 Claude Code 突破上下文窗口限制，通过多智能体协同完成大型开发任务。

## 这是什么

Claude Code 单次会话的上下文窗口有限，面对大项目时容易被代码、日志等内容撑爆。

本方案让 Claude Code 变成**编排器**——它不亲自写代码，而是创建子Agent分别负责计划、开发、测试、审查。各Agent通过文件路径通信，主Agent上下文始终保持轻量。

## 核心设计

| 设计要点 | 说明 |
|---------|------|
| 文件路径传递 | 子Agent只返回路径，不返回代码，主Agent上下文不膨胀 |
| SendMessage复用 | 谁写的bug谁修、谁提的bug谁验，不重复创建Agent |
| 动态工作流 | 从 YAML 读取角色顺序，加新角色不用改 CLAUDE.md |
| 每角色独立模型 | developer 用 sonnet 写代码，tester 用 haiku 省钱，各跑各的 |
| 3轮重试上限 | 修不好自动升级给人决策，不死循环 |
| 角色可扩展 | 需要什么Agent就在 YAML 里声明什么 |

## 快速开始

### 1. 安装（一次性，1分钟）

**Windows：**
```bat
install.bat
```

**Mac / Linux：**
```bash
bash install.sh
```

安装脚本会把模板文件复制到 `~/.claude/templates/multi-agent/`。

### 2. 在项目中使用

把仓库里的 `CLAUDE.md` 复制到你的项目根目录，然后正常使用 Claude Code：

```
帮我开发一个命令行计算器，支持加减乘除
```

编排器会自动检测项目未初始化 → 让你选预设 → 创建 `.claude/orchestrator/` 配置 → 开始干活。

### 3. 是怎么运作的

三层配置，各自分工：

```
workflow.yaml              roles.yaml               prompts/*.md
(执行顺序)    ──引用──→   (角色配置+模型)  ──引用──→  (提示词)
per_task:                  developer:                "你是软件工程师..."
  - role: developer  →      prompt: developer.md
  - role: reviewer   →      model: sonnet
  - role: tester     →      paired_with: [developer]
```

**workflow.yaml** — 角色按什么顺序执行  
**roles.yaml** — 每个角色叫什么、用哪个模型、和谁配对  
**prompts/*.md** — 每个角色具体干什么活

加新角色只需改 YAML 两个文件，CLAUDE.md 不用动。

## 预设配置

| 预设 | 角色 | 适合场景 |
|------|------|---------|
| `standard` | 计划→开发→测试 | 常规开发任务 |
| `with-review` | 计划→开发→测试+审查 | 代码质量要求高 |
| `minimal` | 开发→测试 | 需求明确的小任务 |
| `ai-competition` | 分析→实验→评估 | AI比赛方案探索 |

## 自定义配置

### 添加新角色（3步）

**① 写提示词**

在 `~/.claude/templates/multi-agent/prompts/` 下新建一个 `.md` 文件，告诉这个 Agent 它是谁、干什么、输出什么。

**② 声明角色（roles.yaml）**

```yaml
summarizer:
  description: "项目完成后生成总结报告"
  prompt: "~/.claude/templates/multi-agent/prompts/summarizer.md"
  model: haiku              # 轻量模型，省钱
  lifecycle: once           # 用完即弃
  paired_with: []           # 不需要配对审查
```

**③ 加入工作流（workflow.yaml）**

```yaml
  per_task:
    - role: developer
    - role: tester
    - role: summarizer      ← 加一行

  # 或者在全部任务完成后执行：
  finalize:
    - role: summarizer
```

下次运行自动生效。

### 为每个角色指定不同模型

```yaml
developer:
  model: sonnet              # 写代码用强模型

tester:
  model: haiku               # 测试用轻量模型，省钱

reviewer:
  model: opus                # 审查用最强推理能力
```

支持所有 `/model` 命令列出的模型名：`sonnet`、`opus`、`haiku`、`fable`、`best`、`default` 等。

### 配对审查（自动 SendMessage 复用）

```yaml
developer:
  paired_with: [tester, reviewer]    # 开发完 → 测试和审查同时检查
  max_retries: 3                     # 不通过最多修3轮

tester:
  paired_with: []                    # tester只管测，测完不管修复

reviewer:
  paired_with: []                    # reviewer只管审，审完不管修复
  veto_power: true                   # 审查有一票否决权
```

编排器自动处理：
- 测试不通过 → SendMessage 原 developer 修复 → 修完 SendMessage 原 tester 重验
- 审查不通过 → SendMessage 原 developer 修复 → 修完 SendMessage 原 reviewer 重审
- 3轮还不行 → 生成 escalation.md → 暂停等人类决策

**你只管在 YAML 里写配对关系，SendMessage 复用全自动。**

## 目录结构

```
项目/
├── CLAUDE.md              ← 编排器入口（复制模板）
├── requirements.md         ← 需求文档
├── .claude/orchestrator/  ← 项目配置
│   ├── roles.yaml          ← 有哪些Agent + 用什么模型
│   └── workflow.yaml       ← Agent的执行顺序
├── plan.md                 ← 计划产出
├── progress.yaml           ← 进度追踪
└── output/                 ← 所有代码产出
    ├── task-1/v1/ ... vN/
    ├── task-2/v1/ ... vN/
    └── summary.md
```

## 许可

MIT
