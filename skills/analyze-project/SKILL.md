---
name: analyze-project
description: >-
  对软件项目进行多维度全面分析，输出结构化的专业分析报告（主报告 + 详情报告）。
  覆盖项目目标、技术栈、架构设计、模块关系、核心逻辑、依赖链、社区生态、使用方式、SWOT 评估等维度。
  仅当用户明确说出"使用 analyze-project"或"启动 analyze-project"时触发。
  不适用于任何隐式场景。
---

# Analyze Project

对软件项目进行系统性深度分析，产出言之有据的专业分析报告。

## 触发约束

此 skill **仅通过显式调用触发**。

### ⛔ 不触发的场景
- 用户提到"分析一下这个项目"、"看看代码"、"review"等但未提及 analyze-project
- 代码编写、bug 修复、功能开发过程中顺带的项目理解
- 用户未显式引用 @analyze-project

### ✅ 触发条件
必须同时满足：
1. 用户明确说出"使用 analyze-project"或"启动 analyze-project"，或显式引用 @analyze-project
2. 用户指定了目标项目路径或上下文

## 核心理念

分析报告的质量取决于三个要素：

1. **广度** — 覆盖足够多的分析维度，不遗漏关键方面
2. **深度** — 每个维度有代码级证据，不只是表面描述
3. **结构化** — 多份报告分层次组织，主报告导航 + 详情报告展开

输出不是"读了一遍代码后的感想"，而是基于事实的、可验证的、有结论的工程分析。

## 执行流程

整个分析分为 5 个 Phase，按顺序执行。Phase 1-2 中的子任务应尽量并行。

### Phase 1: 准备与项目探索

**目标**: 确定分析范围，加载分析方法论，初步了解项目全貌。

先读取方法论参考文件，再并行探索项目：

**步骤 A — 加载方法论** (直接读取，无需搜索)

**并行读取**以下 3 个参考文件（合计约 700 行，一次读入避免后续中断）：

1. [references/analysis-methodology.md](references/analysis-methodology.md) — 10 个核心分析维度、CHAOSS/OpenSSF/InfoQ 框架、报告结构、工具清单
2. [references/community-research-guide.md](references/community-research-guide.md) — 社区调研策略：平台列表、搜索词模板、结果组织方式
3. [references/report-guide.md](references/report-guide.md) — 报告编写指南：每份报告的内容维度、ASCII 图表规范、交叉引用规范

不需要重新搜索网络获取这些内容。Phase 1 步骤 C（制定分析计划）就需要 report-guide 的报告结构信息，提前读入可避免 Phase 2 中途打断。

**步骤 B — 项目初步探索** (使用 Agent, subagent_type: Explore)

快速扫描目标项目的全貌：

```
探索内容:
├─ 目录结构 (tree -L 3)
├─ README, LICENSE, CONTRIBUTING 等文档
├─ 配置文件 (package.json / requirements.txt / Cargo.toml / go.mod 等)
├─ 入口文件识别 (main / index / app)
├─ 技术栈初步判断
├─ Git 信息 (最近提交、贡献者、分支)
├─ 测试 / CI/CD / Docker 等基础设施
├─ demo/ 或 examples/ 目录
│   ├─ 示例输出的完整性和质量
│   ├─ 输出格式是否与项目描述一致
│   └─ 示例覆盖了哪些使用场景
├─ 数据库/Schema 文件 (Web 项目必查)
│   ├─ SQL 文件 (*.sql) — 表结构、索引、初始数据
│   ├─ 分库分表配置 (shardingsphere / sharding-jdbc / vitess)
│   ├─ ORM 映射文件 (MyBatis XML / Prisma schema / SQLAlchemy models)
│   └─ Migration 文件 (Flyway / Liquibase / Alembic)
├─ 安全相关 (所有项目类型)
│   ├─ 认证方式 (JWT/Session/OAuth/SSO)
│   ├─ 密码存储方式 (BCrypt/MD5/SHA/明文?)
│   └─ CVE/漏洞历史 (搜索 "{项目名}" CVE / vulnerability)
└─ Monorepo 检测
    ├─ 是否存在 pnpm-workspace.yaml / lerna.json / nx.json / turborepo
    ├─ 有几个子包？各自的 package.json name 和 description
    └─ 子包之间的依赖关系 (谁依赖谁)
```

输出: 项目全貌结构化报告 + **初步发现**（10-15 条，按严重性分级 🔴/🟡/🟢）。

初步发现格式示例：
```
🔴 CRITICAL: 静默遥测采集 MAC/用户名/主机名，无 opt-out — ClientReportRepository.java:32-71
🔴 CRITICAL: WebUI 无任何认证，局域网完全暴露 — WebServer.java:41-57
🟡 HIGH: V8Runtime 内存泄漏，ThreadLocal 未 close — JsCaller.java:15-21
🟢 POSITIVE: 虚拟线程 + Semaphore 限流设计优秀 — VirtualThreadLimiter.java
```

初步发现的价值：帮助 Phase 1 步骤 C 制定分析计划时决定是否需要独立安全/性能专题报告。

**Monorepo 识别**: 如果项目有多个子包（如 `packages/core`、`packages/cli`、`packages/web`），在后续 Phase 中需要为每个重要子包分别派遣 Explore Agent。判断标准：
- 子包数量 ≥ 2 且至少一个子包源文件 > 30 个 → 视为 monorepo
- 每个重要子包（源文件 > 20 个）应获得独立的深读 Agent

