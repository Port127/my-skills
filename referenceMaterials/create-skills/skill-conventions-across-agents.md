# Agent Skill 系统横向对比 — 约定与最佳实践

扫描时间：2026-04-23
来源：.cursor、.claude、.codex、hermes-agent、openclaw、claude-code、deer-flow

---

## 1. 统一基础：Agent Skills 开放规范

所有系统都遵循或兼容 [agentskills.io](https://agentskills.io/specification) 开放标准：

- **目录结构**：`skill-name/SKILL.md`（必需）+ 可选 `scripts/`、`references/`、`assets/`
- **Frontmatter**：YAML，至少包含 `name`（≤64 字符，kebab-case）和 `description`（≤1024 字符）
- **渐进式加载**：元数据常驻 → SKILL.md body 按需加载 → 参考文件深度加载
- **主文件建议不超过 500 行**

---

## 2. 各系统的 SKILL.md Frontmatter 字段对比

| 字段 | 开放规范 | .cursor | .claude | .codex | hermes-agent | openclaw | claude-code | deer-flow |
|------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| `name` | 必需 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `description` | 必需 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `license` | 可选 | — | ✓ | — | ✓ | — | — | ✓ |
| `version` | — | — | ✓ | — | ✓ | — | ✓ | ✓ |
| `author` | — | — | — | — | ✓ | — | — | — |
| `metadata` | 可选 | — | — | — | ✓ | ✓(openclaw) | — | ✓ |
| `compatibility` | 可选 | — | — | — | — | — | — | ✓ |
| `allowed-tools` | 实验 | ✓ | ✓ | — | — | — | ✓ | ✓ |
| `when_to_use` | — | 非标准 | — | — | — | — | ✓ | — |
| `argument-hint` | — | 非标准 | ✓ | — | — | — | ✓ | — |
| `arguments` | — | 非标准 | ✓ | — | — | — | ✓ | — |
| `context` (inline/fork) | — | — | — | — | — | — | ✓ | — |
| `model` | — | — | — | — | — | — | ✓ | — |
| `effort` | — | — | — | — | — | — | ✓ | — |
| `user-invocable` | — | — | — | — | ✓ | ✓ | ✓ | — |
| `disable-model-invocation` | — | — | — | — | — | ✓ | ✓ | — |
| `paths` (条件激活) | — | — | — | — | — | — | ✓ | — |
| `hooks` | — | — | — | — | — | — | ✓ | — |
| `command-dispatch` | — | — | — | — | — | ✓ | — | — |
| `platforms` | — | — | — | — | ✓ | — | — | — |
| `dependencies` | — | — | — | — | ✓ | — | — | — |
| `required_environment_variables` | — | — | — | — | ✓ | — | — | — |

**结论**：只有 `name` + `description` 是所有系统通用的必需字段。其他字段均为各系统的扩展。

---

## 3. Skill 存储位置与优先级

### 3.1 各系统的 Skill 加载路径

| 系统 | 个人全局 | 项目级 | 其他 |
|------|---------|--------|------|
| **.cursor** | `~/.cursor/skills/` | `.cursor/skills/` | `~/.cursor/skills-cursor/`（内置，不可写） |
| **.claude** | `~/.claude/skills/` | `.claude/skills/` | 插件自带（marketplace） |
| **.codex** | `~/.codex/skills/` | — | 插件 marketplace（superpowers 体系） |
| **hermes-agent** | `~/.hermes/skills/` | — | `skills/`（bundled）+ `optional-skills/` + external_dirs |
| **openclaw** | `~/.agents/skills/` | `<workspace>/.agents/skills/` | `<workspace>/skills/`（最高优先级）+ bundled + extraDirs |
| **claude-code** | `~/.claude/skills/` | `.claude/skills/` | managedPath + plugin + bundled |
| **deer-flow** | `skills/custom/`（gitignored） | — | `skills/public/`（bundled，提交到仓库） |

### 3.2 openclaw 加载优先级（从高到低）

1. `<workspace>/skills/`（最高）
2. `<workspace>/.agents/skills/`
3. `~/.agents/skills/`
4. `~/.openclaw/skills/`
5. Bundled skills
6. `skills.load.extraDirs`（最低）

### 3.3 claude-code 加载优先级

1. policySettings（managed）
2. project（`.claude/skills/`）
3. user（`~/.claude/skills/`）
4. plugin / bundled

---

## 4. 各系统的 Skill 创建/开发最佳实践

### 4.1 Cursor — create-skill（499 行）

**核心原则**：
- Concise is Key — 只添加 agent 不知道的内容
- 保持 SKILL.md 不超过 500 行
- 渐进式披露：核心指令在 SKILL.md，深度内容放 `references/`
- 文件引用不超过一层深度

**描述规范**：
- 第三人称编写（注入 system prompt）
- 包含 WHAT + WHEN + 触发关键词
- 关键词密集，简洁优先

**创建流程**：Discovery → Design → Implementation → Verification

### 4.2 .claude — skill-creator + skill-development

**Anatomy of a Skill**（规范最完整）：
- 三级渐进加载：元数据 → SKILL.md → 参考文件
- 写作风格：使用祈使/不定式（动词优先），不用第二人称
- 避免重复：信息只在一个地方出现
- 超过 1 万词的参考文件，在 SKILL.md 中提供 grep 搜索模式

**Skill 创建过程**：
1. 用具体例子理解 skill
2. 规划可复用内容
3. 通过 `scripts/init_skill.py` 初始化
4. 编辑完善
5. 通过 `scripts/package_skill.py` 打包
6. 基于实际使用迭代

### 4.3 .codex — superpowers/writing-skills（656 行）

**Skill 类型**：
1. Technique — 具体方法，有步骤
2. Pattern — 思维方式
3. Reference — API 文档、语法指南

**描述规范**：
- 以 "Use when..." 开头
- 包含具体触发条件、症状、场景
- 不超过 500 字符
- **不要在 description 中总结 skill 的流程**

**命名规范**：
- 主动语态，动词优先
- 用动名词（-ing）：`creating-skills`、`testing-skills`
- 按"你做什么"命名，不按"它是什么"

**Token 效率目标**：
- 常用 skill < 200 词
- 其他 skill < 500 词

**跨 skill 引用**：用 skill 名称（如 `superpowers:test-driven-development`），不用 `@` 语法

**铁律**：TDD 方式创建 skill — 先在没有 skill 的情况下测试基线，再写最小 skill，再重构

### 4.4 hermes-agent — 最完整的运行时体系

**SKILL.md frontmatter schema**（agentskills.io 兼容 + Hermes 扩展）：
```yaml
name: my-skill
description: Brief desc
version: 1.0.0
author: Name
license: MIT
platforms: [macos, linux]
dependencies: [package>=version]
metadata:
  hermes:
    tags: [tag1, tag2]
    related_skills: [other-skill]
    requires_toolsets: [web]
    requires_tools: [web_search]
    fallback_for_toolsets: [browser]
required_environment_variables:
  - name: API_KEY
    prompt: "Enter your API key"
```

**安全体系**：
- 所有外部 skill 经过 `skills_guard.py` 静态扫描
- 检测数据外泄、提示注入、破坏性命令、供应链攻击
- 信任等级：builtin > official > trusted > community > agent-created

**Agent 自改进**：完成复杂任务（5+ 工具调用）后，agent 可自动创建新 skill 捕获过程记忆

### 4.5 openclaw — 最成熟的 gating 系统

**metadata.openclaw**（单行 JSON）：
```json
{
  "emoji": "🐙",
  "requires": { "bins": ["gh"] },
  "install": { "brew": ["gh"] }
}
```

**Gating 机制**：
- `requires.bins` — 所需二进制在 PATH 中
- `requires.anyBins` — 至少一个存在
- `requires.env` — 所需环境变量
- `os` — 平台过滤
- `always: true` — 跳过所有 gate

**Skill Workshop**：实验性插件，自动从 agent 行为中捕获可复用过程并生成 skill 草案

**Skill 快照**：会话启动时记录当前 skill 状态，确保会话内一致性

### 4.6 claude-code — 最复杂的运行时

**扩展 Frontmatter 字段**（超出开放规范）：
- `context: inline|fork` — 内联展开或子 agent 执行
- `model` — 模型覆盖
- `effort` — 推理力度
- `paths` — glob 条件激活
- `hooks` — PreToolUse/PostToolUse/Stop 钩子
- `skills` — 预加载子 skill 列表（仅 agent）

**Skillify**（内置 skill 创建工具）：
- 分析当前会话，识别可复用过程
- 4 轮用户访谈确定名称/步骤/触发条件
- 生成标准 SKILL.md

**Skill 自改进**：每 5 条用户消息后，自动分析对话中用户对 skill 的纠正，生成更新建议并写入文件

**Skill 使用追踪**：指数衰减评分（7 天半衰期），影响 skill 在建议中的排序

### 4.7 deer-flow — Web Agent 体系

**分类系统**：
- `public/` — 提交到仓库的公开 skill
- `custom/` — gitignored 的自定义 skill
- 名称冲突用 `{category}:{name}` 解决

**Skill 演化配置**：
```yaml
skill_evolution:
  enabled: false  # 默认禁止 agent 创建/修改 skill
  moderation_model_name: null
```

**安全**：所有 skill 写入前经过安全扫描，agent 只能修改 custom skill

**打包格式**：`.skill` 文件为 ZIP 归档

---

## 5. 触发约束模式对比

| 系统 | 触发方式 | 自动发现机制 | 手动触发支持 |
|------|---------|-------------|-------------|
| .cursor | description 关键词匹配 | 系统自动扫描所有 skill 的 description | 用户引用 @skill-name |
| .claude | description 关键词匹配 | 系统自动扫描 | 用户 `/skill-name` |
| .codex | description 以 "Use when..." 开头 | 关键词匹配 | 自然语言引用 |
| hermes-agent | `skills_list()` + `skill_view()` | 显式调用 slash command | `hermes skills` CLI |
| openclaw | description 关键词匹配 | 系统自动扫描 | `openclaw skills` CLI |
| claude-code | description + `when_to_use` | 关键词匹配 + `SkillTool` | `/skill-name` |
| deer-flow | 按需加载 | 用户选择启用/禁用 | Web UI settings |

**共同模式**：description 是所有系统加载 skill 的第一道筛选条件。描述写得不好 = skill 永远不会被触发。

---

## 6. 通用最佳实践提炼

### 6.1 Frontmatter 规范

```yaml
---
name: skill-name              # 必需：kebab-case，≤64 字符
description: >-               # 必需：≤1024 字符，第三人称，WHAT + WHEN
  {功能描述，关键词密集}。
  仅当用户明确说出"使用 {skill-name}"或"启动 {skill-name}"时触发。
  不适用于任何隐式场景。
---
```

### 6.2 Body 规范

1. 标题后紧跟触发约束段落（⛔ 不触发 / ✅ 触发条件）
2. 正文不超过 500 行
3. 使用渐进式披露
4. 文件引用不超过一层

### 6.3 命名规范

- 小写字母 + 数字 + 连字符
- 动词/动名词优先：`creating-skills`、`systematic-debugging`
- 避免泛名：`helper`、`utils` → 改为具体名称

### 6.4 安全约束

- 验证脚本只读不写
- 分级阈值（阻断 / 警告 / 通过）
- 阻断前输出诊断报告
- 不在 skill 中存储密钥

---

## 7. 各系统 Skill 创建脚本对比

| 系统 | 初始化脚本 | 打包脚本 | 验证脚本 |
|------|-----------|---------|---------|
| .claude | `scripts/init_skill.py` | `scripts/package_skill.py` | — |
| openclaw | `scripts/init_skill.py` | `scripts/package_skill.py` | — |
| deer-flow | `scripts/init_skill.py` | `scripts/package_skill.py` | `scripts/quick_validate.py` |
| .codex (superpowers) | — | — | subagent 压力测试 |
| hermes-agent | `skill_manage` API | — | `skills_guard.py` 安全扫描 |
| claude-code | `skillify` 内置 skill | — | AI 自改进 hooks |
