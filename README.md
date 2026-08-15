# DeepSeek 建议回复

一个将聊天内容交给 DeepSeek，并生成可直接发送的候选回复的 iOS 快捷指令。

[下载最新快捷指令](https://github.com/aaronfang/ai-response/releases/latest/download/DeepSeek%20%E5%BB%BA%E8%AE%AE%E5%9B%9E%E5%A4%8D.shortcut)

本项目参考了 [Avivbens/ios-shortcuts 的 AI Response](https://github.com/Avivbens/ios-shortcuts/tree/master/packages/ai-response) 的交互思路，但直接调用 DeepSeek API，不依赖 ChatGPT App，也不需要截图识别。

1. 在聊天应用中选中一段文字；
2. 从系统共享菜单运行 **DeepSeek 建议回复**；
3. DeepSeek 生成 5 条候选回复；
4. 选择其中一条，快捷指令会复制回复并自动打开微信。

选中文字比截图更快，也能减少无关内容上传。

## 功能

- 从共享菜单接收选中的聊天文字；
- 未收到输入时自动读取剪贴板；
- 仍无内容时允许手动粘贴；
- 默认使用自然语气，避免每次运行都弹出语气选择；
- 使用 DeepSeek JSON 输出生成结构化候选项；
- 选择后直接复制，并自动打开微信，不请求通知权限。

## 最新版本

当前首个公开版本为 **v0.1.0**，发布时间为 **2026-08-15**。

- Release 页面：[v0.1.0](https://github.com/aaronfang/ai-response/releases/tag/v0.1.0)
- 下载资产：`DeepSeek 建议回复.shortcut`
- 构建产物不包含真实 API Key

## 运行要求

- iOS/iPadOS 17 或更高版本，建议使用较新的系统版本；
- 一个可用的 DeepSeek API Key；
- 网络连接；
- 构建源码时需要 macOS 和 [Cherri](https://github.com/electrikmilk/cherri)。

## 安装

### 从 Release 安装（推荐）

1. 下载 [最新版本的快捷指令](https://github.com/aaronfang/ai-response/releases/latest/download/DeepSeek%20%E5%BB%BA%E8%AE%AE%E5%9B%9E%E5%A4%8D.shortcut)；
2. 在 iPhone 或 Mac 上打开文件并添加到“快捷指令”；
3. 如果导入界面没有出现 API Key 配置项，打开快捷指令编辑页面；
4. 找到最上方的空白“文本”动作，填写你的 DeepSeek API Key：

   ```text
   sk-你的DeepSeek密钥
   ```

5. 保存后即可使用。

API Key 只需要填写 `sk-...`，不要填写 `Bearer `。仓库和 Release 资产不会包含你的真实 Key。

### 方法一：本地构建

在 macOS 上安装 Cherri：

```bash
brew tap electrikmilk/cherri
brew install electrikmilk/cherri/cherri
```

构建并签名快捷指令：

```bash
./scripts/build.sh
```

构建完成后，双击：

```text
dist/DeepSeek 建议回复.shortcut
```

导入时，系统会询问 DeepSeek API Key。请直接填写：

```text
sk-你的DeepSeek密钥
```

填写后，可通过 iCloud 同步到 iPhone。

如果你之前已经导入过旧版本，请先删除旧的 **DeepSeek 建议回复**，再导入新构建的文件。快捷指令的导入配置只会在首次添加时显示。

> `shortcuts sign` 可能要求当前 Mac 已登录 iCloud，并启用快捷指令相关服务。

### 方法二：直接编辑源码

核心文件位于：

```text
src/DeepSeek 建议回复.cherri
```

可以修改：

- `SUGGESTION_COUNT`：默认 5；
- 系统提示词；
- `TONE` 默认值；
- `temperature` 和 `max_tokens`。

修改后重新运行 `./scripts/build.sh`。

当前请求会把 DeepSeek endpoint 和模型直接写入“获取 URL 内容”动作，避免旧版 Shortcuts 对 URL/模型魔法变量的兼容问题。

## iPhone 使用方式

1. 打开微信；
2. 长按并选择对方的聊天内容；
3. 点击 **共享**；
4. 选择 **DeepSeek 建议回复**；
5. 选择一条候选回复；
6. 快捷指令会自动复制回复并打开微信；
7. 在输入框中粘贴。

快捷指令现在默认使用“自然”语气，不再每次运行都弹出语气选择；生成完成后会自动打开微信。

快捷指令可以从共享菜单接收其他应用的文字，但生成完成后默认打开微信。如果你主要使用其他聊天应用，请修改源码最后的：

```text
openApp("com.tencent.xin")
```

将它替换成目标 App 的 Bundle Identifier，再重新构建。

如果共享菜单没有显示：

1. 滑到共享菜单底部，点击“编辑操作”；
2. 启用 **DeepSeek 建议回复**；
3. 确认快捷指令详情中已开启“在共享表单中显示”。

某些聊天应用不允许直接共享选中文字。这时可先复制文字，再直接运行快捷指令。

如果应用没有提供“共享”：

1. 在聊天中复制消息；
2. 将快捷指令添加到控制中心、轻点 iPhone 背面或操作按钮；
3. 在微信中直接触发快捷指令；
4. 快捷指令会自动读取剪贴板，不再要求再次粘贴聊天内容。

生成完成后，快捷指令会自动打开微信并把回复放进剪贴板，所以推荐流程是：

```text
复制消息 → 从控制中心/背面轻点/操作按钮触发 → 选择回复 → 微信中粘贴
```

如果使用共享菜单，则是：

```text
选中文字 → 共享 → DeepSeek 建议回复 → 选择回复 → 粘贴
```

快捷指令目前不能可靠地把文本直接注入微信当前输入框，因此最后仍需要一次粘贴。

## DeepSeek API

快捷指令调用：

```text
POST https://api.deepseek.com/chat/completions
Authorization: Bearer <DEEPSEEK_API_KEY>
Content-Type: application/json
```

默认模型为 `deepseek-v4-flash`，并使用 `response_format: {"type":"json_object"}` 获取可解析的候选回复数组。快捷指令同时关闭 thinking 模式，避免把推理过程混入回复内容。

## 排查“没有返回候选回复”

如果出现这个提示，请重新导入最新构建的快捷指令。新版会在 API 没有返回 `choices` 时显示服务器原始响应，而不是笼统地提示检查网络和 Key。

如果你使用旧版本时原始响应只有：

```text
completions
```

这不是 DeepSeek 返回的 API JSON，而是旧版快捷指令把请求 URL
`https://api.deepseek.com/chat/completions` 当成了结果文本。旧版使用了动态生成的请求头，导致“获取 URL 内容”动作没有可靠地保留响应体。新版已改为把 `Authorization`、`Accept` 和 `Content-Type` 直接写进“获取 URL 内容”动作。

请确认你导入的是最新生成的文件，并且快捷指令编辑页面中的“获取 URL 内容”动作满足：

- 方法：`POST`
- 请求体：`JSON`
- Headers 中有 `Authorization: Bearer sk-...`
- URL：`https://api.deepseek.com/chat/completions`

如果仍出现 `completions`，请把错误提示中的“响应类型”和“响应字段”一并提供；它们可以区分当前运行的是旧快捷指令，还是 URL 动作确实没有返回 JSON。

常见情况：

- `Authentication Fails`：Authorization 格式或 API Key 不正确；
- `Insufficient Balance`：API 平台余额不足；
- `model not found`：快捷指令版本过旧，仍在使用已经变更的模型名称；
- 返回 HTML、网关错误或空内容：网络代理、地区网络或 API 服务异常。

这里需要的是 DeepSeek API Platform 的 Key，不是 DeepSeek 聊天 App 的登录信息。填写时只填 `sk-...`，快捷指令会自动加上 `Bearer `。

## 隐私与安全

- 选中的聊天内容会发送给 DeepSeek API；
- 不要上传密码、验证码、身份证号、银行卡信息、公司机密等敏感内容；
- AI 回复可能不准确或不合适，发送前必须人工确认；
- API Key 会保存在快捷指令配置中。请不要将含真实 Key 的 `.shortcut` 文件公开发布；
- 仓库默认忽略 `dist/`，避免误提交本机构建产物。

## 开发检查

只检查源码能否编译，不生成仓库内产物：

```bash
./scripts/check.sh
```

构建并生成可导入、可分享的快捷指令：

```bash
./scripts/build.sh
```

`dist/` 是本地构建目录，已加入 `.gitignore`。Release 上传的 `.shortcut` 文件由构建脚本生成。

## 项目结构

```text
.
├── src/
│   └── DeepSeek 建议回复.cherri
├── scripts/
│   ├── build.sh
│   └── check.sh
├── .gitignore
├── LICENSE
└── README.md
```

## License

MIT
