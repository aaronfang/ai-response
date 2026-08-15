#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CHECK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/deepseek-reply-check.XXXXXX")"
CHECK_SOURCE="$CHECK_DIR/DeepSeek 建议回复.cherri"
CHECK_OUTPUT="$CHECK_DIR/DeepSeek 建议回复_unsigned.shortcut"

trap 'rm -rf "$CHECK_DIR"' EXIT

if ! command -v cherri >/dev/null 2>&1; then
    echo "未找到 Cherri，无法执行编译检查。"
    exit 1
fi

cp "$ROOT_DIR/src/DeepSeek 建议回复.cherri" "$CHECK_SOURCE"

cherri "$CHECK_SOURCE" \
    --skip-sign \
    --derive-uuids \
    --no-ansi

test -s "$CHECK_OUTPUT"

python3 - "$CHECK_OUTPUT" "$ROOT_DIR/src/DeepSeek 建议回复.cherri" <<'PY'
import plistlib
import sys

shortcut_path = sys.argv[1]
source_path = sys.argv[2]

with open(shortcut_path, "rb") as shortcut_file:
    shortcut = plistlib.load(shortcut_file)

questions = shortcut.get("WFWorkflowImportQuestions", [])
if len(questions) != 1:
    raise SystemExit(
        f"导入问题检查失败：预期 1 个 API Key 配置项，实际为 {len(questions)} 个。"
    )

question = questions[0]
if "ActionIndex" not in question:
    raise SystemExit(
        "导入问题检查失败：缺少 ActionIndex，iOS 导入时不会显示 API Key 配置。"
    )

action_index = question["ActionIndex"]
actions = shortcut.get("WFWorkflowActions", [])

if not isinstance(action_index, int) or action_index >= len(actions):
    raise SystemExit(f"导入问题检查失败：无效 ActionIndex {action_index!r}。")

target_action = actions[action_index]
parameters = target_action.get("WFWorkflowActionParameters", {})

if target_action.get("WFWorkflowActionIdentifier") != "is.workflow.actions.gettext":
    raise SystemExit("导入问题检查失败：API Key 没有绑定到文本动作。")

if parameters.get("CustomOutputName") != "apiKey":
    raise SystemExit(
        "导入问题检查失败：API Key 配置项绑定到了错误的动作 "
        f"{parameters.get('CustomOutputName')!r}。"
    )

if question.get("ParameterKey") != "WFTextActionText":
    raise SystemExit("导入问题检查失败：配置项没有绑定到文本内容参数。")

source_text = open(
    source_path,
    encoding="utf-8",
).read()
if "DeepSeek 没有返回标准 JSON 响应" not in source_text:
    raise SystemExit("错误处理检查失败：没有保留 API 原始响应诊断信息。")
if "响应类型：" not in source_text or "响应字段：" not in source_text:
    raise SystemExit("错误处理检查失败：没有保留响应类型和字段诊断信息。")
if "const responseDebug = \"{response}\"" not in source_text:
    raise SystemExit("错误处理检查失败：没有保留原始响应对象诊断信息。")
if "dynamicJSONRequest" in source_text:
    raise SystemExit("请求检查失败：不应使用自定义动态请求动作。")
if "const clipboard = getClipboard()" not in source_text:
    raise SystemExit("输入检查失败：没有显式读取剪贴板作为回退输入。")
if 'const TONE = "自然"' not in source_text:
    raise SystemExit("交互检查失败：没有使用默认自然语气减少一次选择。")
if 'openApp("com.tencent.xin")' not in source_text:
    raise SystemExit("交互检查失败：没有在复制回复后自动返回微信。")
if "showNotification(" in source_text:
    raise SystemExit("交互检查失败：不应请求系统通知权限。")

request_actions = [
    action
    for action in actions
    if action.get("WFWorkflowActionIdentifier") == "is.workflow.actions.downloadurl"
]
if len(request_actions) != 1:
    raise SystemExit(
        f"请求检查失败：预期 1 个 Get Contents of URL 动作，实际为 {len(request_actions)} 个。"
    )

request_parameters = request_actions[0].get("WFWorkflowActionParameters", {})
request_url = request_parameters.get("WFURL", {})
if isinstance(request_url, str):
    request_url_value = request_url
else:
    request_url_value = request_url.get("Value")

if request_url_value != "https://api.deepseek.com/chat/completions":
    raise SystemExit("请求检查失败：URL 必须是 DeepSeek Chat Completions 端点。")

body_items = (
    request_parameters.get("WFJSONValues", {})
    .get("Value", {})
    .get("WFDictionaryFieldValueItems", [])
)
body_keys = [
    item.get("WFKey", {}).get("Value", {}).get("string")
    for item in body_items
]
if "model" not in body_keys or "messages" not in body_keys:
    raise SystemExit("请求检查失败：JSON 请求体缺少 model 或 messages。")

request_parameters = request_actions[0].get("WFWorkflowActionParameters", {})
headers = request_parameters.get("WFHTTPHeaders", {})
header_items = (
    headers.get("Value", {}).get("WFDictionaryFieldValueItems", [])
    if isinstance(headers, dict)
    else []
)
header_keys = [
    item.get("WFKey", {}).get("Value", {}).get("string")
    for item in header_items
]

if "Authorization" not in header_keys:
    raise SystemExit("请求检查失败：Authorization 没有写入 Get Contents of URL 的请求头。")

if headers.get("WFSerializationType") == "WFTextTokenAttachment":
    raise SystemExit(
        "请求检查失败：请求头不能是另一个动作的输出，必须直接写入 Get Contents of URL。"
    )

wechat_actions = [
    action
    for action in actions
    if action.get("WFWorkflowActionIdentifier") == "is.workflow.actions.openapp"
]
if not any(
    action.get("WFWorkflowActionParameters", {}).get("WFAppIdentifier")
    == "com.tencent.xin"
    for action in wechat_actions
):
    raise SystemExit("交互检查失败：没有在完成后打开微信。")
PY

echo "检查通过：Cherri 源码可成功编译。"
