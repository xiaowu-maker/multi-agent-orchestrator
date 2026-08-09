# 多Agent协同编排框架

让 AI 突破上下文窗口限制，通过多智能体协同完成大型开发任务。

## 这是什么

单次会话的上下文窗口有限，面对大项目时容易被代码、日志等内容撑爆。

本方案让主Agent变成**编排器**——它不亲自写代码，而是创建子Agent分别负责计划、开发、测试、审查。各Agent通过**文件路径**通信，主Agent上下文始终保持轻量。

## 核心设计

| 设计要点 | 说明 |
|---------|------|
| 文件路径传递 | 子Agent只返回路径，不返回代码，主Agent上下文不膨胀 |
| 状态恢复复用 | 子Agent是一次性的，修复/复验用"新建 + status.json 恢复上下文"实现复用 |
| 动态工作流 | 从 YAML 读取角色顺序，加新角色不用改规范文件 |
| 每角色独立模型 | 在 roles.yaml 里为每个角色指定模型（留空=默认） |
| 重试上限 | 修不好自动升级给人决策，不死循环 |
| 路径验证 | 子Agent返回的路径必须验证存在，防幻觉 |
| 角色可扩展 | 需要什么Agent就在 YAML 里声明什么 |

## 快速开始（Claude Code）

### 1. 安装（一次性，1分钟）

**Windows：**
```bat
install.bat
```

**Mac / Linux：**
```bash
bash install.sh
```

安装脚本会把模板复制到 `~/.claude/templates/multi-agent/`。

### 2. 在项目中使用

把 `CLAUDE.md` 复制到你的项目根目录，然后正常使用 Claude Code：

```
帮我开发一个命令行计算器，支持加减乘除
```

编排器会自动检测项目未初始化 → 让你选预设 → 创建 `.claude/orchestrator/` 配置 → 开始干活。

## 预设配置

| 预设 | 角色 | 适合场景 |
|------|------|---------|
| `standard` | 计划→开发→测试 | 常规开发任务 |
| `with-review` | 计划→开发→测试+审查 | 代码质量要求高 |
| `minimal` | 开发→测试 | 需求明确的小任务 |
| `ai-competition` | 分析→实验→评估 | AI比赛方案探索 |

## 自定义配置

### 添加新角色（3步）

**① 写提示词**：在 `~/.claude/templates/multi-agent/prompts/` 下新建一个 `.md` 文件。

**② 声明角色（roles.yaml）**

```yaml
summarizer:
  description: "项目完成后生成总结报告"
  prompt: "prompts/summarizer.md"
  model: ""                # 留空=默认模型
  paired_with: []          # 不需要配对审查
  max_retries: 0
  veto_power: false
```

**③ 加入工作流（workflow.yaml）**

```yaml
  per_task:
    - role: developer
    - role: tester
    - role: summarizer      # ← 加一行

  # 或者在全部任务完成后执行：
  finalize:
    - role: summarizer
```

### 为每个角色指定不同模型

```yaml
developer:
  model: sonnet              # 写代码用强模型
tester:
  model: haiku               # 测试用轻量模型，省钱
reviewer:
  model: opus                # 审查用最强推理能力
```

留空 `""` 则使用当前默认模型。Claude Code 支持 `/model` 命令列出的模型名；Hermes 环境留空即可。

### 配对审查（自动修复循环）

```yaml
developer:
  paired_with: [tester, reviewer]    # 开发完 → 测试和审查同时检查
  max_retries: 3                     # 不通过最多修3轮

tester:
  paired_with: []                    # tester只管测，测完不管修复

reviewer:
  paired_with: []
  veto_power: true                   # 审查有一票否决权
```

编排器自动处理：
- 测试不通过 → 状态恢复模式找原 developer 修 → 修完找原 tester 重验
- 审查不通过 → 状态恢复模式找原 developer 修 → 修完找原 reviewer 重审
- 3轮还不行 → 生成 escalation.md → 暂停等人类决策

## 目录结构

```
项目/
├── CLAUDE.md              ← 编排器入口（复制模板）
├── requirements.md         ← 需求文档
├── .claude/orchestrator/  ← 项目配置
│   ├── roles.yaml          ← 有哪些Agent + 用什么模型
│   └── workflow.yaml       ← Agent的执行顺序
├── plan.md                 ← 计划产出
├── progress.yaml           ← 进度追踪（编排器唯一状态源）
└── output/                 ← 所有代码产出
    ├── task-1/v1/ ... vN/
    ├── task-2/v1/ ... vN/
    └── summary.md
```

## 许可

MIT
