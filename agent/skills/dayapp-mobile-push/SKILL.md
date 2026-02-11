---
name: dayapp-mobile-push
version: 0.1.1
author: 肆〇柒/ForOhZen
description: Send a critical mobile push through Day.app (Bark) with one GET request. Use when a task finishes, fails, is blocked, or needs immediate alerting, and you should summarize task name and summary from current task context before sending.
---

# Dayapp Mobile Push

## Overview

用 Day.app 接口发送手机告警推送。调用时先从当前任务上下文提炼 `taskname` 与 `tasksummary`，再直接触发 GET 请求。

## Workflow

1. 从当前任务上下文提炼参数：
   - `taskname`：不超过 6 个中文字符（英文场景建议不超过 12 个字母）
   - `tasksummary`：不超过 25 个中文字符，或不超过 50 个英文字符
2. 读取 `config.json` 的 `deviceid`、`app_name` 与 `quiet_hours`。
3. 若 `deviceid` 为空，立即提示用户并停止：
   - 配置位置：`~/agent/skills/dayapp-mobile-push/config.json`
   - 配置方式：把 `deviceid` 写入 `{"deviceid":"你的值"}`
   - 获取方式：在 App Store 安装 `Bark`，打开 App 即可看到并复制 `deviceid`
4. 生成请求 URL：
   - 标题前缀不是写死 `Codex-`，而是 `{应用名}-{taskname}`
   - `group` 参数也不是写死值，而是与 `{应用名}` 保持一致
   - `app_name=auto` 时自动识别：Codex 环境用 `Codex-`，Claude Code 环境用 `Claude-`
   - 若当前时间在静音时段内：从 URL 参数里去掉 `sound`、`level`、`volume`
   - 若不在静音时段：保留 `sound=alarm&level=critical&volume=5`
5. 发送 GET 请求。

## Rules

- 只发送一次 GET 请求，不做重试风暴。
- 若 `config.json` 缺少 `deviceid`，先提示用户配置，再停止。
- `app_name` 默认 `auto`；也可以手动写死，例如 `Codex`、`Claude`。
- `quiet_hours` 为可选；未配置时按非静音处理。
- 发送前必须做长度约束；超长内容交给脚本自动截断。
- 不在消息中写入敏感信息（token、密码、cookie、内网地址等）。

## Config

编辑同目录下 `config.json`：

```json
{
  "deviceid": "YOUR_DEVICE_ID",
  "app_name": "auto",
  "quiet_hours": {
    "start": "23:00",
    "end": "08:00"
  }
}
```

说明：
- `app_name`
  - `auto`：自动识别当前应用（Codex / Claude）
  - 其他值：手动指定前缀（会规范化，例如 `Claude Code` -> `Claude`）
- `quiet_hours.start` / `quiet_hours.end` 使用 `HH:MM`（24 小时制）
- 支持跨天（如 `23:00` 到 `08:00`）
- 在静音窗口内会自动移除 `sound`、`level`、`volume`

## Command Reference

```bash
python3 scripts/send_dayapp_push.py --task-name "构建完成" --task-summary "CLI 构建与测试全部通过"
```

```bash
python3 scripts/send_dayapp_push.py --task-name "部署阻塞" --task-summary "生产发布被权限策略拦截" --dry-run
```
