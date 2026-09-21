# SAVIA Orchestrator

The orchestrator is SAVIA infrastructure, not an AI agent.

Its job is to coordinate deterministic tools such as Blender, Godot and Git while keeping project state explicit and protecting existing work.

## Principles

- local-first
- free-first
- open-source-first where practical
- tools remain replaceable
- no dependency on Cline, Codex or another agent
- destructive operations are disabled by default
- Blender operations use a small allowlist instead of arbitrary Python
- Git state is checked before mutations

## Current adapters

- Blender: local TCP JSON-lines bridge on 127.0.0.1:9877
- Godot: command-line validation
- Git: status/diff/history
- GitHub: remote source of truth
- Ollama: optional local AI service; not required by the orchestrator

## Commands

From the repository root:

python tools/savia_orchestrator.py status

python tools/savia_orchestrator.py plan --operation scene.inspect

python tools/savia_orchestrator.py blender scene.inspect

The first Blender operation is read-only.

## Safety model

The orchestrator does not execute arbitrary Blender Python received over the network. The Blender bridge accepts named operations with validated parameters.

The first mutation operations are additive and collection-scoped. Global scene deletion, arbitrary code execution and unrestricted filesystem access are intentionally outside the protocol.