**两步完成后**，结合方法论的 10 个维度 + 项目特征确定：
- **项目类型** — 参考 [analysis-methodology.md](references/analysis-methodology.md) 第 2.5 节的分类学 (Web/CLI/SDK/数据管道/GUI/AI-LLM/Prompt-Skill/游戏引擎/混合型)。项目类型决定报告主题和评估维度。
  - **混合型项目**: 如果项目跨越 2+ 种类型（如 AI 创作工具 = AI/LLM + CLI + Web GUI + Skill），确定主要类型 + 次要类型，为主要类型选择核心报告，为次要类型增加专题报告。
  - **混合型项目报告命名示例**:
    - 小说下载器 (CLI 工具 + Web GUI + 爬虫): `04-crawler-engine.md` (核心逻辑), `06-web-interface.md` (多界面对比), `07-security.md` (安全与隐私)
    - AI 创作工具 (AI/LLM + CLI + Web): `04-ai-pipeline.md`, `06-web-interface.md`, `07-prompt-engineering.md`
    - 数据平台 (数据管道 + Web + SDK): `04-data-pipeline.md`, `06-api-design.md`, `07-deployment.md`
- 分析报告的数量和主题 (通常 8-10 份)
- 每份报告覆盖哪些维度
- 需要深入阅读的核心源文件列表
- 如果是 Prompt/Skill 项目，分析报告需包含 Prompt 工程分析和方法论体系专题

**步骤 C — 输出分析计划** (形式化输出 + 用户确认)

将上述决策写入分析计划表，并使用 AskUserQuestion 向用户确认：

```markdown
### 分析计划

项目类型: {类型}
报告计划:
| 编号 | 文件名 | 主题 | 覆盖维度 | 核心源文件 |
|------|--------|------|---------|-----------|
| 01 | 01-overview.md | 项目概览 | #1 项目目标 | README, CHANGELOG |
| 02 | 02-architecture.md | 架构分析 | #3 结构, #4 架构 | ... |
| ... | | | | |
| NN | NN-evaluation.md | 评估与建议 | 综合 | 全部 |

维度覆盖检查 (10 维度 × 报告分配):
| 维度 | 覆盖报告 |
|------|---------|
| #1 项目目标 | 01-overview |
| #2 技术栈 | 05-tech-stack |
| ... | |

⏸ 等待用户确认后进入 Phase 2。
```

同时，对每份计划中的报告执行 **TaskCreate**:
- subject: "编写 {filename}"
- description: "覆盖维度: {dimensions}"
- activeForm: "编写 {filename}"

### Phase 2: 深度阅读与社区调研

**目标**: 获取代码级证据和社区外部视角。

并行执行两个子任务：

**子任务 A — 核心源码深度阅读** (使用 Agent, subagent_type: Explore)

逐一阅读 Phase 1 识别出的所有核心源文件。

**Monorepo 多 Agent 分派**: 如果 Phase 1 识别为 monorepo，为每个重要子包分别派遣 Explore Agent，而非一个 Agent 读所有包。示例：
```
Agent 1 (Explore): core 包深读 — {packages/core/src/ 下的关键文件}
Agent 2 (Explore): cli + studio 包深读 — {packages/cli/src/ + packages/studio/src/}
Agent 3 (general-purpose): 社区调研 (始终独立)
```
每个 Agent 的提示词应列出该包的具体目录和文件，而非泛泛的 `{file_list}`。

**大型单体项目分派** (>100 个源文件，非 monorepo):

当项目是单个包但文件量大时，一个 Explore Agent 无法在上下文窗口内读完所有文件。
按**架构层次**拆分为 2-3 个 Explore Agent：

```
Agent 1 (Explore): 入口层 + 业务逻辑层
  — CLI/routes/handlers → Service/Use-case → Domain/Model
  — 关注: 数据流从输入到核心处理的完整路径

Agent 2 (Explore): 数据层 + 基础设施层
  — Repository/Storage → Database/External API → Config/Auth
  — 关注: 持久化策略、外部集成、配置管理

Agent 3 (general-purpose): 社区调研 (始终独立)
```

拆分原则:
1. 每个 Agent 获取一个完整的「数据流切面」，而非按目录随机分
2. Agent 1 追踪「请求从哪来、怎么处理」，Agent 2 追踪「数据存到哪、怎么取」
3. 如果有 API 层 + Worker 层，按层拆分；如果有 CQRS，按读/写路径拆分

**Agent 提示词策略**: 提示词越具体，Agent 输出质量越高。遵循以下原则：
1. **列出具体目录结构** — 告诉 Agent 要读哪些目录和文件
2. **按优先级分组** — P0 必读 / P1 重点 / P2 抽样
3. **指定关注点** — 每个目录/文件要关注什么 (设计模式？数据流？错误处理？)
4. **定义输出格式** — 每个文件的分析应包含什么字段
5. **要求汇总** — 最后输出设计模式清单、质量问题列表、模块关系图

**通用提示词模板**:

```
深读项目 {path}，按以下优先级阅读文件：

P0 (必读): {file_list_from_phase1_plan}
P1 (重点): {reference_files}
P2 (抽样): {scripts_and_tests}

对每个文件输出：
## {filename} (N行)
- **行数**: N
- **核心职责**: 一句话
- **关键设计**: 代码片段 + 解释
- **优点**: 1-3 个值得借鉴的设计点
- **问题**: 按 CRITICAL/HIGH/MED 分级，附行号
- **连接关系**: 被谁调用，调用谁

最后输出汇总：
- 架构发现列表 (编号 A1, A2, ... 附文件:行号)
- 设计模式清单 (模式名 + 位置 + 实现方式)
- 数据流图 (ASCII 绘制，从入口到输出的完整管线)
- 模块关系图 (ASCII 绘制，展示层次和调用关系)
- 安全问题清单 (按 CRITICAL/HIGH/MED 分级，附代码位置)
- 质量问题列表 (按 CRITICAL > HIGH > MED 排序，附编号)
```

