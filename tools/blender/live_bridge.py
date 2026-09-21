"""
SAVIA Blender Live Bridge
-------------------------
Runs Blender as a live visualizer for the SAVIA procedural asset generator.

Design goals:
- One watcher only, even if this bridge is executed again.
- No rebuild loop after a failed build.
- A file save triggers exactly one rebuild.
- A second edit made while building is picked up after the current build.
- Blender remains a normal GUI application so the viewport can be watched.
"""

import bpy
import os
import traceback

BRIDGE_DIR = os.path.dirname(os.path.abspath(__file__))
SOURCE = os.path.join(BRIDGE_DIR, "savia_field_research_station_v01.py")
WATCH_INTERVAL = 0.5

# Keep watcher state in Blender's process-level namespace so re-running this
# script can cleanly replace an older watcher.
STATE = bpy.app.driver_namespace.setdefault("SAVIA_LIVE_STATE", {})
_running = False


def _source_mtime():
    try:
        return os.path.getmtime(SOURCE)
    except OSError:
        return None


def run_source():
    global _running

    if _running:
        return False

    mtime = _source_mtime()
    if mtime is None:
        print("[SAVIA LIVE] Source not found:", SOURCE)
        STATE["last_mtime"] = None
        STATE["last_status"] = "missing"
        return False

    # Mark this version as seen BEFORE executing it.
    # This is critical: if the build fails, the timer must not execute the same
    # broken source every 0.5 seconds forever.
    STATE["last_mtime"] = mtime
    STATE["last_status"] = "building"
    _running = True

    try:
        print("\n[SAVIA LIVE] ===============================")
        print("[SAVIA LIVE] Rebuilding from:", SOURCE)
        print("[SAVIA LIVE] Source mtime:", mtime)
        print("[SAVIA LIVE] ===============================")

        with open(SOURCE, "r", encoding="utf-8") as f:
            source_code = f.read()

        namespace = {
            "__name__": "__main__",
            "__file__": SOURCE,
        }

        exec(compile(source_code, SOURCE, "exec"), namespace, namespace)

        STATE["last_status"] = "ok"
        print("[SAVIA LIVE] Build finished.")

        # If the file was edited while the build was running, leave the newer
        # mtime untouched. The next timer tick will rebuild that newer version.
        current = _source_mtime()
        if current != mtime:
            print("[SAVIA LIVE] A newer source version was saved during build; it will be rebuilt next.")

        return True

    except Exception:
        STATE["last_status"] = "error"
        print("[SAVIA LIVE] BUILD ERROR")
        traceback.print_exc()
        print("[SAVIA LIVE] Waiting for the next file change; no error loop will be started.")
        return False

    finally:
        _running = False


def watch():
    mtime = _source_mtime()

    if mtime is None:
        if STATE.get("last_status") != "missing":
            print("[SAVIA LIVE] Waiting for source:", SOURCE)
        STATE["last_status"] = "missing"
        return WATCH_INTERVAL

    last = STATE.get("last_mtime")

    if last is None:
        run_source()
    elif mtime != last and not _running:
        run_source()

    return WATCH_INTERVAL


# Remove a previous watcher if this bridge script is executed again.
old_watch = bpy.app.driver_namespace.get("SAVIA_LIVE_WATCH")
if old_watch is not None:
    try:
        if bpy.app.timers.is_registered(old_watch):
            bpy.app.timers.unregister(old_watch)
            print("[SAVIA LIVE] Previous watcher removed.")
    except Exception:
        pass

STATE["last_mtime"] = None
STATE["last_status"] = "starting"

run_source()

bpy.app.driver_namespace["SAVIA_LIVE_WATCH"] = watch
bpy.app.timers.register(watch, first_interval=WATCH_INTERVAL, persistent=True)

print("[SAVIA LIVE] Watching:", SOURCE)
print("[SAVIA LIVE] Status: LIVE")
print("[SAVIA LIVE] Save the generator file to trigger a rebuild.")
