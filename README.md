# 智维Agent / SmartOpsAgent

> **面向中小企业的可信 AI 智能运维与知识协同平台** —— 基于 AI Agent + RAG + MCP + 可信安全闭环构建的 AI Native Web 应用。

![license](https://img.shields.io/badge/license-MIT-blue)
![stack](https://img.shields.io/badge/stack-Vue3%20%7C%20FastAPI%20%7C%20SpringBoot-blue)
![version](https://img.shields.io/badge/version-0.1.0-green)
![ai](https://img.shields.io/badge/AI-Agent%20%7C%20RAG%20%7C%20MCP-orange)

**目录**：[项目定位](#1-项目定位与解决的问题) · [技术栈](#2-技术栈与命名) · [对比方案](#3-解决什么问题与传统运维对比) · [工作原理](#4-工作原理) · [目录结构](#5-目录结构) · [安装运行](#6-安装与运行) · [快速开始](#8-快速开始使用) · [AI 能力](#9-核心-ai-能力) · [创新点](#10-创新点) · [文档导航](#13-文档导航与交付材料)

---

## 1. 项目定位与解决的问题

中小企业在日常运维中普遍面临：运维知识分散、故障定位依赖个人经验、传统检索返回错误版本知识、大模型结论不可验证、AI 能分析却无法安全执行、操作缺乏验证与审计。

智维Agent 把"监测 → 分析 → 知识检索 → 证据验证 → 决策规划 → 风险判断 → 人工审批 → 安全执行 → 结果验证 → 审计留痕 → 经验沉淀"连成可信闭环，让 AI 从"会回答运维问题"走向"可信地完成运维任务"。

---

## 2. 技术栈与命名

| 层 | 技术 |
|---|---|
| 前端 | Vue 3 + Vite + TypeScript（共享逻辑层）+ Element Plus + Pinia + Vue Router + ECharts + Three.js |
| 后端 | Spring Boot（运维数据 / 账户 / 审计） |
| AI 服务 | FastAPI（LLM 网关、对话、RAG 编排） |
| Agent 框架 | Python（planner / executor / inspector / memory / policies） |
| 检索 | 混合检索（Hybrid Retrieval：关键词 + 向量）知识库 |
| 工具集成 | MCP 适配器、Function Calling、Docker 工具 |
| 多模态 | 3D 可视化（Three.js）+ 图表（ECharts）+ 语音输入（Web Speech API）+ 截屏/拍照证据附件 |
| 模型接入 | OpenAI 兼容网关（mock / Ollama / OpenAI 兼容均可，默认 mock 零密钥跑通） |

> 命名约定：仓库名 `SmartOpsAgent` = 目录名 = 文档标题，保持唯一一致。

---

## 3. 解决什么问题（与传统运维对比）

| 痛点 | 智维Agent 方案 |
|---|---|
| 知识分散、版本混乱 | 版本感知知识库 + 混合检索，检索策略可解释 |
| 大模型结论不可信 | 证据验证 + 风险策略引擎 + 人工审批，输出可解释可控 |
| AI 不能安全执行 | 受控执行（executor）+ 权限/风险策略 + 审计留痕 |
| 故障处理无证据链 | inspector 核查 + audit 审计，全程可追溯 |
| 学习成本高 | 对话式入口 + AI 思考过程可视化，降低使用门槛 |

---

## 4. 工作原理

```text
监测(Monitor)
   │
   ▼
分析(Analyze) ──► 知识检索(Knowledge RAG) ──► 证据验证(Evidence)
   │                                            │
   ▼                                            ▼
决策规划(Planner/Agent) ◄──────────────────────┘
   │
   ▼
风险判断(Risk Policy) ──► 人工审批(Human-in-the-loop)
   │
   ▼
安全执行(Executor / Tools / MCP)
   │
   ▼
结果验证(Inspector) ──► 审计留痕(Audit) ──► 经验沉淀(Memory)
```

| 阶段 | 模块 | 作用 |
|---|---|---|
| 规划 | `agent/planner` | 将故障拆解为可执行的 Agent 计划 |
| 执行 | `agent/executor` + `agent/tools` | 调用工具 / MCP 完成运维动作 |
| 核查 | `agent/inspector` | 结果验证，生成证据 |
| 记忆 | `agent/memory` | 短期/长期经验沉淀，版本感知 |
| 策略 | `agent/policies` | 权限/风险判定，安全兜底 |
| 检索 | `knowledge/` | 混合检索 + 证据增强 |

---

## 5. 目录结构

```text
SmartOpsAgent/
├── frontend/        # Vue 3 运维控制台（用户层 + 管理员层）
├── backend/         # Spring Boot 后端（数据/账户/审计）
├── ai-service/      # FastAPI AI 服务（LLM 网关、对话、RAG 编排）
├── agent/           # Python Agent 框架（planner/executor/inspector/memory/policies）
├── knowledge/       # 知识库与混合检索服务
├── infrastructure/  # 部署与可观测性（Prometheus/Grafana 等）
├── docs/            # 架构、API、实验与竞赛材料
├── training/        # 训练与评测脚本
├── tests/           # 单元/集成/E2E 测试
├── scripts/         # 启动与运维脚本（含 Windows）
├── data/            # 种子/样例数据（不含密钥与二进制）
├── .env.example     # 环境变量模板（密钥一律留空）
├── README.md        # 本文件
├── LICENSE          # MIT
└── CHANGELOG.md     # 版本记录
```

---

## 6. 安装与运行

### 前置依赖
- Node.js ≥ 18（构建/运行）；执行 `npm test` 需 Node ≥ 22.18（测试直接加载共享层 `.ts`）
- Python ≥ 3.11
- JDK 17（后端）
- MySQL 8、Redis 7
- Ollama（可选，本地模型；不装则使用 `mock` 提供方）

### 步骤
```bash
# 1) 环境变量：复制模板并填入（密钥仅在 .env 中，绝不入库）
cp .env.example .env

# 2) 启动 AI 服务（默认 mock 提供方，无需任何密钥即可跑通）
cd ai-service && pip install -r requirements.txt && uvicorn app.main:app --port 8001

# 3) 启动知识库服务
cd knowledge && # 按 knowledge/README 启动检索编排

# 4) 启动后端（Spring Boot）
cd backend && ./mvnw spring-boot:run   # 或 mvn spring-boot:run

# 5) 启动前端（用户层 5173 / 管理员层 5174）
cd frontend && npm install && npm run dev
# 管理员层：npm run dev:admin

# 质量检查：单元测试 + 类型检查 + 构建
cd frontend && npm test && npm run typecheck && npm run build
```

- 用户层入口：`http://127.0.0.1:5173/login`
- 管理员层入口：`http://127.0.0.1:5174/login?portal=admin`
- 首次管理员由 `SMARTOPS_BOOTSTRAP_USERNAME` / `SMARTOPS_BOOTSTRAP_PASSWORD` 引导创建（仅账户表为空时生效）。

### 安全说明
- 所有密钥经环境变量注入，**绝不出现在代码或公开仓库**。
- `.env`、`.runtime/`、密钥文件均已被 `.gitignore` 屏蔽。
- 管理入口有会话/CSRF/频率限制；生产部署需另行配置 TLS 与共享限流。

---

## 7. 依赖与环境

- `LLM_PROVIDER=mock|ollama|openai-compatible`：默认 `mock`，零密钥即可演示完整链路。
- `VITE_API_BASE_URL`：前端构建时注入的后端地址。
- 外部模型密钥（如 `LLM_API_KEY`、`ZHIPU_API_KEY`）仅在 `.env` 中配置，模板里全部留空。
- 跨平台：Windows 提供 `scripts/windows/*.ps1`；Linux/macOS 可用等效 shell 脚本。

---

## 8. 快速开始（使用）

1. 浏览器打开用户层入口并登录（或自助注册普通账号）。
2. 进入 Agent 对话，提交一个故障现象（如"MySQL 连接数打满"）；也可点击麦克风用语音描述（需浏览器支持）。
3. 观察 AI 思考过程可视化 → 规划 → 检索证据 → 风险判断 → 人工审批 → 安全执行 → 结果验证 → 审计留痕的完整闭环。
4. 在监控/知识/模型网关等页面查看可视化分析与多模态呈现。

---

## 9. 核心 AI 能力

- **LLM 集成（8%）**：OpenAI 兼容网关，可切换 Provider；Prompt 模板集中于 `agent/prompts/`，输出稳定可控。
- **Agent / 工作流（8%）**：planner→executor→inspector 闭环，具备规划、工具调用、自主决策能力。
- **RAG（6%）**：混合检索 + 证据验证，检索策略可解释，显著降低错误版本知识干扰。
- **多模态（5%）**：Three.js 3D + ECharts 图表可视化；对话支持语音输入（Web Speech API，Chrome/Edge 可用）与截屏/拍照图像证据（文件名随消息参与 AI 模拟解析，图片内容保留在本地不上传）。
- **AI 安全与可控（4%）**：policies 权限/风险引擎 + 人工审批 + 审计留痕，体现"可信 AI"。
- **MCP / 工具集成（4%）**：`agent/tools/adapters/mcp.py` 已实现 MCP 适配，支持外部工具/数据源接入。

---

## 10. 创新点

- **选题创新**：聚焦中小企业"可信运维"这一真实且未被充分满足的需求。
- **技术创新**：把"规划—风险—执行—验证—审计"做成端到端可信闭环，而非单点 AI 调用。
- **交互创新**：AI 思考过程可视化 + 流式输出 + 语音输入，降低运维 AI 的使用门槛。

---

## 11. 许可证与团队

- 代码以 **MIT** 许可证发布（见 `LICENSE`）。
- 外部数据集如有单独许可，将在对应目录声明，不与代码许可混同。

### 团队信息（TODO：由团队填写）
<!-- TODO: 学校 / 成员(1-3人同校) / 组别(研究生组 / A组 / B组 / C组) -->
| 角色 | 姓名 | 备注 |
|---|---|---|
| 指导教师 | （待填） | （可选，≤2 名） |
| 队员 | （待填） | |
| 队员 | （待填） | |

---

## 12. 更新与维护

- 版本变更见 `CHANGELOG.md`；改了什么 → 改哪个文件 → 版本如何升，均在其中记录。
- 路线图：流式多模态增强、端侧推理（Transformers.js / WebGPU）、多节点会话与 MFA。
- 反馈与共建欢迎通过仓库 Issue 提出。

---

## 13. 文档导航与交付材料

| 类别 | 文档 |
|---|---|
| 架构 | [架构总览](docs/SMARTOPS_ARCHITECTURE.md) · [模块地图](docs/SMARTOPS_MODULE_MAP.md) · [分层前端服务](docs/layered-frontend-services.md) |
| API | [Agent](docs/api/agent.md) · [认证](docs/api/auth.md) · [知识](docs/api/knowledge.md) · [监控](docs/api/monitor.md) · [服务器](docs/api/server.md) |
| 实验与评测 | [评测计划](docs/experiments/evaluation-plan.md) · [消融实验](docs/experiments/ablation-study.md) · [检索](docs/experiments/retrieval.md) · [可信度](docs/experiments/trust.md) |
| 竞赛材料 | [项目计划书](docs/competition/project-plan.md) · [创新点](docs/competition/innovation.md) · [Demo 脚本](docs/competition/demo-script.md) · [答辩稿](docs/competition/defense.md) |
| 调整方案清单 | [adjustment-plan.md](docs/competition/adjustment-plan.md)（仓库托管 / TS 改造 / 多模态 / 材料收口的逐项状态） |
| 技术文档 | [technical-document.pdf](docs/competition/technical-document.pdf)（HTML 源：同目录 `technical-document.html`） |
| 功能说明 | [AI 对话历史](docs/ai-chat-history.md) · [聊天附件](docs/chat-attachments.md) · [模型接入](docs/model-integrations.md) · [插件中心](docs/plugin-center.md) |

> 生成技术文档 PDF：`cd frontend && node ../scripts/export-technical-pdf.mjs`（依赖 Playwright + Edge）。