**按项目类型的文件优先级指引**:

| 项目类型 | P0 核心文件 | P1 重点文件 | P2 抽样 |
|---------|------------|------------|--------|
| **Java Spring Boot** | Controller → Service → Mapper → Entity | Config / Security / Filter | Utils / VO / DTO |
| **Java (桌面/CLI/工具)** | Main/Launcher → Core/Service → Utils → Model | Config / CLI parser (picocli) / UI | Tests / Resources |
| **Node.js/Express** | routes → controllers → services → models | middleware / config | utils / tests |
| **Python/Django** | views → models → serializers | settings / middleware / signals | admin / forms |
| **Go** | handlers → services → repositories → models | middleware / config | utils / tests |
| **Rust** | main.rs/lib.rs → mod.rs 层次 → 核心 trait/struct → 错误类型定义 | Cargo.toml features / config / build.rs | tests / benches / examples |
| **Prompt/Skill** | SKILL.md (all) | references/ (核心知识文件) | scripts/ / demo/ |
| **AI/LLM** | Agent定义 → Pipeline → LLM调用 → Prompt | Config / State / Guard | Tests / Utils |
| **Python 数据管道/AI** | CLI入口 → Pipeline stages → LLM调用 → Schema/Prompt | Search/Storage/Embedding / Config / Runtime | Tests / Utils / Terminal |

**大型代码库 (>100 文件) 的深读策略**:

1. **先找 God File** — `find . -name '*.java' -o -name '*.py' -o -name '*.ts' | xargs wc -l | sort -rn | head -10`
2. **再找入口** — Application / main / index / app 文件
3. **追踪数据流** — 从入口到数据库，沿调用链读取
4. **抽样其余** — 非核心模块通过目录结构和命名推断

**AI/LLM 项目增强提示**: 如果项目是 AI/LLM 多智能体类型，在提示词中额外加入：
```
特别关注：
- Agent 类/接口定义：每个 Agent 的角色、继承关系、核心方法
- Agent 间协调：谁调用谁、数据如何流转、状态如何共享
- LLM 调用抽象：provider 接口、模型路由、重试策略
- Prompt 构建：系统提示模板、上下文注入、规则栈
- 状态管理：真相文件/状态存储、CQRS/Event Sourcing 模式
- 质量门控：审计维度、重试策略、温度递增
- 文件规模：标记 >50KB 的文件为潜在 God File
```

**Java 项目增强提示** (适用于所有 Java 项目):
```
特别关注：
- ThreadLocal 使用：是否有 clear()/remove()？与虚拟线程池配合是否安全？
  InheritableThreadLocal + VT pool = 潜在信息泄漏
- synchronized 与虚拟线程：是否会导致 carrier thread pinning？应改用 ReentrantLock
- 资源泄漏：InputStream/OutputStream/Connection 是否在 try-with-resources 中关闭？
- 并发集合：HashMap/ArrayList 是否在多线程上下文中使用？
  应改用 ConcurrentHashMap/CopyOnWriteArrayList
- GC 选择：是否显式指定 GC（G1/ZGC/Shenandoah）？
- Maven/Gradle profile 管理：native 依赖如何跨平台？profile 激活条件是否清晰？
- System.exit 滥用：是否在可重试场景中使用 System.exit 杀死整个进程？
```

**Rust 项目增强提示** (适用于所有 Rust 项目):
```
特别关注：
- Feature Flags 组合: Cargo.toml 的 [features] 段，互斥/依赖关系，
  #[cfg(feature = "xxx")] 是否导致两套独立实现（维护负担）
- unsafe 使用: grep -rn "unsafe" 统计，评估安全边界
- 并发原语选择: std::sync::Mutex vs tokio::sync::Mutex vs crossbeam
  在 async 上下文中混用是常见 bug 来源
  std::sync::Mutex 在 async 函数中持有跨 await 点 = 编译错误
  tokio::sync::Mutex 在同步代码中使用 = 性能浪费
- reqwest::blocking vs async: 全用 blocking 然后在 async 中 spawn_blocking
  是务实选择但需标记桥接点数量和性能影响
- OnceLock/LazyLock 缓存: 正则、编译模板等一次性初始化模式
- #[serde(skip)] 反模式: 运行时状态 (folder_path, registry) 混入持久化结构
  违反纯数据配置原则
- compile_error! 编译期约束: 用于强制 feature 互斥是优秀实践
- 错误类型层次: thiserror (库级精确) vs anyhow (应用级便捷) 的分工
- 生命周期标注复杂度: 复杂生命周期可能暗示过度耦合
- 技术栈迁移: 如果项目从其他语言重写为 Rust，增加迁移前后对比分析
  (分发方式、性能、内存、开发速度的维度对比)
```

**Python 项目增强提示** (适用于所有 Python 项目):
```
特别关注：
- 模块级副作用: load_dotenv() / logging.basicConfig() / warnings.filterwarnings()
  在模块顶层执行影响测试隔离性，应移到函数内部或 conftest.py
- 连接池/客户端复用: OpenAI client / SQLAlchemy engine / requests.Session / httpx.Client
  每次调用新建实例是常见性能问题，应模块级缓存或依赖注入
- ContextVar vs ThreadLocal: 异步场景应使用 ContextVar 实现请求级隔离
  InheritableThreadLocal + 异步 = 潜在信息泄漏
- pyproject.toml 规范: 版本声明、依赖管理 (dependencies vs optional-dependencies)
  检查是否有锁文件 (requirements.lock / poetry.lock / uv.lock)
- __init__.py 延迟导入: 避免启动时加载所有模块，检查导入链深度
- dataclass/Pydantic 参数封装: 函数签名 >5 个参数时应使用 dataclass 或 TypedDict
- GIL 与并发: CPU 密集型任务是否使用 multiprocessing / ProcessPoolExecutor
  I/O 密集型是否使用 asyncio / ThreadPoolExecutor
- 类型注解覆盖: 核心模块是否有 type hints，mypy/pyright 是否配置
- 测试隔离: fixture 是否有跨测试污染风险，mock 是否在模块级别
```

