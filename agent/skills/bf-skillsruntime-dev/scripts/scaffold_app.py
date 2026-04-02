#!/usr/bin/env python3
"""
Generate a Skills Runtime SDK business app skeleton.

Usage:
    python3 scaffold_app.py <app_name> --out <dir> [--with-skills] [--dry-run] [--force]

Generates:
    <dir>/
      run.py
      config/
        runtime.yaml
      skills/
        <app_name>/
          SKILL.md
      tests/
        test_<app_name>_smoke.py
"""
from __future__ import annotations

import argparse
from pathlib import Path
from textwrap import dedent

RUN_PY = dedent(
    '''\
    """
    {app_name} — Skills Runtime SDK business app.

    Prerequisites:
        - Ensure `skills-runtime-sdk` is available in the current Python environment.
        - Recommended during local development:
          pip install -e <local_repo>/packages/skills-runtime-sdk-python

    Usage:
        python3 {run_path} --workspace-root /tmp/{app_name} [--mode offline|real] [--config config/runtime.yaml]
    """
    from __future__ import annotations

    import argparse
    from pathlib import Path

    from skills_runtime.agent import Agent
    from skills_runtime import AgentBuilder
    from skills_runtime.config.loader import AgentSdkLlmConfig
    from skills_runtime.llm.chat_sse import ChatStreamEvent
    from skills_runtime.llm.fake import FakeChatBackend, FakeChatCall
    from skills_runtime.llm.openai_chat import OpenAIChatCompletionsBackend
    from skills_runtime.state.wal_protocol import InMemoryWal


    def parse_args() -> argparse.Namespace:
        p = argparse.ArgumentParser(description="{app_name}")
        p.add_argument("--workspace-root", type=str, required=True)
        p.add_argument("--mode", choices=["offline", "real"], default="offline")
        p.add_argument("--config", type=str, default=None)
        return p.parse_args()


    def build_backend(mode: str):
        if mode == "offline":
            return FakeChatBackend(calls=[
                FakeChatCall(events=[
                    ChatStreamEvent(type="text_delta", text="EXAMPLE_OK: {app_name} completed."),
                    ChatStreamEvent(type="completed", finish_reason="stop"),
                ])
            ])
        llm_cfg = AgentSdkLlmConfig(
            base_url="https://api.openai.com/v1",
            api_key_env="OPENAI_API_KEY",
            timeout_sec=60,
        )
        return OpenAIChatCompletionsBackend(llm_cfg)


    def build_agent(*, ws: Path, mode: str) -> Agent:
        backend = build_backend(mode)
        return (
            AgentBuilder()
            .workspace_root(ws)
            .backend(backend)
            .wal_backend(InMemoryWal())
            .build()
        )


    def main() -> None:
        args = parse_args()
        ws = Path(args.workspace_root).resolve()
        ws.mkdir(parents=True, exist_ok=True)

        agent = build_agent(ws=ws, mode=args.mode)
        result = agent.run("请完成 {app_name} 的核心任务。")

        print(f"status: {{result.status}}")
        print(f"output: {{result.final_output}}")
        print(f"wal:    {{result.wal_locator}}")


    if __name__ == "__main__":
        main()
'''
)

OVERLAY_YAML = dedent(
    '''\
    # {app_name} overlay — keep secrets out of YAML.
    run:
      max_steps: 20
    safety:
      mode: "ask"
      approval_timeout_ms: 60000
    sandbox:
      default_policy: none
    skills:
      strictness:
        unknown_mention: error
        duplicate_name: error
        mention_format: strict
      references:
        enabled: false
      actions:
        enabled: false
    # Uncomment and adjust when you are ready to enable business skills:
    #   spaces:
    #     - id: app-space
    #       namespace: "biz:{app_name}"
    #       sources: [app-fs]
    #       enabled: true
    #   sources:
    #     - id: app-fs
    #       type: filesystem
    #       options:
    #         root: "./skills"
'''
)

SKILL_MD = dedent(
    '''\
    ---
    name: {app_name}
    description: "{app_name} business skill — replace this with the concrete business capability."
    ---

    # {app_name}

    建议补齐：
    - 什么时候触发
    - 输入 / 输出契约
    - 必须走哪些 builtin tools
    - 哪些 references/actions 需要启用
    - 最小回归与证据要求
'''
)

TEST_PY = dedent(
    '''\
    """Offline smoke test for {app_name}."""
    import subprocess
    import sys
    from pathlib import Path

    APP_ROOT = Path(__file__).resolve().parents[1]


    def test_{app_name_under}_offline_smoke(tmp_path):
        """Run {app_name} in offline mode and check EXAMPLE_OK marker."""
        run_py = APP_ROOT / "run.py"
        result = subprocess.run(
            [sys.executable, str(run_py), "--workspace-root", str(tmp_path), "--mode", "offline"],
            capture_output=True,
            text=True,
            timeout=30,
        )
        assert result.returncode == 0, f"stderr: {{result.stderr}}"
        assert "EXAMPLE_OK:" in result.stdout, f"stdout: {{result.stdout}}"
'''
)


def write_file(path: Path, content: str, *, force: bool, dry_run: bool) -> None:
    if path.exists() and not force:
        print(f"  SKIP (exists): {path}")
        return
    if dry_run:
        print(f"  WOULD WRITE: {path}")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    print(f"  WROTE: {path}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Scaffold a Skills Runtime SDK business app.")
    parser.add_argument("app_name", help="App name (kebab-case recommended)")
    parser.add_argument("--out", required=True, help="Output directory")
    parser.add_argument("--with-skills", action="store_true", help="Generate skills/ directory")
    parser.add_argument("--dry-run", action="store_true", help="Preview without writing")
    parser.add_argument("--force", action="store_true", help="Overwrite existing files")
    args = parser.parse_args()

    out = Path(args.out).resolve()
    name = str(args.app_name).strip()
    name_under = name.replace("-", "_")
    run_path = f"{name}/run.py"

    ctx = {"app_name": name, "app_name_under": name_under, "run_path": run_path}

    print(f"Scaffolding '{name}' into {out}/")

    write_file(out / "run.py", RUN_PY.format(**ctx), force=args.force, dry_run=args.dry_run)
    write_file(out / "config" / "runtime.yaml", OVERLAY_YAML.format(**ctx), force=args.force, dry_run=args.dry_run)
    write_file(out / "tests" / f"test_{name_under}_smoke.py", TEST_PY.format(**ctx), force=args.force, dry_run=args.dry_run)

    if args.with_skills:
        write_file(out / "skills" / name / "SKILL.md", SKILL_MD.format(**ctx), force=args.force, dry_run=args.dry_run)

    print("Done.")


if __name__ == "__main__":
    main()
