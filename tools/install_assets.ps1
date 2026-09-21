# SAVIA Asset Installer (PowerShell for Windows)
# Descarga e instala los assets necesarios para el juego

$ErrorActionPreference = "Stop"

# Rutas
$ROOT = Split-Path -Parent $PSScriptRoot
$ASSET_ROOT = Join-Path $ROOT "assets"
$VENDOR = Join-Path $ASSET_ROOT "vendor"
$CACHE = Join-Path $ROOT ".asset_cache"

Write-Host "SAVIA Asset Installer" -ForegroundColor Cyan
Write-Host "Project: $ROOT" -ForegroundColor Gray
Write-Host ""

# Crear directorios
@(
    (Join-Path $VENDOR "quaternius"),
    (Join-Path $VENDOR "polyhaven"),
    (Join-Path $ASSET_ROOT "nature"),
    (Join-Path $ASSET_ROOT "laboratory"),
    (Join-Path $ASSET_ROOT "fauna"),
    (Join-Path $ASSET_ROOT "materials"),
    (Join-Path $ASSET_ROOT "hdris"),
    $CACHE
) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
    }
}

# =========================================================================
# Quaternius Stylized Nature MegaKit — free Standard CC0 distribution
# =========================================================================
$quatVendor = Join-Path $VENDOR "quaternius"
$QUAT_DIR = Join-Path $quatVendor "stylized_nature_megakit"
$MIRROR_DIR = Join-Path $CACHE "FreeModels"

$quatInstalled = (Test-Path $QUAT_DIR) -and ((Get-ChildItem $QUAT_DIR -Filter "*.gltf" -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0)

if (-not $quatInstalled) {
    Write-Host "[1/2] Installing Quaternius Stylized Nature MegaKit..." -ForegroundColor Yellow
    
    if (-not (Test-Path (Join-Path $MIRROR_DIR ".git"))) {
        if (Test-Path $MIRROR_DIR) {
            Remove-Item $MIRROR_DIR -Recurse -Force
        }
        
        Write-Host "  Cloning GitHub mirror..." -ForegroundColor Gray
        git clone --depth 1 "https://github.com/agentkaerf/FreeModels.git" "$MIRROR_DIR"
    }
    
    Write-Host "  Copying Quaternius assets..." -ForegroundColor Gray
    
    # Note: Use -LiteralPath to avoid bracket interpretation
    $SRC = Join-Path $MIRROR_DIR "Stylized Nature MegaKit[Standard]"
    if (-not (Test-Path -LiteralPath $SRC)) {
        Write-Host "ERROR: Quaternius mirror layout changed; installation stopped." -ForegroundColor Red
        exit 1
    }
    
    Remove-Item $QUAT_DIR -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $QUAT_DIR -Force | Out-Null
    
    # Copy all items from source to destination
    Get-ChildItem -LiteralPath $SRC -Recurse | ForEach-Object {
        if ($_.PSIsContainer) {
            $RelPath = $_.FullName.Substring($SRC.Length + 1)
            $TargetDir = Join-Path $QUAT_DIR $RelPath
            New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
        } else {
            $RelPath = $_.FullName.Substring($SRC.Length + 1)
            $TargetFile = Join-Path $QUAT_DIR $RelPath
            $TargetDir = Split-Path $TargetFile
            New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
            Copy-Item -LiteralPath $_.FullName -Destination $TargetFile
        }
    }
    
    Write-Host "  [OK] Quaternius installed successfully" -ForegroundColor Green
} else {
    Write-Host "[1/2] Quaternius assets already installed." -ForegroundColor Green
}

# =========================================================================
# Poly Haven — Single Root (requires Python 3)
# =========================================================================
$polyVendor = Join-Path $VENDOR "polyhaven"
$POLY_DIR = Join-Path $polyVendor "single_root"
$POLY_GLTF = Join-Path $POLY_DIR "single_root_1k.gltf"

if (-not (Test-Path $POLY_GLTF)) {
    Write-Host "[2/2] Installing Poly Haven Single Root (1K)..." -ForegroundColor Yellow
    
    # Verificar Python (python3 o python)
    $pythonCmd = $null
    try {
        $pythonVersion = & python3 --version 2>&1
        $pythonCmd = "python3"
        Write-Host "  Using: $pythonVersion" -ForegroundColor Gray
    } catch {
        try {
            $pythonVersion = & python --version 2>&1
            $pythonCmd = "python"
            Write-Host "  Using: $pythonVersion" -ForegroundColor Gray
        } catch {
            Write-Host "ERROR: python or python3 is required." -ForegroundColor Red
            exit 1
        }
    }
    
    New-Item -ItemType Directory -Path $POLY_DIR -Force | Out-Null
    
    # Script Python inline para descargar desde la API de Poly Haven
    $pythonScript = @"
import json
import os
import pathlib
import urllib.request

asset_dir = pathlib.Path(r'$POLY_DIR')
api_url = 'https://api.polyhaven.com/files/single_root'
request = urllib.request.Request(
    api_url,
    headers={'User-Agent': 'SAVIA-AssetInstaller/1.0'}
)

print('  Fetching from Poly Haven API...')
with urllib.request.urlopen(request, timeout=30) as response:
    data = json.load(response)

gltf = data.get('gltf', {})
entry = gltf.get('1k') or gltf.get('2k') or next(iter(gltf.values()), None)
if not entry or not entry.get('gltf', {}).get('url'):
    raise SystemExit('Poly Haven API did not return a glTF bundle for single_root.')

files = [(pathlib.Path('single_root_1k.gltf'), entry['gltf']['url'])]
for relative, dependency in entry['gltf'].get('include', {}).items():
    files.append((pathlib.Path(relative), dependency['url']))

for relative_path, url in files:
    target = asset_dir / relative_path
    target.parent.mkdir(parents=True, exist_ok=True)
    print(f'  Downloading {relative_path}...')
    req = urllib.request.Request(
        url,
        headers={'User-Agent': 'SAVIA-AssetInstaller/1.0'}
    )
    with urllib.request.urlopen(req, timeout=120) as response:
        target.write_bytes(response.read())

print('  [OK] Poly Haven downloaded successfully')
"@

    Write-Host "  Downloading Poly Haven assets..." -ForegroundColor Gray
    $pythonScript | & $pythonCmd
    
} else {
    Write-Host "[2/2] Poly Haven Single Root already installed." -ForegroundColor Green
}

# Crear archivo README en Poly Haven
$polyReadme = Join-Path $polyVendor "README.md"
@"
# SAVIA / Poly Haven

Single Root: https://polyhaven.com/a/single_root
License: CC0
Attribution: Poly Haven (https://polyhaven.com)
"@ | Set-Content $polyReadme

Write-Host ""
Write-Host "Asset installation complete!" -ForegroundColor Green
Write-Host "You can now open the project in Godot 4.7" -ForegroundColor Cyan