**大型单体项目 Agent 分派** (>100 个源文件，非 monorepo):

当项目是单个包但文件量大时（157 个 Python 文件、300+ 个 JS 文件等），
一个 Explore Agent 无法在上下文窗口内读完所有文件。按**架构层次**拆分：

```
Agent 1 (Explore): 入口层 + 业务逻辑层
  — CLI/routes/handlers → Service/Use-case → Domain/Model
  — 关注: 数据流从输入到核心处理的完整路径

Agent 2 (Explore): 数据层 + 基础设施层
  — Repository/Storage → Database/External API → Config/Auth
  — 关注: 持久化策略、外部集成、配置管理

Agent 3 (general-purpose): 社区调研 (始终独立)
```

**拆分原则**:
1. 每个 Agent 获取一个完整的「数据流切面」，而非按目录随机分
2. Agent 1 追踪「请求从哪来、怎么处理」，Agent 2 追踪「数据存到哪、怎么取」
3. 如果项目有明确的 API 层 + Worker 层，按层拆分
4. 如果项目有明确的读路径 + 写路径 (CQRS)，按路径拆分

**Web 项目安全分析提示**: 如果项目是 Web 应用，在提示词中额外加入：
```
安全分析重点：
- 密码存储：查找密码哈希方式 (BCrypt/MD5/SHA/明文?)
- 认证机制：JWT/Session/OAuth，Token 存储位置 (Cookie/Header)
- 输入校验：Controller 参数是否有校验，sort/order 参数是否白名单
- 路径遍历：文件读取/下载接口是否过滤 ../ 
- 并发安全：HashMap/ArrayList 是否在多线程上下文中使用
- 支付安全：金额/价格是否在客户端可篡改
- CVE 历史：搜索 "{项目名}" CVE OR vulnerability
```

**独立安全报告的创建条件**:
当项目满足以下任一条件时，应创建独立的 `NN-security.md` 报告：
1. Phase 1 初步发现中包含 ≥ 2 个 🔴 CRITICAL 级安全问题
2. 涉及用户隐私数据采集（遥测、日志上报、用户画像）
3. Web 应用无认证或认证机制薄弱
4. 存在 SSL/TLS 配置问题（信任所有证书、弱加密套件）
5. 凭证管理不当（明文存储、硬编码密钥、配置文件暴露）

安全报告应包含：
- 安全问题总览表（编号/严重性/问题/位置/影响）
- 每个 CRITICAL/HIGH 问题的详细分析（代码片段 + 攻击场景 + 修复建议）
- 隐私影响评估（数据采集清单、用户知情权、opt-out 机制）
- 安全加固建议（按优先级排序）
- 安全评估可视化（文本条形图）

**子任务 B — 在线社区调研** (使用 Agent, subagent_type: general-purpose)

参考文件已在 Phase 1 步骤 A 中加载（community-research-guide.md 和 report-guide.md）。直接执行针对目标项目的社区调研。

该指南固化了"去哪里找、用什么搜索词、提取什么信息"的通用策略。具体的搜索结果因项目而异，需要运行时搜索获取。

使用以下提示词模板：

```
调研项目 "{name}"，作者 "{author}"。

必查平台: GitHub, {project_specific_platforms_from_guide}
搜索词: "{name}", "{name}" review, "{name}" 评测, "{name}" tutorial

输出格式:
## GitHub 数据
| 指标 | 值 | 来源 |
|------|-----|------|

## 社区覆盖
| 平台 | 覆盖度 | 内容类型 | 链接 |
|------|--------|---------|------|

## 用户反馈 (每条附来源URL)
### 正面
### 负面
### 建议

## 竞品对比 (附来源URL)
| 项目 | Stars | 定位 | 差异化 |
|------|-------|------|--------|

## 关键发现 (3-5条)
```

```
调研内容 (参考 guide 中的详细策略):
├─ GitHub 数据 (stars, forks, issues, trending 历史)
├─ 中文平台覆盖 (知乎, CSDN, Bilibili, 掘金, V2EX...)
├─ 英文平台覆盖 (Reddit, HN, YouTube, Medium...)
├─ 作者背景和动机
├─ 教程、评测和推荐文章
├─ 与同类项目的对比
├─ 已知问题和用户反馈
└─ 衍生项目和 Fork
```

搜索策略: 中英文分别搜索，按 guide 中的搜索词模板组合关键词。

### Phase 2.5: 发现汇总与信息持久化

**目标**: 将 Phase 2 两个 Agent 的核心发现汇总为结构化中间产物，防止上下文衰减导致信息丢失。

Phase 2 的 Agent 返回数据量大，到 Phase 3 写报告时（尤其是第 4-10 份报告）可能已不在上下文窗口中。必须在写报告前将关键发现持久化。

在输出目录下写入 `{output_dir}/_findings.md`：

