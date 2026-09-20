# SAVIA — Asset Pipeline

SAVIA keeps external art separate from game code. Assets are installed locally into `assets/vendor/` and are not committed to the game repository.

## Primary nature source
- Quaternius — Stylized Nature MegaKit
- Official source: https://quaternius.com/packs/stylizednaturemegakit.html
- License: CC0
- Free Standard distribution: 68 models / 99 MB
- Godot-compatible glTF assets are available.

## Secondary material source
- Poly Haven — https://polyhaven.com/
- Forest Floor: https://polyhaven.com/a/forest_floor
- License: CC0

## Local structure

```
assets/
  vendor/
    quaternius/
      stylized_nature_megakit/
    polyhaven/
      forest_floor/
  nature/
  laboratory/
  fauna/
  materials/
  hdris/
```

The installer retrieves the free nature package through a sparse Git clone of a public CC0 mirror that contains Quaternius models. The official Quaternius page remains the canonical source and license reference.

## Install

From the SAVIA project root:

```bash
bash tools/install_assets.sh
```

The installer is repeatable: existing files are reused and the package is not copied into Git history.

## Design rule

Third-party assets are raw material. SAVIA's identity comes from composition, simulation, shaders, lighting, scale transitions and scientific visualization — not from simply placing an asset pack in a scene.
