# Changelog

本项目遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) 的结构。

## [0.1.0] - 2026-08-15

### Added

- 从 iOS 共享菜单接收选中的聊天文字；
- 没有共享输入时自动读取剪贴板；
- 没有剪贴板内容时允许手动输入；
- 调用 DeepSeek Chat Completions API；
- 使用 JSON Output 生成 5 条候选回复；
- 默认使用自然语气；
- 选择回复后自动复制到剪贴板；
- 复制完成后自动打开微信；
- API Key 配置、API 错误和原始响应诊断；
- Cherri 编译脚本和快捷指令结构检查脚本。

### Security

- 源码和 Release 资产不包含真实 DeepSeek API Key；
- `.gitignore` 忽略本地构建产物和系统文件。
