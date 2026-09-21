bl_info = {
    "name": "SAVIA Direct Bridge",
    "author": "SAVIA",
    "version": (0, 1, 0),
    "blender": (5, 2, 0),
    "location": "View3D > N > SAVIA",
    "description": "Local deterministic bridge for SAVIA orchestration",
    "category": "Development",
}

import bpy
import json
import queue
import socket
import threading
from typing import Any


HOST = "127.0.0.1"
PORT = 9877

_server_socket = None
_server_thread = None
_stop_event = threading.Event()
_command_queue: queue.Queue[tuple[socket.socket, dict[str, Any]]] = queue.Queue()


def _send(conn: socket.socket, payload: dict[str, Any]) -> None:
    try:
        conn.sendall((json.dumps(payload, ensure_ascii=False) + "\n").encode("utf-8"))
    except OSError:
        pass


def _scene_summary() -> dict[str, Any]:
    collections = []
    for collection in bpy.data.collections:
        collections.append({
            "name": collection.name,
            "objects": len(collection.objects),
        })

    objects = []
    for obj in bpy.context.scene.objects:
        objects.append({
            "name": obj.name,
            "type": obj.type,
            "collection": obj.users_collection[0].name if obj.users_collection else None,
            "location": [round(v, 4) for v in obj.location],
        })

    cameras = [
        {"name": obj.name}
        for obj in bpy.context.scene.objects
        if obj.type == "CAMERA"
    ]
    lights = [
        {"name": obj.name, "type": obj.data.type}
        for obj in bpy.context.scene.objects
        if obj.type == "LIGHT"
    ]

    return {
        "scene": bpy.context.scene.name,
        "file": bpy.data.filepath,
        "blender_version": list(bpy.app.version),
        "collections": collections,
        "objects": objects,
        "cameras": cameras,
        "lights": lights,
    }


def _ensure_collection(name: str) -> dict[str, Any]:
    if not name or len(name) > 80:
        raise ValueError("Invalid collection name")

    collection = bpy.data.collections.get(name)
    created = False
    if collection is None:
        collection = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(collection)
        created = True

    return {"name": collection.name, "created": created}


def _add_cube(params: dict[str, Any]) -> dict[str, Any]:
    collection_name = params.get("collection", "SAVIA_TEMP")
    name = params.get("name", "SAVIA_Cube")
    if bpy.data.objects.get(name):
        raise ValueError(f"Object already exists: {name}")

    collection = bpy.data.collections.get(collection_name)
    if collection is None:
        raise ValueError(f"Collection does not exist: {collection_name}")

    size = float(params.get("size", 1.0))
    location = params.get("location", [0.0, 0.0, 0.0])

    if size <= 0 or size > 1000:
        raise ValueError("Invalid cube size")
    if len(location) != 3:
        raise ValueError("location must contain three numbers")

    bpy.ops.mesh.primitive_cube_add(size=size, location=location)
    obj = bpy.context.object
    obj.name = name

    for old in list(obj.users_collection):
        old.objects.unlink(obj)
    collection.objects.link(obj)

    return {"name": obj.name, "type": obj.type}


def _add_uv_sphere(params: dict[str, Any]) -> dict[str, Any]:
    collection_name = params.get("collection", "SAVIA_TEMP")
    name = params.get("name", "SAVIA_Sphere")
    if bpy.data.objects.get(name):
        raise ValueError(f"Object already exists: {name}")

    collection = bpy.data.collections.get(collection_name)
    if collection is None:
        raise ValueError(f"Collection does not exist: {collection_name}")

    radius = float(params.get("radius", 0.5))
    location = params.get("location", [0.0, 0.0, 0.0])

    if radius <= 0 or radius > 500:
        raise ValueError("Invalid sphere radius")
    if len(location) != 3:
        raise ValueError("location must contain three numbers")

    bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, location=location)
    obj = bpy.context.object
    obj.name = name

    for old in list(obj.users_collection):
        old.objects.unlink(obj)
    collection.objects.link(obj)

    return {"name": obj.name, "type": obj.type}


def _save() -> dict[str, Any]:
    if not bpy.data.filepath:
        raise ValueError("Blend file has no path; save it manually once first")
    bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
    return {"saved": True, "file": bpy.data.filepath}


