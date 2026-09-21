#!/usr/bin/env python3
"""
SAVIA Orchestrator v0.1

Deterministic local coordinator for SAVIA tools.
No LLM, agent, MCP client or paid service is required.

Examples:
  python tools/savia_orchestrator.py status
  python tools/savia_orchestrator.py plan --operation scene.inspect
  python tools/savia_orchestrator.py blender scene.inspect
  python tools/savia_orchestrator.py godot.validate
"""

from __future__ import annotations

import argparse
import json
import socket
import subprocess
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / ".savia" / "tool_registry.json"
STATE = ROOT / ".savia" / "state.json"


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def run_command(args: list[str], cwd: Path = ROOT, timeout: int = 30) -> tuple[int, str]:
    try:
        result = subprocess.run(
            args,
            cwd=cwd,
            text=True,
            capture_output=True,
            timeout=timeout,
        )
        output = (result.stdout + result.stderr).strip()
        return result.returncode, output
    except FileNotFoundError:
        return 127, f"Command not found: {args[0]}"
    except subprocess.TimeoutExpired:
        return 124, f"Command timed out: {' '.join(args)}"


def git_status() -> dict[str, Any]:
    code, output = run_command(["git", "status", "--short", "--branch"])
    return {"ok": code == 0, "code": code, "output": output}


def check_project() -> dict[str, Any]:
    required = [
        ROOT / "project.godot",
        ROOT / "main.tscn",
        ROOT / "scripts" / "main.gd",
        ROOT / "scripts" / "ecological_elements.gd",
        ROOT / "scripts" / "blender_asset_loader.gd",
    ]
    return {
        "ok": all(p.exists() for p in required),
        "files": {str(p.relative_to(ROOT)): p.exists() for p in required},
    }


def blender_request(operation: str, params: dict[str, Any] | None = None) -> dict[str, Any]:
    request = {
        "id": "savia-orchestrator-1",
        "op": operation,
        "params": params or {},
    }
    host = "127.0.0.1"
    port = 9877

    with socket.create_connection((host, port), timeout=5) as sock:
        sock.sendall((json.dumps(request) + "\n").encode("utf-8"))
        buffer = b""
        while b"\n" not in buffer:
            chunk = sock.recv(65536)
            if not chunk:
                raise ConnectionError("Blender bridge closed the connection")
            buffer += chunk

    return json.loads(buffer.split(b"\n", 1)[0].decode("utf-8"))


def command_status(_: argparse.Namespace) -> int:
    registry = load_json(REGISTRY)
    state = load_json(STATE)

    print("SAVIA ORCHESTRATOR")
    print("==================")
    print(f"Project: {registry['project']}")
    print(f"Architecture: {state['architecture_version']}")
    print(f"Active feature: {state['active_feature']}")
    print()

    print("PROJECT")
    print(json.dumps(check_project(), indent=2, ensure_ascii=False))
    print()

    print("GIT")
    print(json.dumps(git_status(), indent=2, ensure_ascii=False))
    print()

    print("TOOLS")
    for name, tool in registry["tools"].items():
        marker = "optional" if tool.get("optional") else "required"
        print(f"- {name}: {marker}, local={tool.get('local')}, free={tool.get('free')}")

    return 0


def command_plan(args: argparse.Namespace) -> int:
    allowed = {
        "scene.inspect",
        "collection.ensure",
        "mesh.add_cube",
        "mesh.add_uv_sphere",
        "scene.save",
    }
    if args.operation not in allowed:
        print(f"Operation not allowed: {args.operation}", file=sys.stderr)
        print("Allowed:", ", ".join(sorted(allowed)), file=sys.stderr)
        return 2

    print(json.dumps({
        "operation": args.operation,
        "mode": "dry-run",
        "destructive": False,
        "project": str(ROOT),
    }, indent=2))
    return 0


def command_blender(args: argparse.Namespace) -> int:
    try:
        response = blender_request(args.operation)
    except Exception as exc:
        print(f"Blender bridge unavailable: {exc}", file=sys.stderr)
        return 1

    print(json.dumps(response, indent=2, ensure_ascii=False))
    return 0 if response.get("ok", False) else 1


def command_godot_validate(_: argparse.Namespace) -> int:
    code, output = run_command(
        [
            "godot",
            "--headless",
            "--path",
            str(ROOT),
            "--script",
            "res://tools/godot/validate_project.gd",
        ],
        timeout=60,
    )
    print(output)
    return code


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="SAVIA deterministic orchestrator")
    sub = parser.add_subparsers(dest="command", required=True)

    status = sub.add_parser("status", help="Inspect project, Git and tool registry")
    status.set_defaults(func=command_status)

    plan = sub.add_parser("plan", help="Validate a safe operation without executing it")
    plan.add_argument("--operation", required=True)
    plan.set_defaults(func=command_plan)

    blender = sub.add_parser("blender", help="Call the local Blender bridge")
    blender.add_argument("operation")
    blender.set_defaults(func=command_blender)

    godot = sub.add_parser("godot.validate", help="Validate the Godot project headlessly")
    godot.set_defaults(func=command_godot_validate)

    return parser


if __name__ == "__main__":
    args = build_parser().parse_args()
    raise SystemExit(args.func(args))