```markdown
# {项目名} — 分析发现汇总

> Phase 2 产物，作为 Phase 3 报告编写的单一输入源。

## 源码分析发现

### 架构发现
- {发现}: {filename}:{line} — {说明}

### 设计模式
- {模式}: {filename} — {证据}

### 质量问题
- [CRITICAL] {问题}: {filename}:{line}
- [HIGH] {问题}: {filename}:{line}
- [MED] {问题}: {filename}:{line}

### 安全发现 (Web 项目必填)
- 密码存储: {BCrypt/MD5/SHA/明文}
- 认证机制: {JWT/Session/OAuth}
- 路径穿越: {存在/不存在}
- 并发安全: {HashMap不安全/...}
- CVE 历史: {CVE-xxxx-xxxx, ...}

### 数据库发现 (Web 项目必填)
- 数据库类型: {MySQL/PostgreSQL/...}
- 表数量: ~{N}张
- 分库分表: {分片策略, 分片键, 分片数}
- 核心表: {表名1, 表名2, ...}

### 模块关系
- {模块A} → {模块B}: {调用方式}

### 数据流图
```
{ASCII 绘制的从输入到输出的完整数据流}
```

### 模块关系图
```
{ASCII 绘制的模块层次和调用关系}
```

## 社区调研发现

### 核心数据
| 指标 | 值 | 来源 |
|------|-----|------|

### 用户反馈 (原话引用)
- 正面: "..." — {来源URL}
- 负面: "..." — {来源URL}

### 竞品对比
| 项目 | 差异化 | 来源 |
|------|--------|------|

## 待验证假设
- {假设}: 需在 Phase 3 中用代码证据验证

## 维度覆盖预检
| 维度 | 初步覆盖情况 |
|------|-------------|
| #1 项目目标 | ✅/⚠️/❌ |
| ... | |
```

写完后向用户展示关键发现预览（3-5 条），使用 AskUserQuestion 确认是否继续：

> "关键发现: {摘要}。是否继续编写报告？需要补充调研吗？"

### Phase 3: 报告编写

**目标**: 将所有发现综合为结构化报告。

在用户指定的输出目录下，按项目名创建子目录存放报告。

默认输出路径: `{analysis_dir}/{项目名}/`

例如分析多个项目时的目录结构：

```
analysis/
├── AI_NovelGenerator/
│   ├── README.md
│   ├── 01-overview.md
│   └── ...
├── novel-plus/
│   ├── README.md
│   ├── 01-overview.md
│   └── ...
└── so-novel/
    ├── README.md
    └── ...
```

#### 报告体系

**主报告** `README.md`:
- 执行摘要 (项目一句话定位 + 关键发现表格)
- 综合评级 (多维度评分)
- 报告目录 (链接到所有详情报告)
- 分析方法论说明
- 项目快照表 (关键属性一览)

**详情报告** (编号 + 英文短名):

```
01-overview.md          — 项目概览
02-architecture.md      — 架构分析
03-modules.md           — 模块详解
04-core-logic.md        — 核心逻辑 (项目特定主题)
05-tech-stack.md        — 技术栈与依赖
...                     — 根据项目特征增减
NN-evaluation.md        — 评估与建议 (始终作为最后一份)
```

报告主题不是固定的。根据项目特征调整：
- Web 项目: 加 API 设计、前端架构、部署方案
- CLI 工具: 加命令行接口、插件机制
- SDK/库: 加公共 API 设计、版本策略、迁移指南
- 数据项目: 加数据流、ETL 管道、存储方案

每份报告的具体内容参考 [references/report-guide.md](references/report-guide.md)。

#### 写作原则

1. **言之有据** — 每个结论必须附带代码行号、文件路径或来源 URL
2. **代码片段** — 关键设计用简短代码片段说明，不要大段粘贴
3. **ASCII 图表** — 架构图、流程图、时序图使用 ASCII/Unicode 字符绘制
4. **表格对比** — 选型对比、竞品对比用表格呈现
5. **评分量化** — 尽可能给出数值评分或等级

#### 输出顺序

按以下顺序编写报告 (先写依赖关系最少的)：

```
第一批 (并行): README.md + 01-overview.md + 08-community.md    ← 3 份 (community 只依赖 Phase 2 调研数据)
第二批 (并行): 02-architecture.md + 03-modules.md + 05-tech-stack.md  ← 3 份
第三批 (并行): 04-core-logic.md + 其他项目特定报告              ← 2-4 份
最后一批:      NN-evaluation.md                                ← 1 份 (需要前面所有报告的信息)
```

> **关键优化**: 08-community.md 只依赖 Phase 2 社区调研数据，不依赖代码分析报告，可提前到第一批。

**批次灵活性**: 报告数量不是固定的 9 份。混合型项目可能需要 10-12 份报告。
批次策略应随报告数量调整：

| 报告数 | 推荐批次 | 说明 |
|--------|---------|------|
| 5-7 份 | 2+2+2+1 或 3+2+1+1 | 小项目，合并模块和技术栈 |
| 8-10 份 | 3+3+3+1 或 2+3+3+2+1 | 标准项目 |
| 11-13 份 | 3+3+3+3+1 或 3+4+4+1 | 混合型项目，多个专题报告 |

每批上限 3-4 个并行 Write。超过 4 个可能导致质量下降。

#### 批量写入策略

同一批次的报告使用**多个 Write 工具并行调用**，而非逐一写入。实测数据：
- 9-10 份报告分 4-5 批，每批 2-3 个 Write 并行
- 总耗时约 4-5 轮对话（不含读取和探索）
- 单份报告平均 150-560 行，3.7K-21K
- 实测 3 份并行 Write 稳定无问题
- 总计产出 3,380 行 / 156K（在 2500-4000 行预期范围内）

> **关键**：每批内的 Write 调用之间无依赖关系，应在同一个 tool_calls block 中并行发出。

#### 任务追踪

Phase 1 已通过 TaskCreate 为每份报告创建了任务。Phase 3 写报告时：