def _dispatch(request: dict[str, Any]) -> dict[str, Any]:
    op = request.get("op")
    params = request.get("params") or {}

    if op == "ping":
        return {"ok": True, "service": "savia_blender_bridge", "port": PORT}

    if op == "scene.inspect":
        return {"ok": True, "result": _scene_summary()}

    if op == "collection.ensure":
        return {"ok": True, "result": _ensure_collection(params["name"])}

    if op == "mesh.add_cube":
        return {"ok": True, "result": _add_cube(params)}

    if op == "mesh.add_uv_sphere":
        return {"ok": True, "result": _add_uv_sphere(params)}

    if op == "scene.save":
        return {"ok": True, "result": _save()}

    raise ValueError(f"Operation not allowed: {op}")


def _client_loop(conn: socket.socket) -> None:
    try:
        with conn:
            buffer = b""
            while not _stop_event.is_set():
                chunk = conn.recv(65536)
                if not chunk:
                    break
                buffer += chunk
                while b"\n" in buffer:
                    raw, buffer = buffer.split(b"\n", 1)
                    if not raw.strip():
                        continue
                    try:
                        request = json.loads(raw.decode("utf-8"))
                        _command_queue.put((conn, request))
                    except Exception as exc:
                        _send(conn, {
                            "ok": False,
                            "error": f"Invalid request: {exc}",
                        })
    except OSError:
        pass


def _server_loop() -> None:
    global _server_socket

    try:
        server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server.bind((HOST, PORT))
        server.listen(8)
        server.settimeout(0.5)
        _server_socket = server

        print(f"SAVIA Bridge listening on {HOST}:{PORT}")

        while not _stop_event.is_set():
            try:
                conn, _ = server.accept()
            except socket.timeout:
                continue
            except OSError:
                break

            thread = threading.Thread(
                target=_client_loop,
                args=(conn,),
                daemon=True,
            )
            thread.start()
    except OSError as exc:
        print(f"SAVIA Bridge failed to start: {exc}")


def _process_queue() -> float:
    while True:
        try:
            conn, request = _command_queue.get_nowait()
        except queue.Empty:
            break

        try:
            result = _dispatch(request)
        except Exception as exc:
            result = {
                "ok": False,
                "error": str(exc),
                "operation": request.get("op"),
            }

        _send(conn, result)

    return 0.1


def start_bridge() -> None:
    global _server_thread

    if _server_thread and _server_thread.is_alive():
        return

    _stop_event.clear()
    _server_thread = threading.Thread(target=_server_loop, daemon=True)
    _server_thread.start()

    if not bpy.app.timers.is_registered(_process_queue):
        bpy.app.timers.register(_process_queue, first_interval=0.1)


def stop_bridge() -> None:
    _stop_event.set()

    global _server_socket
    if _server_socket:
        try:
            _server_socket.close()
        except OSError:
            pass
        _server_socket = None


class SAVIA_OT_start_bridge(bpy.types.Operator):
    bl_idname = "savia.start_bridge"
    bl_label = "Start SAVIA Bridge"

    def execute(self, context):
        start_bridge()
        self.report({"INFO"}, f"SAVIA Bridge: {HOST}:{PORT}")
        return {"FINISHED"}


class SAVIA_OT_stop_bridge(bpy.types.Operator):
    bl_idname = "savia.stop_bridge"
    bl_label = "Stop SAVIA Bridge"

    def execute(self, context):
        stop_bridge()
        self.report({"INFO"}, "SAVIA Bridge stopped")
        return {"FINISHED"}


class SAVIA_PT_bridge(bpy.types.Panel):
    bl_label = "SAVIA Bridge"
    bl_idname = "SAVIA_PT_bridge"
    bl_space_type = "VIEW_3D"
    bl_region_type = "UI"
    bl_category = "SAVIA"

    def draw(self, context):
        layout = self.layout
        layout.label(text=f"Local: {HOST}:{PORT}")
        layout.operator("savia.start_bridge", icon="PLAY")
        layout.operator("savia.stop_bridge", icon="PAUSE")
        layout.label(text="No arbitrary Python execution")


CLASSES = (
    SAVIA_OT_start_bridge,
    SAVIA_OT_stop_bridge,
    SAVIA_PT_bridge,
)


def register():
    for cls in CLASSES:
        bpy.utils.register_class(cls)


def unregister():
    stop_bridge()
    if bpy.app.timers.is_registered(_process_queue):
        bpy.app.timers.unregister(_process_queue)
    for cls in reversed(CLASSES):
        bpy.utils.unregister_class(cls)


if __name__ == "__main__":
    register()
