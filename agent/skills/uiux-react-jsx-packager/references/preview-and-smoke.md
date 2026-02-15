# Preview & Smoke（通用排障与最小回归）

本文件是 `uiux-react-jsx-packager` 的“运行时门禁 + 排障手册”。
目标：把“单文件 `.jsx` 产物”在拿走后依然**可跑、不白屏、导航可用**，并减少常见误判。

## 1) 最小 Smoke Checklist（手工版）

用任意 runner（推荐 `scripts/preview_single_jsx_vite.sh`）打开页面后，按顺序做：

1. **首屏**
   - 页面不是纯白
   - 有可识别的主 UI（标题/侧边栏/主内容区至少出现其一）
2. **导航**
   - 侧边栏（或顶部导航）依次点击主要模块/页面（至少点一轮）
   - 每次点击后，主内容区必须发生变化（标题/列表/按钮等）
3. **Hash（如果你实现了 hash 同步）**
   - 手动改 `#/xxx` 能直达对应模块
4. **二级交互（抽样）**
   - 打开一个详情/弹窗/下拉菜单
   - 关闭并返回，状态不崩

判定：
- 任何一步出现“纯白且没有错误信息”，都算失败（需要补 ErrorBoundary 或修初始化异常）。

## 2) 预览常见误判：端口自动切换

Vite（以及很多 dev server）会在端口被占用时自动换端口，典型输出：

- `Port 5188 is in use, trying another one...`
- `Local: http://127.0.0.1:5190/`

**规则：必须以终端输出的 `Local:` URL 为准**。不要死盯一个固定端口。

### 端口占用排查（按系统）

macOS / Linux：

- 查占用：`lsof -nP -iTCP:5188 -sTCP:LISTEN || true`
- 结束进程：`kill <PID>`

Windows（PowerShell）：

- 查占用：`netstat -ano | findstr :5188`
- 结束进程：`taskkill /PID <PID> /F`

## 3) Runner 常见坑：React.lazy import 失败导致“白屏”

很多预览脚本/runner 会这样加载组件：

- `const Prototype = React.lazy(() => import(path))`

如果 `import()` 失败（路径不允许、跨目录限制、编译器报错），常见表现是：
- Suspense 一直 Loading
- 或页面白屏

建议：
- runner 一定要有 **ErrorBoundary**（渲染错误至少显示错误摘要，而不是纯白）
- 预览时优先用“静态 import `/@fs/...`”加载（更直观），必要时再切换到 lazy 模式复现 runner 行为

## 4) 缓存/串台：你看到的可能是“旧服务”

常见现象：
- 你重新跑了预览脚本，但浏览器仍打开旧标签页 / 旧端口
- 或者临时目录复用导致加载旧工程

建议：
- 预览脚本默认使用**唯一临时目录**（避免复用）
- 任何时候都以终端输出的 `Local:` URL 为准
- 需要时清理：删除预览脚本创建的 `/tmp/single-jsx-preview-*` 目录

