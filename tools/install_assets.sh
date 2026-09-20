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
# Poly Haven metadata/installer marker.
# Actual material selection is kept explicit so we do not silently download
# large 8K files onto a phone. The project can request the required resolution.
# ---------------------------------------------------------------------------
POLY_MARKER="$VENDOR/polyhaven/README.md"
if [ ! -f "$POLY_MARKER" ]; then
  cat > "$POLY_MARKER" <<'EOF'
# SAVIA / Poly Haven

Canonical source: https://polyhaven.com/
Forest Floor: https://polyhaven.com/a/forest_floor
License: CC0

SAVIA will use selected Poly Haven materials at an explicit resolution.
Large 8K source files are not downloaded automatically to mobile devices.
EOF
fi

echo
echo "Asset installation finished."
echo "Installed model files: $(find "$QUAT_DIR" -type f \( -name "*.gltf" -o -name "*.glb" \) | wc -l)"
echo "Installed texture files: $(find "$QUAT_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | wc -l)"
echo "Nature assets: $QUAT_DIR"
echo
echo "Next: open SAVIA in Godot and import the project assets."
