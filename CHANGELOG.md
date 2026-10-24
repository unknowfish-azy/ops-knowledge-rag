# Changelog

本文件遵循 [SemVer](https://semver.org/lang/zh-CN/)（MAJOR.MINOR.PATCH）。

## [Unreleased]

### Added
- 前端 AI 对话支持语音输入（Web Speech API，渐进增强；不支持的浏览器自动隐藏入口）。
- 语音识别结果仅追加到输入框，不自动发送、不上传音频。
- 图像证据链路：普通会话中截屏/拍照/图片附件本地暂存，随流式消息将文件名传给 ai-service；`ChatRequest` 新增 `images` 字段，AI 思考过程新增"图像证据解析"阶段，提示词包含图像证据段落（mock 链路可演示，图片内容不上传）。

### Changed
- 仓库卫生：停止跟踪 `backend/.m2` 本地 Maven 仓库、`frontend/.vite-once-cache` 预构建缓存与用户运行时知识库数据，并补齐 `.gitignore`。
- README 多模态能力说明与实现对齐。
- 共享逻辑层（`api/`、`domain/`、`utils/`、`types/` 共 48 个模块）迁移到 TypeScript；Vue 组件与 Pinia store 保持 JavaScript，Vite 构建兼容；新增 `tsconfig.json` 与 `npm run typecheck`。
- 分包策略收敛到 `vite.shared.mjs`，用户层与管理员层共用；zrender 从 echarts 拆分，`vendor-echarts` 由 510 kB 降至 346 kB，新增独立 `vendor-zrender`（166 kB），Three.js 仍为懒加载 chunk。

## [0.1.0] - 2026-10-24

### Added
- 初版竞赛交付：智维Agent（SmartOpsAgent）——面向中小企业的可信 AI 智能运维与知识协同平台。
- 前端：Vue 3 + Vite + Element Plus + Pinia + ECharts + Three.js 运维控制台。
- 后端：Spring Boot（运维数据 / 账户 / 审计），FastAPI AI 服务（LLM 网关、对话、RAG 编排）。
- Agent 框架：规划(planner) / 执行(executor) / 核查(inspector) / 记忆(memory) / 策略(policies)。
- 检索：混合检索知识服务 + 证据验证（防错误版本知识）。
- 工具集成：MCP 适配器、Function Calling、Docker 工具。
- 可信安全：权限/风险策略引擎 + 人工审批 + 审计留痕。
- 竞赛文档：项目计划书、创新点设计、Demo 脚本、答辩稿。
- 仓库就绪：README（12 章骨架）、MIT LICENSE、CHANGELOG、`.env.example` 环境模板。