- 开始写一份报告前：`TaskUpdate` → `status: in_progress`
- 完成一份报告后：`TaskUpdate` → `status: completed`
- 写报告时参考 `{output_dir}/_findings.md` 作为单一数据源，避免上下文衰减

> **⚠️ 任务 ID 陷阱**: 每批次开始前，必须 `TaskList` 确认当前任务的 ID 与报告的对应关系。
> 错误示例：批次 1 写了 README + 01-overview + 08-community，但标记了 Task #13 (NN-evaluation) 为 in_progress，
> 导致 NN-evaluation 被提前标记完成，后续无法更新。
> **正确做法**: 每批次开始前打印 TaskList，按实际报告名匹配 Task ID 再更新状态。

### Phase 4: 校验与交付

**目标**: 通过可执行的验证脚本确认报告质量，修复发现的问题后交付。

**执行效率提示**: 验证步骤可合并为 1-2 个 bash 命令执行，减少对话轮次：
- 命令 1: 合并 4.1 维度覆盖 + 4.2 交叉引用 + 4.3 断裂链接 + 4.4 评分一致性
- 命令 2: 合并 4.6 文件统计 + 4.7 God File

实测单次命令即可完成 4 项验证，示例：
```bash
cd {output_dir} && \
echo "=== 维度覆盖 ===" && \
for dim in "项目目标" "技术栈" ...; do count=$(grep -l "$dim" *.md 2>/dev/null | wc -l); echo "  [$dim] → $count"; done && \
echo "=== 交叉引用 ===" && \
for f in *.md; do refs=$(grep -oP '\]\([^)]+\.md\)' "$f" 2>/dev/null | wc -l); echo "  $f: $refs 处引用"; done && \
echo "=== 断裂链接 ===" && \
(broken=0; for f in *.md; do ... done; [ $broken -eq 0 ] && echo "✅ 所有链接有效") && \
echo "=== 评分一致性 ===" && \
grep -E '^\| .+\| \*?\*?[0-9]+/[0-9]+' README.md NN-evaluation.md
```

#### 4.1 维度覆盖验证

读取 analysis-methodology.md 的 10 个核心维度，逐一检查：

```bash
for dim in "项目目标" "技术栈" "项目结构" "架构" "依赖" "代码质量" "核心概念" "核心逻辑" "社区" "使用方式"; do
  count=$(grep -l "$dim" *.md 2>/dev/null | wc -l)
  echo "[$dim] → $count 份报告"
done
```

**规则**: 0 覆盖的维度必须补充 — 追加到最相关的现有报告中，或新增专题报告。

#### 4.2 交叉引用验证

```bash
for f in *.md; do
  refs=$(grep -oP '\]\([^)]+\.md\)' "$f" | wc -l)
  echo "$f: $refs 处引用"
done
```

**规则**: 每份详情报告至少有 2 处指向其他报告的链接（参见 report-guide.md 交叉引用规范）。

#### 4.3 断裂链接验证

检查所有 `.md` 链接的目标文件是否存在。断裂的链接必须修复。

```bash
broken=0
for f in *.md; do
  while IFS= read -r link; do
    target=$(echo "$link" | sed 's/.*(\(.*\))/\1/' | sed 's/#.*//')
    if [ -n "$target" ] && [[ "$target" == *.md ]] && [ ! -f "$target" ]; then
      echo "❌ BROKEN: $f → $target"
      broken=$((broken+1))
    fi
  done < <(grep -oP '\[[^\]]+\]\([^)]+\.md[^)]*\)' "$f")
done
if [ $broken -eq 0 ]; then echo "✅ 所有链接有效"; fi
```

> **注意**: 不要使用 `grep -oP '\]\([^)]+\.md\)' "$f" | wc -l` 方式计数链接，该方式在多链接行中会产生误报。

#### 4.4 评分一致性验证

提取 README 和 evaluation 报告中的评分，逐项对比。注意两种格式都可能出现：
- README 可能用 `| 维度 | 8/10 |` 或 `| 维度 | **8/10** |`
- evaluation 可能用 `| 维度 | **8/10** |` 或 `| 维度 | 8/10 |`

```bash
# 提取评分行 (兼容有/无粗体)
grep -E '^\| .+\| \*?\*?[0-9]+/[0-9]+' README.md
grep -E '^\| .+\| \*?\*?[0-9]+/[0-9]+' *-evaluation.md
```

**规则**: 
1. 同一维度的评分必须一致。不一致的以 evaluation 报告为准，回填到 README。
2. evaluation 可以比 README 多 1-3 个维度（如"性能"、"创新性"等），这些额外维度不需要出现在 README 中。
3. README 维度数建议 8-10 个，evaluation 维度数建议 10-12 个。

**算术验证**: 综合评分必须等于各维度评分的算术均值，四舍五入到一位小数：

```bash
# 提取 evaluation 报告中所有 N/10 评分，计算均值
grep -oP '\*?\*?[0-9]+/10' *-evaluation.md | grep -oP '[0-9]+' | \
  awk '{sum+=$1; n++} END {if(n>0) printf "维度数: %d, 总分: %d, 均值: %.1f/10\n", n, sum, sum/n}'
```

**规则**: 如果报告中标注的"综合评分: X.X/10"与算术均值不一致，必须修正为算术均值。
这是常见的人工计算错误来源。

#### 4.5 报告间数据一致性

人工检查：
- 同一指标（如 stars 数、版本号）在各报告中数值相同
- 一份报告标为"优势"的不应在另一份报告标为"劣势"（除非有明确上下文说明）
- 关键发现不在 3+ 份报告中重复详细展开

#### 4.6 文件统计

