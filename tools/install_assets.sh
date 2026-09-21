#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSET_ROOT="$ROOT/assets"
VENDOR="$ASSET_ROOT/vendor"
CACHE="$ROOT/.asset_cache"

mkdir -p "$VENDOR/quaternius" "$VENDOR/polyhaven" "$ASSET_ROOT/nature" "$ASSET_ROOT/laboratory" "$ASSET_ROOT/fauna" "$ASSET_ROOT/materials" "$ASSET_ROOT/hdris" "$CACHE"

git config --global --add safe.directory "$ROOT" 2>/dev/null || true

echo "SAVIA Asset Installer"
echo "Project: $ROOT"
echo

# ---------------------------------------------------------------------------
# Quaternius Stylized Nature MegaKit — free Standard CC0 distribution.
# The public mirror is used only as an automated transport mechanism.
# Canonical source/license: https://quaternius.com/packs/stylizednaturemegakit.html
# ---------------------------------------------------------------------------
QUAT_DIR="$VENDOR/quaternius/stylized_nature_megakit"
MIRROR_DIR="$CACHE/FreeModels"

if [ ! -d "$QUAT_DIR" ] || [ -z "$(find "$QUAT_DIR" -type f -name "*.gltf" -print -quit 2>/dev/null)" ] || [ -z "$(find "$QUAT_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) -print -quit 2>/dev/null)" ]; then
  echo "[1/2] Installing Quaternius Stylized Nature MegaKit..."

  if [ ! -d "$MIRROR_DIR/.git" ]; then
    rm -rf "$MIRROR_DIR"
    git clone --depth 1 --filter=blob:none --sparse \
      https://github.com/agentkaerf/FreeModels.git "$MIRROR_DIR"
  fi

  git config --global --add safe.directory "$MIRROR_DIR" 2>/dev/null || true
  git -C "$MIRROR_DIR" config --local --add safe.directory "$MIRROR_DIR" 2>/dev/null || true
  git -C "$MIRROR_DIR" sparse-checkout set --skip-checks 'Stylized Nature MegaKit[Standard]'

  SRC="$MIRROR_DIR/Stylized Nature MegaKit[Standard]"
  if [ ! -d "$SRC" ]; then
    echo "ERROR: Quaternius mirror layout changed; asset installation stopped."
    exit 1
  fi

  rm -rf "$QUAT_DIR"
  mkdir -p "$QUAT_DIR"

  # Copy the complete pack, not only glTF. The glTF scenes can reference
  # textures/material resources next to the models; copying only glTF makes
  # Godot fail to instantiate the scenes and silently fall back to primitives.
  cp -R "$SRC/." "$QUAT_DIR/"

  cp "$ROOT/assets/ASSET_PIPELINE.md" "$QUAT_DIR/../ASSET_SOURCE_NOTES.md" 2>/dev/null || true
else
  echo "[1/2] Quaternius assets already installed."
fi

# ---------------------------------------------------------------------------
# Poly Haven — Single Root
# Official public API, 1K glTF bundle. The API returns the model plus all
# referenced dependencies, so the asset is installed as a complete scene.
# Canonical asset: https://polyhaven.com/a/single_root
# License: CC0. API access requires a clear Poly Haven attribution in products.
# ---------------------------------------------------------------------------
POLY_DIR="$VENDOR/polyhaven/single_root"

if [ ! -f "$POLY_DIR/single_root_1k.gltf" ]; then
  echo "[2/2] Installing Poly Haven Single Root (1K)..."
  if ! command -v python3 >/dev/null 2>&1; then
    echo "ERROR: python3 is required for the Poly Haven asset installer."
    echo "Install it once in Termux with: pkg install python -y"
    exit 1
  fi

  mkdir -p "$POLY_DIR"
  SAVIA_POLY_DIR="$POLY_DIR" python3 - <<'PY'
import json
import os
import pathlib
import urllib.request

asset_dir = pathlib.Path(os.environ["SAVIA_POLY_DIR"])
api_url = "https://api.polyhaven.com/files/single_root"
request = urllib.request.Request(
    api_url,
    headers={"User-Agent": "SAVIA-AssetInstaller/1.0"}
)

with urllib.request.urlopen(request, timeout=30) as response:
    data = json.load(response)

gltf = data.get("gltf", {})
entry = gltf.get("1k") or gltf.get("2k") or next(iter(gltf.values()), None)
if not entry or not entry.get("gltf", {}).get("url"):
    raise SystemExit("Poly Haven API did not return a glTF bundle for single_root.")

files = [(pathlib.Path("single_root_1k.gltf"), entry["gltf"]["url"])]
for relative, dependency in entry["gltf"].get("include", {}).items():
    files.append((pathlib.Path(relative), dependency["url"]))

for relative_path, url in files:
    target = asset_dir / relative_path
    target.parent.mkdir(parents=True, exist_ok=True)
    print(f"  downloading {relative_path}")
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "SAVIA-AssetInstaller/1.0"}
    )
    with urllib.request.urlopen(req, timeout=120) as response:
        target.write_bytes(response.read())
PY
else
  echo "[2/2] Poly Haven Single Root already installed."
fi

# Keep a provenance note inside the project without downloading heavy 8K maps.
POLY_MARKER="$VENDOR/polyhaven/README.md"
cat > "$POLY_MARKER" <<'EOF'
# SAVIA / Poly Haven

Single Root: https://polyhaven.com/a/single_root
API: https://api.polyhaven.com/
License: CC0

The installer downloads the 1K glTF bundle and its referenced files automatically.
Poly Haven requests clear attribution when the live public API is used in a product.
EOF

