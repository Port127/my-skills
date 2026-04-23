# Skill 开发规范

本仓库存放全局 SKILL.md 文件。所有 skill 必须遵循以下规范。

## 触发原则

**所有 skill 均为手动触发，禁止自动触发。**

- NEVER 在完成任务后自动触发任何 skill
- NEVER 定期提醒用户使用任何 skill
- NEVER 在对话中"顺便"执行任何 skill
- 只有用户明确说出"使用 {skill-name}"或"启动 {skill-name}"，或显式引用 @{skill-name} 时才触发

## SKILL.md 结构规范

遵循 [Agent Skills 开放标准](https://agentskills.io/specification)。

### Frontmatter

只保留 `name` 和 `description` 两个必需字段，禁止添加非标准字段（如 `when_to_use`、`argument-hint`、`arguments` 等）。

```yaml
---
name: skill-name
description: >-
  {1句话描述功能，第三人称，关键词密集}。
  仅当用户明确说出"使用 {skill-name}"或"启动 {skill-name}"时触发。
  不适用于任何隐式场景。
---
```

**规则**：
- `name`：1-64 字符，仅小写字母、数字、连字符，不以连字符开头或结尾
- `description`：1-1024 字符，必须包含 WHAT（功能）+ WHEN（触发条件）
- 禁止使用 `when_to_use`、`argument-hint`、`arguments` 等非标准字段

### Body

在标题之后、正文之前，必须包含统一的触发约束段落：

```markdown
# {Skill 标题}

## 触发约束

此 skill **仅通过显式调用触发**。

### ⛔ 不触发的场景
- 用户提到相关功能但未提及 {skill-name}
- 日常文档编辑、代码编写、完成任务后的"顺便"操作
- 用户未显式引用 @{skill-name}

### ✅ 触发条件
必须同时满足：
1. 用户明确说出"使用 {skill-name}"或"启动 {skill-name}"，或显式引用 @{skill-name}
2. 用户提供了明确需求或上下文
```

⛔ 场景中的第一条应根据 skill 功能定制（例如 skill-discovery 写"发现模式"、"提炼能力"等）。

### 内容约束

- SKILL.md 正文不超过 500 行
- 使用渐进式披露：主文件放核心指令，深度内容放到 `references/` 目录
- 文件引用不超过一层深度（相对路径，从 SKILL.md 出发）
- 不编造未验证的模式，不使用占位符或空模板

## 创建新 Skill 流程

1. 确定 skill 名称（小写 + 连字符）和功能描述
2. 按上述格式编写 SKILL.md
3. 在 `~/.cursor/skills/` 下创建 `{skill-name}/SKILL.md`（个人全局 skill）
4. 将 SKILL.md 同步到此仓库存档

## 禁止事项

- NEVER 自动触发任何 skill
- NEVER 在 SKILL.md 中使用非标准 frontmatter 字段
- NEVER 让 SKILL.md 超过 500 行（拆分到 references/）
- NEVER 在 description 中留空或写过于笼统的内容（如 "帮助处理 XXX"）