```bash
for f in *.md; do lines=$(wc -l < "$f"); size=$(ls -lh "$f" | awk '{print $5}'); echo "$f | $lines 行 | $size"; done
```

#### 4.7 God File 检查

对分析的源项目执行 God File 扫描，结果记入 evaluation 报告：

```bash
find {project_path} -type f \( -name "*.java" -o -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.vue" -o -name "*.svelte" -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.c" -o -name "*.cpp" -o -name "*.rb" -o -name "*.php" -o -name "*.kt" -o -name "*.scala" \) | xargs wc -c 2>/dev/null | sort -rn | head -10
```

阈值参考 analysis-methodology.md §5.1。

#### 4.8 任务完成确认

```
TaskList → 确认所有报告 Task 状态为 completed
```

### Phase 5: 总结

向用户展示：

1. **文件清单表格** (文件名 / 内容 / 行数 / 大小)
2. **关键发现摘要** (3-5 条最重要的结论)
3. **数据来源统计** (读了多少文件、搜索了多少来源)
4. **维度覆盖矩阵** — 10 维度 × 报告的覆盖表 (使用 analysis-methodology.md §2 的矩阵模板)
5. **分析局限性** — 哪些维度因信息不足而分析较浅
6. **跨报告洞察** — 报告间的关联发现（如架构决策如何影响可维护性评分）
7. **未分析内容声明** — 明确列出哪些文件/模块/方面被跳过或仅抽样，让用户了解分析边界
8. **后续建议** — 值得进一步深入分析的方向

**维度覆盖矩阵输出格式**:
```
| 维度 | 覆盖报告 | 覆盖度 |
|------|---------|--------|
| #1 项目目标 | 01-overview | ✅ 完整 |
| #2 技术栈 | 05-tech-stack | ✅ 完整 |
| ... | | |
```

## 并行策略

分析过程中大量使用并行 Agent 提升效率：

```
Phase 1: [读取 3 个参考文件 (并行)] + [项目探索 (Explore Agent)]  ← 一次加载所有方法论
Phase 2: [源码深读]   ‖ [社区调研]     ← 社区调研策略从已加载的 references/ 获取，具体数据运行时搜索
         Monorepo 项目: [core 深读] ‖ [cli+web 深读] ‖ [社区调研]  (3 路并行)
         前后端分离项目: [后端深读] ‖ [前端深读] ‖ [社区调研]  (3 路并行)
Phase 2.5: [发现汇总持久化]            ← 将 Agent 产出写入 _findings.md，防止上下文衰减
Phase 3: 报告编写 (按依赖顺序分批并行)  ← 参考 _findings.md 作为单一数据源
         推荐批次: 3+3+3+1 (README+overview+community → arch+modules+tech → core+专题 → evaluation)
```

**前后端分离识别**: 项目根目录同时存在 `backend/` + `frontend/` 或 `server/` + `client/` 或 `api/` + `web/` 时，按前后端分别派遣 Explore Agent。每个 Agent 的提示词应列出该端的具体目录和文件。

每个 Agent 的职责要明确，避免重复工作。Explore 类 Agent 负责代码阅读，general-purpose Agent 负责网络搜索和综合分析。方法论和社区调研策略已固化在 `references/` 中，不需要每次重新搜索。

## 常见问题处理

**项目很小 (< 10 个文件)**:
减少报告数量 (3-5 份)，合并模块和技术栈分析。

**项目很大 (> 100 个文件)**:
优先分析核心路径上的文件，非核心模块通过目录结构和命名推断。使用多个 Explore Agent 并行扫描不同子系统。

**Monorepo 项目 (多子包)**:
为每个重要子包 (源文件 > 20 个) 分别派遣 Explore Agent。在模块详解报告中按包分章节。架构报告需覆盖包间依赖关系。

**混合型项目 (跨类型)**:
按主要类型选择核心报告 (01-05)，次要类型增加专题报告 (06-08)。评分维度取各类型并集。

**无 README 或文档**:
从代码和配置文件推断项目目标。查看入口文件、CLI 帮助、测试用例获取使用方式。

**私有项目或无在线存在**:
跳过社区调研，将精力集中在代码分析上。

**非英语/非中文项目**:
根据项目主要语言调整搜索关键词。代码分析不受语言影响。

## 常见项目模式识别

在实践中，以下模式反复出现。识别它们可以显著提升分析深度：

