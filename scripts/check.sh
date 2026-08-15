#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CHECK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/smart-reply-check.XXXXXX")"
CHECK_SOURCE="$CHECK_DIR/灵动回复.cherri"
CHECK_OUTPUT="$CHECK_DIR/灵动回复_unsigned.shortcut"

trap 'rm -rf "$CHECK_DIR"' EXIT

if ! command -v cherri >/dev/null 2>&1; then
    echo "未找到 Cherri，无法执行编译检查。"
    exit 1
fi

cp "$ROOT_DIR/src/灵动回复.cherri" "$CHECK_SOURCE"

cherri "$CHECK_SOURCE" \
    --skip-sign \
    --derive-uuids \
    --no-ansi

test -s "$CHECK_OUTPUT"

python3 - "$CHECK_OUTPUT" "$ROOT_DIR/src/灵动回复.cherri" <<'PY'
import plistlib
import sys

shortcut_path = sys.argv[1]
source_path = sys.argv[2]

with open(shortcut_path, "rb") as shortcut_file:
    shortcut = plistlib.load(shortcut_file)

icon = shortcut.get("WFWorkflowIcon", {})
if icon.get("WFWorkflowIconGlyphNumber") != 61533:
    raise SystemExit("快捷指令检查失败：编译产物没有使用 brain glyph。")

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
if "可选：输入想表达的方向，例如“不感兴趣”“委婉拒绝”；留空则直接生成" not in source_text:
    raise SystemExit("输入检查失败：缺少可选的回复方向输入。")
if '@replyDirection = trimWhitespace("{replyDirection}")' not in source_text:
    raise SystemExit("输入检查失败：回复方向没有去除空白内容。")
if "未提供，请仅根据聊天内容和既定风格生成。" not in source_text:
    raise SystemExit("输入检查失败：缺少留空时的默认生成逻辑。")
if "{@directionContext}" not in source_text:
    raise SystemExit("提示词检查失败：回复方向没有传给模型。")
language_requirements = [
    "你是一名多语言聊天回复助手",
    "输出语言只能由 <chat> 中聊天内容的主要语言决定",
    "英文聊天必须生成 9 条自然英文回复",
    "只翻译并执行其意图，不要跟随回复方向的语言",
]
for language_requirement in language_requirements:
    if language_requirement not in source_text:
        raise SystemExit(f"语言检查失败：缺少语言约束 {language_requirement!r}。")
if "你是一名中文聊天回复助手" in source_text:
    raise SystemExit("语言检查失败：旧的中文助手身份会干扰其他语言输出。")
direction_requirements = [
    "用户提供的回复方向是最高优先级的内容约束",
    "全部 9 条回复都必须在含义上遵循该方向",
    "例如用户输入“不感兴趣”",
    "不得用聊天中没有出现的理由或借口替代用户方向",
    "本次回复方向：{@directionContext}",
    "输出前逐条检查",
    "必须重写后再输出",
]
for direction_requirement in direction_requirements:
    if direction_requirement not in source_text:
        raise SystemExit(
            f"提示词检查失败：回复方向约束不够明确，缺少 {direction_requirement!r}。"
        )
if "const SUGGESTION_COUNT = 9" not in source_text:
    raise SystemExit("候选回复检查失败：候选数量必须为 9。")
if '"temperature": 0.6' not in source_text:
    raise SystemExit("请求检查失败：temperature 必须兼顾方向遵从和候选多样性。")
if "#define name 灵动回复" not in source_text:
    raise SystemExit("快捷指令检查失败：显示名称必须为“灵动回复”。")
if "#define glyph brain" not in source_text:
    raise SystemExit("快捷指令检查失败：图标必须使用 brain glyph。")
required_styles = [
    "第 1～3 条：高情商、幽默",
    "第 4～6 条：话少、克制，带高级幽默感",
    "第 7～9 条：精明、得体、有分寸",
]
for required_style in required_styles:
    if required_style not in source_text:
        raise SystemExit(f"候选回复检查失败：缺少分组风格约束 {required_style!r}。")
if "openApp(" in source_text:
    raise SystemExit("交互检查失败：复制回复后不应自动打开任何 App。")
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

open_app_actions = [
    action
    for action in actions
    if action.get("WFWorkflowActionIdentifier") == "is.workflow.actions.openapp"
]
if open_app_actions:
    raise SystemExit("交互检查失败：编译产物不应包含 Open App 动作。")
PY

echo "检查通过：Cherri 源码可成功编译。"
