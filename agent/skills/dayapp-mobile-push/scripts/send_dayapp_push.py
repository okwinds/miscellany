#!/usr/bin/env python3
import argparse
import json
import re
import sys
from datetime import datetime, time
from pathlib import Path
from urllib.parse import quote, urlencode
from urllib.request import urlopen


def strip_sensitive(text: str) -> str:
    """移除常见敏感片段，避免把密钥等信息发到通知中。"""
    text = re.sub(r"(?i)(token|password|cookie|secret)\s*[:=]\s*\S+", "[REDACTED]", text)
    text = re.sub(r"https?://[^\s]+", "[LINK]", text)
    return text


def truncate_by_limit(text: str, max_zh: int, max_en: int) -> str:
    """按中英文上限截断消息文本。"""
    text = text.strip()
    if not text:
        return text
    if any("\u4e00" <= ch <= "\u9fff" for ch in text):
        return text[:max_zh]
    return text[:max_en]


def parse_hhmm(value: str) -> time:
    """解析 HH:MM 格式时间。"""
    try:
        hour_str, minute_str = value.split(":", 1)
        hour = int(hour_str)
        minute = int(minute_str)
        return time(hour=hour, minute=minute)
    except Exception as exc:
        raise ValueError(f"静音时间格式错误: {value}，请使用 HH:MM") from exc


def is_time_in_range(now: time, start: time, end: time) -> bool:
    """判断当前时间是否在静音窗口内，支持跨天窗口。"""
    if start == end:
        return False
    if start < end:
        return start <= now < end
    return now >= start or now < end


def load_config(config_path: Path) -> tuple[str, dict]:
    """读取配置文件并返回 deviceid 与静音配置。"""
    if not config_path.exists():
        raise ValueError(f"配置文件不存在: {config_path}")

    try:
        data = json.loads(config_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"配置文件不是合法 JSON: {exc}") from exc

    deviceid = str(data.get("deviceid", "")).strip()
    if not deviceid:
        raise ValueError(
            "deviceid 为空。请编辑 ~/.claude/skills/dayapp-mobile-push/config.json，"
            "写入 {\"deviceid\":\"你的值\"}。"
            "deviceid 获取方式：在 App Store 安装 Bark，打开 App 即可复制。"
        )

    quiet_hours = data.get("quiet_hours", {})
    if quiet_hours is None:
        quiet_hours = {}
    if not isinstance(quiet_hours, dict):
        raise ValueError("quiet_hours 必须是对象，例如 {\"start\":\"23:00\",\"end\":\"08:00\"}")

    return deviceid, quiet_hours


def in_quiet_hours(quiet_hours: dict) -> bool:
    """依据配置判断当前是否处于静音时段。"""
    start_raw = str(quiet_hours.get("start", "")).strip()
    end_raw = str(quiet_hours.get("end", "")).strip()
    if not start_raw or not end_raw:
        return False

    start = parse_hhmm(start_raw)
    end = parse_hhmm(end_raw)
    now = datetime.now().time()
    return is_time_in_range(now=now, start=start, end=end)


def build_url(deviceid: str, task_name: str, task_summary: str, quiet_mode: bool) -> str:
    """组装 Day.app 请求 URL；静音时移除 sound/level/volume。"""
    encoded_name = quote(task_name, safe="")
    encoded_summary = quote(task_summary, safe="")

    params = {
        "group": "codex",
        "isArchive": "1",
        "badge": "1",
    }

    if not quiet_mode:
        params.update({
            "sound": "alarm",
            "level": "critical",
            "volume": "5",
        })

    return (
        f"https://api.day.app/{deviceid}/Codex-{encoded_name}/{encoded_summary}"
        f"?{urlencode(params)}"
    )


def send_get(url: str) -> tuple[int, str]:
    """发送 GET 请求并返回状态码与响应文本。"""
    with urlopen(url, timeout=10) as resp:
        body = resp.read().decode("utf-8", errors="replace")
        return int(resp.status), body


def parse_args() -> argparse.Namespace:
    """解析命令行参数。"""
    parser = argparse.ArgumentParser(description="Send Day.app push by GET request")
    parser.add_argument("--task-name", required=True, help="任务名（将自动截断）")
    parser.add_argument("--task-summary", required=True, help="任务概要（将自动截断）")
    parser.add_argument(
        "--config",
        default=str(Path(__file__).resolve().parent.parent / "config.json"),
        help="配置文件路径，默认使用 skill 根目录 config.json",
    )
    parser.add_argument("--dry-run", action="store_true", help="仅打印 URL，不实际发送")
    return parser.parse_args()


def main() -> int:
    """脚本入口：读取配置、处理参数、触发请求。"""
    args = parse_args()
    config_path = Path(args.config).expanduser().resolve()

    try:
        deviceid, quiet_hours = load_config(config_path)
        quiet_mode = in_quiet_hours(quiet_hours)

        task_name = truncate_by_limit(strip_sensitive(args.task_name), max_zh=6, max_en=12)
        task_summary = truncate_by_limit(strip_sensitive(args.task_summary), max_zh=25, max_en=50)

        if not task_name:
            raise ValueError("task_name 为空，无法发送")
        if not task_summary:
            raise ValueError("task_summary 为空，无法发送")

        url = build_url(deviceid, task_name, task_summary, quiet_mode=quiet_mode)

        if args.dry_run:
            print(url)
            return 0

        status, body = send_get(url)
        print(f"status={status}")
        print(body)
        return 0 if 200 <= status < 300 else 1
    except Exception as exc:
        print(f"发送失败: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
