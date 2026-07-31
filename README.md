# 多Agent协同编排框架

让 Claude Code 突破上下文窗口限制，通过多智能体协同完成大型开发任务。

## 这是什么

Claude Code 单次会话的上下文窗口有限，面对大项目时容易被代码、日志等内容撑爆。

本方案让 Claude Code 变成**编排器**——它不亲自写代码，而是创建子Agent分别负责计划、开发、测试、审查。各Agent之间通过文件路径通信，主Agent上下文始终保持轻量。

## 核心设计

| 设计要点 | 说明 |
|---------|------|
| 文件路径传递 | 子Agent只返回路径，不返回代码，主Agent上下文不膨胀 |
| SendMessage复用 | 谁写的bug谁修、谁提的bug谁验，不重复创建Agent |
| 3轮重试上限 | 修不好自动升级给人决策，不死循环 |
| 角色可扩展 | 需要什么Agent就声明什么，不绑定固定类型 |

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

在项目根目录创建 `CLAUDE.md`，写入编排器指令（见下方），然后正常使用 Claude Code：

```
帮我开发一个命令行计算器，支持加减乘除
```

Claude Code 会自动进入编排器模式。

### 3. CLAUDE.md 模板

把下面的内容保存为项目根目录的 `CLAUDE.md`：

```markdown
# 编排器模式

🚨 **你现在是编排器，不是程序员。禁止自己写代码。**

## 收到任务时的第一反应

用户说"开发XXX"时，先检查 `.claude/orchestrator/` 目录：
- 没有 → 问用户选预设（standard / with-review / minimal / 自定义）
- 有 → 读取配置，进入编排流程

## 编排流程

### 阶段1：计划
读取 planner.md 模板 → Agent工具创建 planner → 等返回 plan.md → 暂停给用户确认

### 阶段2：逐个任务
每个任务:
  Agent创建 dev-{N} → 等产出 → Agent创建 test-{N} → 等测试报告
  测试失败 → SendMessage(dev)修复 → SendMessage(test)重验 (最多3轮)
  3轮仍失败 → escalation.md → 暂停等用户

### 阶段3：完成
展示汇总，暂停等确认

## 核心铁律
1. 子Agent只返回文件路径，不返回代码
2. 修复用SendMessage找原开发Agent（不新建）
3. 验收用SendMessage找原测试Agent（不新建）
4. 最多修3轮，超了暂停
5. 不读代码，只看status.json和escalation.md
```

## 预设配置

| 预设 | 角色 | 适合场景 |
|------|------|---------|
| `standard` | 计划→开发→测试 | 常规开发任务 |
| `with-review` | 计划→开发→测试+审查 | 代码质量要求高 |
| `minimal` | 开发→测试 | 需求明确的小任务 |
| `ai-competition` | 分析→实验→评估 | AI比赛方案探索 |

需要自定义时，编辑项目下的 `.claude/orchestrator/roles.yaml` 和 `workflow.yaml`。

## 目录结构

```
项目/
├── CLAUDE.md              ← 编排器入口（复制模板）
├── requirements.md         ← 需求文档
├── .claude/orchestrator/  ← 项目配置（自动生成）
│   ├── roles.yaml
│   └── workflow.yaml
├── plan.md                 ← 计划产出
├── progress.yaml           ← 进度追踪
└── output/                 ← 所有代码产出
    ├── task-1/v1/ ... vN/
    ├── task-2/v1/ ... vN/
    └── summary.md
```

## 添加自定义Agent

1. 写一个提示词模板放到 `~/.claude/templates/multi-agent/prompts/`
2. 在项目 `.claude/orchestrator/roles.yaml` 中声明新角色
3. 在 `workflow.yaml` 中指定它何时执行

下次运行编排器时自动生效。

## 许可

MIT
