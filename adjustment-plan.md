# 比赛调整方案清单（Adjustment Plan）

> 来源：WorkBuddy 对话（根据比赛要求制定的调整方案）。本清单跟踪各项决策的落地状态。
> 更新日期：2026-10-24

## 决策记录

| 决策项 | 结论 |
| --- | --- |
| 托管平台 | 公开 GitHub 仓库（由团队手动推送，AI 不持有凭据） |
| TypeScript 改造深度 | 部分改造：仅共享逻辑层（`api/`、`domain/`、`utils/`、`types/`） |
| 多模态方向 | 语音输入（Web Speech API）+ 图像证据（截屏/拍照/图片附件） |
| 演示视频 | 团队提供录制文件，AI 协助剪辑 |
| 团队与组别 | 待补充 |
| 在线演示 | 可选，待补充 |

## 任务清单

- [x] **P1 仓库就绪**：`.gitignore` 补齐；取消跟踪 `backend/.m2`、`frontend/.vite-once-cache`、`components.d.ts`、用户运行时知识库数据；跟踪文件由 3091 降至 1585。
- [x] **P2 SSE 流式对话 + AI 思考可视化**：ai-service `chat_stream` 产出 `thinking/token/done` 事件；前端 `stream.ts` 解析 SSE，对话面板渲染思考步骤与流式光标；Vite `/ai → :8001` 代理。
- [x] **T3 TypeScript 部分改造**：共享逻辑层 48 个模块迁移 `.js → .ts`；新增 `tsconfig.json`（`allowJs + noEmit`）；`npm run typecheck` 接入质量检查；测试同步改为显式 `.ts` 导入（Node ≥22.18）。
- [x] **T4 多模态**：
  - 语音输入：`domain/chat/speechInput.ts`（Web Speech API，渐进增强，不支持自动隐藏；识别文本仅入输入框，不上传音频）。
  - 图像证据：普通会话中图片本地暂存，随流式消息仅将**文件名**传给 ai-service（`ChatRequest.images`）；AI 思考过程新增"图像证据解析"阶段；图片内容不上传。文本/日志附件仍走私有附件会话，不参与模型分析。
- [x] **T5 性能（构建分包）**：`manualChunks` 收敛至 `vite.shared.mjs` 共享；zrender 从 echarts 拆出，`vendor-echarts` 510 kB → 346 kB；Three.js 保持懒加载 chunk。
- [x] **T6 技术文档 PDF**：`docs/competition/technical-document.pdf`（由 `technical-document.html` 经 `scripts/export-technical-pdf.mjs` 导出，可重复生成）。
- [ ] **T7 演示视频**：等待团队提供录制文件（阻塞项，需人工）。
- [ ] **T8 在线演示**：可选，待补充（阻塞项，需人工决策）。
- [ ] **T9 推送 GitHub**：由团队手动执行（阻塞项，凭据自持）。
- [ ] **团队与组别信息**：待补充（阻塞项，需人工填写）。

## 质量验证（每次改动后执行）

```powershell
cd frontend
npm test            # node --test test/**/*.test.mjs（当前 458 项）
npm run typecheck   # tsc --noEmit
npm run build       # 用户层构建
npm run build:admin # 管理员层构建
```

ai-service（Python）改动后执行语法检查：

```powershell
cd ai-service
python -m py_compile app/schemas/chat.py app/services/chat.py
```

## 演示动线（多模态 + 可信 AI）

1. 启动后端（8080）与 ai-service（8001），`cd frontend && npm run dev`。
2. 进入 Agent 对话：点击麦克风语音描述故障（如"MySQL 连接数打满"）。
3. 点击"截取屏幕"添加图像证据，发送后观察 AI 思考过程：图像证据解析 → 知识检索 → 证据验证 → Agent 规划 → 风险判定 → 生成回答。
4. 展示引用证据与可信度评分；切换到附件会话演示"私有保存、不分析"的隐私边界。
