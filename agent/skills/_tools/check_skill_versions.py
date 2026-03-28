#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from typing import Iterable


SEMVER_RE = re.compile(r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$")


class SkillVersionError(RuntimeError):
    pass


@dataclass(frozen=True)
class Skill:
    name: str
    dir_path: str
    skill_md_path: str


def _run_git(args: list[str]) -> str:
    proc = subprocess.run(
        ["git", *args],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )
    if proc.returncode != 0:
        raise SkillVersionError(
            f"git {' '.join(args)} failed (exit {proc.returncode}): {proc.stderr.strip()}"
        )
    return proc.stdout


def _read_file_at_ref(ref: str, path: str) -> str | None:
    if ref.upper() in {"WORKTREE", "WORKING_TREE"}:
        try:
            with open(path, "r", encoding="utf-8") as f:
                return f.read()
        except FileNotFoundError:
            return None

    proc = subprocess.run(
        ["git", "show", f"{ref}:{path}"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )
    if proc.returncode != 0:
        # File may not exist at ref (e.g. new skill added in the PR).
        return None
    return proc.stdout


def _iter_skills(skills_dir: str) -> Iterable[Skill]:
    for entry in sorted(os.listdir(skills_dir)):
        if entry.startswith(".") or entry.startswith("_"):
            continue
        dir_path = os.path.join(skills_dir, entry)
        if not os.path.isdir(dir_path):
            continue
        skill_md_path = os.path.join(dir_path, "SKILL.md")
        if not os.path.isfile(skill_md_path):
            continue
        yield Skill(name=entry, dir_path=dir_path, skill_md_path=skill_md_path)


def _extract_front_matter(text: str) -> str:
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        raise SkillVersionError("missing YAML front matter starting '---'")
    try:
        end_idx = next(i for i in range(1, len(lines)) if lines[i].strip() == "---")
    except StopIteration as exc:
        raise SkillVersionError("missing YAML front matter closing '---'") from exc
    return "\n".join(lines[1:end_idx]) + "\n"


def _extract_version_from_skill_md(text: str) -> str:
    fm = _extract_front_matter(text)
    for line in fm.splitlines():
        if line.strip().startswith("version:"):
            _, value = line.split(":", 1)
            version = value.strip().strip('"').strip("'")
            if not version:
                raise SkillVersionError("version is empty")
            return version
    raise SkillVersionError("missing 'version:' in YAML front matter")


def _parse_semver(version: str) -> tuple[int, int, int]:
    m = SEMVER_RE.match(version)
    if not m:
        raise SkillVersionError(
            f"invalid version '{version}': expected MAJOR.MINOR.PATCH (e.g. 0.1.0)"
        )
    return (int(m.group(1)), int(m.group(2)), int(m.group(3)))


def _ref_exists(ref: str) -> bool:
    """Check if a git ref/commit exists in the repository."""
    proc = subprocess.run(
        ["git", "cat-file", "-t", ref],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )
    return proc.returncode == 0


def _changed_skills(skills_dir: str, base: str, head: str) -> set[str] | None:
    """Return changed skills, or None if base ref doesn't exist (e.g., after force push)."""
    # Check if base ref exists (may not exist after force push)
    if not _ref_exists(base):
        print(f"warning: base ref {base} not found, skipping change detection", file=sys.stderr)
        return None

    if head.upper() in {"WORKTREE", "WORKING_TREE"}:
        diff = _run_git(["diff", "--name-only", base, "--", skills_dir])
    else:
        diff = _run_git(["diff", "--name-only", f"{base}..{head}", "--", skills_dir])
    skills: set[str] = set()
    prefix = skills_dir.rstrip("/") + "/"
    for raw in diff.splitlines():
        path = raw.strip().replace("\\", "/")
        if not path.startswith(prefix):
            continue
        rest = path[len(prefix) :]
        parts = rest.split("/", 1)
        if len(parts) < 2:
            continue
        skill_name = parts[0]
        if skill_name.startswith("_") or skill_name.startswith("."):
            continue
        skill_md = os.path.join(skills_dir, skill_name, "SKILL.md")
        if os.path.isfile(skill_md):
            skills.add(skill_name)
    return skills


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Validate that each skill has a semver 'version:' in SKILL.md front matter, "
            "and require a version bump whenever any file under a skill directory changes."
        )
    )
    parser.add_argument("--skills-dir", default="agent/skills")
    parser.add_argument("--base", required=True, help="git ref/sha for base")
    parser.add_argument("--head", required=True, help="git ref/sha for head")
    args = parser.parse_args()

    skills_dir = args.skills_dir.rstrip("/")
    if not os.path.isdir(skills_dir):
        print(f"error: skills dir not found: {skills_dir}", file=sys.stderr)
        return 2

    skills = list(_iter_skills(skills_dir))
    if not skills:
        print(f"error: no skills found under {skills_dir}", file=sys.stderr)
        return 2

    errors: list[str] = []

    # Always validate versions exist and are semver at head.
    for skill in skills:
        head_text = _read_file_at_ref(args.head, skill.skill_md_path)
        if head_text is None:
            errors.append(
                f"{skill.name}: {skill.skill_md_path} missing at head ref {args.head}"
            )
            continue
        try:
            version = _extract_version_from_skill_md(head_text)
            _parse_semver(version)
        except SkillVersionError as exc:
            errors.append(f"{skill.name}: invalid/missing version at head: {exc}")

    changed = _changed_skills(skills_dir, args.base, args.head)
    if changed is None:
        # Base ref doesn't exist (e.g., after force push). Only validate version format.
        if errors:
            print("Skill version check failed:\n", file=sys.stderr)
            for err in errors:
                print(f"- {err}", file=sys.stderr)
            return 1
        print("warning: skipped version bump check (base ref not available)", file=sys.stderr)
        return 0

    if changed:
        for skill_name in sorted(changed):
            skill_md_path = os.path.join(skills_dir, skill_name, "SKILL.md")
            base_text = _read_file_at_ref(args.base, skill_md_path)
            head_text = _read_file_at_ref(args.head, skill_md_path)
            if head_text is None:
                errors.append(f"{skill_name}: SKILL.md missing at head")
                continue
            if base_text is None:
                # New skill added. Version existence/format already validated above.
                continue
            try:
                head_version = _extract_version_from_skill_md(head_text)
                head_tuple = _parse_semver(head_version)
                try:
                    base_version = _extract_version_from_skill_md(base_text)
                    base_tuple = _parse_semver(base_version)
                except SkillVersionError:
                    # Base ref may predate versioning migration; don't enforce bump in that case.
                    continue
                if head_tuple <= base_tuple:
                    errors.append(
                        f"{skill_name}: changed but version not bumped "
                        f"({base_version} -> {head_version})"
                    )
            except SkillVersionError as exc:
                errors.append(f"{skill_name}: version check failed: {exc}")

    if errors:
        print("Skill version check failed:\n", file=sys.stderr)
        for err in errors:
            print(f"- {err}", file=sys.stderr)
        if changed:
            print(
                "\nTip: when you touch any file under agent/skills/<skill>/, bump "
                "the 'version:' field in that skill's SKILL.md.",
                file=sys.stderr,
            )
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
