"""
SAVIA Blender Live Bridge
-------------------------
Keeps Blender open as a live visualizer of the procedural SAVIA asset script.

When savia_field_research_station_v01.py changes on disk, Blender detects the
new modification time, clears/rebuilds the station, updates the viewport and
saves/exports the result again.

Run this file from Blender's command line:
    blender.exe --python tools/blender/live_bridge.py

The bridge intentionally runs with Blender's normal GUI so the user can watch
the build happen in the viewport.
"""

import bpy
import os
import time
import traceback

BRIDGE_DIR = os.path.dirname(os.path.abspath(__file__))
SOURCE = os.path.join(BRIDGE_DIR, "savia_field_research_station_v01.py")

_last_mtime = None
_running = False


def run_source():
    global _last_mtime, _running

    if _running:
        return

    _running = True
    try:
        if not os.path.exists(SOURCE):
            print("[SAVIA LIVE] Source not found:", SOURCE)
            return

        print("\n[SAVIA LIVE] ===============================")
        print("[SAVIA LIVE] Rebuilding from:", SOURCE)
        print("[SAVIA LIVE] ===============================")

        with open(SOURCE, "r", encoding="utf-8") as f:
            source_code = f.read()

        # Execute in a fresh namespace so old globals from previous builds
        # cannot accidentally leak into the next build.
        namespace = {
            "__name__": "__main__",
            "__file__": SOURCE,
        }
        exec(compile(source_code, SOURCE, "exec"), namespace, namespace)

        _last_mtime = os.path.getmtime(SOURCE)
        print("[SAVIA LIVE] Build finished.")

    except Exception:
        print("[SAVIA LIVE] BUILD ERROR")
        traceback.print_exc()

    finally:
        _running = False


def watch():
    global _last_mtime

    try:
        mtime = os.path.getmtime(SOURCE)
    except OSError:
        return 1.0

    if _last_mtime is None:
        _last_mtime = mtime
        run_source()
    elif mtime != _last_mtime:
        run_source()

    return 0.5


# First build immediately, then watch the file.
run_source()

if not bpy.app.timers.is_registered(watch):
    bpy.app.timers.register(watch, first_interval=0.5, persistent=True)

print("[SAVIA LIVE] Watching:", SOURCE)
print("[SAVIA LIVE] Edit the Python file and save it; Blender will rebuild automatically.")