| 模式 | 识别信号 | 分析动作 |
|------|---------|---------|
| **God File** | 单文件 > 50KB 或 > 1000 行 | 标记为技术债务，建议拆分 |
| **多框架混用** | 同项目使用 2+ 个安全/ORM/日志框架 | 标记为维护风险，建议统一 |
| **并发安全缺陷** | HashMap/ArrayList 在多线程上下文中使用 | 标记为潜在bug，建议 ConcurrentHashMap |
| **硬编码配置** | 路径/密钥/端口直接写在源码中 | 标记为部署风险，建议外部配置化 |
| **重复代码块** | 3+ 个方法有相似的前置/后置逻辑 | 标记为维护成本，建议抽取公共方法 |
| **CQRS 状态层** | 读写分离、权威数据源 + 缓存索引 | 绘制写入/读取路径图 |
| **Pipeline 架构** | 多阶段串行处理 (plan→execute→validate) | 绘制管线流程图 + 质量门 |
| **多 Agent 协调** | 多个 Agent 类、工具注册、会话管理 | 分析 Agent 角色分工和通信 |
| **统一 Action Surface** | CLI/TUI/Web 共享核心引擎 | 对比各界面功能矩阵 |
| **Schema-first 设计** | Zod/TypeBox/Protobuf 定义驱动 | 评估类型安全和验证覆盖 |
| **Event Sourcing** | 事件日志、检查点、状态可回溯 | 分析事件流和恢复机制 |
| **内嵌大字符串** | 提示词/模板/SQL 内嵌在代码中 | 评估可维护性，建议外置 |
| **单作者供应链风险** | 核心依赖来自 1-2 人维护的项目 | 标记为依赖风险 |
| **双语/多语维护** | 代码中同时存在中英日等多语文本 | 评估维护成本和一致性 |
| **装饰器注册表** | `@register_xxx` 装饰器 + 全局字典，模块导入即注册 | 评估零配置注册的可发现性和隐式依赖风险 |
| **模板方法提取器** | 基类定义固定流程 + 子类实现 3-5 个方法 (load/merge/build) | 评估基类抽象质量、子类一致性、配置驱动 vs 代码驱动 |
| **双模式运行** | 项目同时支持桌面 (Electron/Tauri) + Web 浏览器 | 对比各界面功能矩阵、mock 层设计、IPC 桥接 |
| **SSE 双通道** | EventSource (长连接) + fetch ReadableStream (请求级) 并存 | 分析各自适用场景、重连策略、兜底机制 |
| **Prompt 三层分布** | 数据库存储 + 代码内嵌 + 动态组装混合 | 评估可维护性、国际化能力、用户自定义空间 |
| **ContextVar 依赖注入** | Python ContextVar 实现请求级依赖隔离，避免参数穿透 | 评估注入清晰度和测试友好性 |
| **Feature Gate 双构建** | `#[cfg(feature)]` / build tags 拆出两套独立实现 | 评估维护成本、功能降级矩阵、是否可合并 |
| **运行时状态寄生** | `#[serde(skip)]` 或 `@JsonIgnore` 将运行时状态嵌入持久化结构 | 标记为设计反模式，建议分离到独立状态结构 |
| **阻塞/异步桥接** | `spawn_blocking` / `run_in_executor` 包装阻塞调用 | 标记桥接点数量，评估是否可迁移为纯异步 |
| **编译期互斥约束** | `compile_error!` / static assert 强制配置互斥 | 评价为优秀实践（防止非法组合） |
| **闭源依赖寄生** | 核心功能依赖不可审计的私有/闭源库 | 标记供应链风险，评估可替代性和可审计性 |
| **技术栈迁移** | 项目从语言 A 完全重写为语言 B | 增加迁移前后对比表（分发/性能/内存/开发速度） |
| **竞争定位象限** | 同赛道有 3+ 竞品 | 绘制 Stars vs 专用度/通用度 象限图 |
| **YAML-first 数据模型** | YAML/JSON 文件为事实来源 + DB 为可重建查询层 + sync 机制 | 评估双写一致性、可审计性、断点续传能力；绘制 YAML↔DB 同步路径图 |
| **契约驱动设计** | 单一契约文件 (fields.yaml/schema) → 多处同步 (提示词/校验/代码) | 评估同步完整性：修改一处是否真能多处生效；检查消费方是否全部接入 |
| **LLM 断点续传** | 每个处理单元 (章/批次/阶段) 独立文件保存 + 已完成项跳过 | 评估中断恢复能力、状态粒度、合并策略；检查是否有"状态真空" |
| **LLM 优雅降级** | LLM 失败时用统计兜底/默认值/空结构，不中断流程 | 评估每阶段降级策略完整性；检查是否有"降级真空"(某阶段无兜底) |
| **动态温度控制** | 根据流水线进度调整 LLM temperature (前期低/后期高) | 评估策略是否有数据支撑；检查阈值配置化程度 |
| **三路召回 + RRF** | lexical + semantic + structured 三通道 + Reciprocal Rank Fusion | 评估通道互补性、融合参数 (k 值)、单路失败降级、重排策略 |
| **可发现性分析** | 项目名在搜索引擎中被同名异义内容压制 | 评估 SEO 影响；建议消歧策略 (添加 topics/description/改名) |

## 报告规模参考

基于实践数据的报告规模指导：

| 报告类型 | 典型行数 | 典型大小 |
|---------|---------|---------|
| README.md (主报告) | 70-120 行 | 3-6K |
| 概览报告 (01) | 150-250 行 | 5-10K |
| 架构报告 (02) | 300-500 行 | 15-25K |
| 模块报告 (03) | 400-500 行 | 15-20K |
| 核心逻辑 (04) | 400-600 行 | 18-30K |
| 技术栈 (05) | 200-300 行 | 8-15K |
| 专题报告 (06-08) | 250-450 行 | 9-20K |
| 评估报告 (NN) | 180-250 行 | 8-15K |

| 项目类型 | 报告数 | 合计行数 | 合计大小 |
|---------|--------|---------|---------|
| 标准项目 (单一类型) | 9 份 + README | 2,800-3,800 行 | 100-160K |
| 混合型项目 (跨 2-3 类型) | 10-12 份 + README | 3,500-4,500 行 | 140-200K |
| 小型项目 (< 10 文件) | 3-5 份 + README | 800-1,500 行 | 30-60K |

## 参考资源

| 文件 | 用途 | 加载时机 |
|------|------|----------|
| [references/analysis-methodology.md](references/analysis-methodology.md) | 分析方法论：10 维度、CHAOSS/OpenSSF 框架、报告结构、工具清单 | Phase 1 开始时 (与其他两个并行读取) |
| [references/community-research-guide.md](references/community-research-guide.md) | 社区调研策略：平台列表、搜索词模板、结果组织方式 | Phase 1 开始时 (与其他两个并行读取) |
| [references/report-guide.md](references/report-guide.md) | 报告编写指南：每份报告的内容维度、ASCII 图表规范、交叉引用规范 | Phase 1 开始时 (与其他两个并行读取) |
