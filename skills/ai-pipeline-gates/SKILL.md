---
name: ai-pipeline-gates
description: >-
  为 AI 驱动的多步骤流水线添加脚本门控（gating），防止 agent 跳过中间步骤、保证关键节点质量校验、分级阻断。
  仅当用户明确说出"使用 ai-pipeline-gates"或"启动 ai-pipeline-gates"时触发。
  不适用于任何隐式场景。
---

# AI Pipeline Gate Pattern

## 触发约束

此 skill **仅通过显式调用触发**。

### ⛔ 不触发的场景
- 用户提到"流水线"、"门控"、"验证"等但未提及 ai-pipeline-gates
- 日常代码编写、完成任务后的"顺便"添加校验
- 用户未显式引用 @ai-pipeline-gates

### ✅ 触发条件
必须同时满足：
1. 用户明确说出"使用 ai-pipeline-gates"或"启动 ai-pipeline-gates"，或显式引用 @ai-pipeline-gates
2. 用户提供了明确需求或上下文

## 问题

在 AI 驱动的多步骤流水线中，agent 倾向于：

1. **跳过扫描阶段**——直接跳到"写文件"步骤
2. **自作主张绕过校验**——"这个检查意义不大"然后继续
3. **在低质量基础上继续构建**——错误的输入导致垃圾级联输出
4. **伪造完成状态**——改 meta 状态而不实际执行

这是 LLM 的行为特征，不是 bug。LLM 追求"完成任务"而非"按流程完成"。

**靠 SKILL 文案的约束不够用。必须用脚本门控（exit code 阻断）。**

---

## 模式

### 核心原则

```
流水线阶段 A → 脚本验证（只读、快速、幂等） → 通过 → 阶段 B
                                        ↓ exit 1
                                   阻断，输出诊断报告
```

### 设计规则

| 规则 | 说明 |
|------|------|
| **只读检查** | 验证脚本只读取数据，不修改任何文件。失败时不产生副作用。 |
| **快速** | 单次执行 < 10 秒。不阻塞 agent 的正常流程。 |
| **幂等** | 重复执行结果一致。agent 重新运行不会出问题。 |
| **先写报告再阻断** | exit 1 前先把诊断信息写入文件（如 quality_report.yaml），让 agent 能读取具体原因。 |
| **脚本在 SKILL 之前** | SKILL 告诉 agent 该做什么，脚本强制 agent 不能绕过。 |

### 阈值设计：分级而非一刀切

```python
# 错误做法：单一阈值，非黑即白
if density < 0.4:
    sys.exit(1)  # 太严，正常情况也可能触发

# 正确做法：分级
if density < 0.25:
    sys.exit(1)        # 严重不足 → 强制阻断
elif density < 0.4:
    print("⚠️ 建议补切") # 偏低 → 警告但放行
# else: 正常
```

**为什么分级**：
- 太严 → agent 被迫花大量时间补切边际情况，用户烦躁
- 太松 → 没有约束力
- 分级 → 真正差的情况拦住，边缘情况让用户知情后自行决定

---

## 实施步骤

### Step 1: 识别关键节点

在你的流水线中找出**不可逆的转换点**——一旦数据从这里流过，后续步骤都基于它的质量。

常见位置：
| 流水线类型 | 关键节点 |
|-----------|---------|
| 数据处理 | 清洗 → 分析之间 |
| 内容生成 | 素材拆分 → 索引构建之间 |
| 代码生成 | 代码生成 → 测试运行之间 |
| 数据分析 | 数据提取 → 报告生成之间 |

### Step 2: 编写验证脚本

```python
#!/usr/bin/env python
"""gate_checker.py — 流水线门控验证"""
import sys

def check(data):
    """返回 (passed: bool, message: str)"""
    score = compute_quality_score(data)
    if score < 0.25:
        return False, f"质量评分 {score:.2f} 严重不足（阈值 < 0.25）"
    if score < 0.4:
        return None, f"质量评分 {score:.2f} 偏低（建议 >= 0.4）"
    return True, f"质量评分 {score:.2f} ✅"

def main():
    data = load_data()
    passed, message = check(data)

    # 总是输出诊断信息
    write_diagnostic_report(data, "gate_report.yaml")

    if passed is False:
        print(f"🚫 阻断: {message}")
        print("  诊断报告: gate_report.yaml")
        sys.exit(1)
    elif passed is None:
        print(f"⚠️  警告: {message}")
    else:
        print(f"✅ 通过: {message}")

if __name__ == '__main__':
    main()
```

### Step 3: 在 SKILL 中声明门控

在你的流水线 SKILL 中添加：

```markdown
### Step N: 质量门控（强制）

执行验证：
```bash
python gate_checker.py
```

如果脚本返回非零退出码：
- **禁止进入下一步**
- 读取诊断报告，修复问题
- 重新运行验证

此步骤不可跳过。
```

---

## 真实案例

### 案例：小说素材流水线

**问题**：36 章小说只拆分出 12 个事件（密度 0.33），但 agent 直接进入索引构建和精调阶段，最终产物完整度仅 2.6%。

**修复**：在事件拆分和索引构建之间加入 `quality_audit.py` 全书审计：

```
novel-events (all)
    ↓
quality_audit.py  ← 新增门控
    ├── 密度 < 0.25 → exit 1（阻断）
    ├── 密度 0.25-0.4 → 警告（放行）
    └── 连续缺口 > 3 → exit 1（阻断）
    ↓
build-index
```

**效果**：agent 无法在密度不足时继续流水线，必须补切事件。

---

## 常见反模式

| 反模式 | 为什么不行 | 正确做法 |
|--------|-----------|---------|
| 只在 SKILL 里写"MUST 检查" | agent 会认为"这个不重要"然后跳过 | SKILL + 脚本双重约束 |
| 验证脚本修改数据 | 阻断后留下半成品 | 验证脚本只读，诊断报告另写 |
| 只有一个硬阈值 | 太严或太松 | 分级：严重阻断 / 警告放行 / 通过 |
| 阻断时不输出诊断 | agent 不知道具体哪里不行 | exit 1 前先写诊断文件 |
| 每个节点都加门 | 过度工程化，agent 频繁被打断 | 只在不可逆转换点加门 |

---

## 什么时候不需要门控

| 情况 | 原因 |
|------|------|
| 单步操作 | 没有"中间步骤"可跳过 |
| 结果立即可验证 | 用户一眼就能看出对错 |
| 失败代价低 | 重跑成本 < 1 分钟 |
| 确定性脚本 | 不需要 LLM 判断，纯逻辑执行 |

---

## 硬约束

- MUST 门控脚本只读不写（诊断报告除外）
- MUST 分级阈值（至少两级：阻断 / 警告）
- MUST exit 1 前先输出诊断信息到文件
- MUST 在 SKILL 中声明"此步骤不可跳过"
- NEVER 在每个微步骤都加门——只在关键转换点加
- NEVER 让验证脚本本身成为失败源（保持简单）
