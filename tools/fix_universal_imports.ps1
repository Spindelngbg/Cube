$root = "C:\Users\Simon\Cube\assets\models\characters\quaternius-universal"
$normalMaps = @(
    "T_Hair_1_Normal_png.png",
    "T_Hair_2_Normal.png",
    "T_Eye_Normal_png.png",
    "T_Superhero_Male_Normal.png",
    "T_Superhero_Female_Normal.png"
)
$roughnessMaps = @(
    "T_Superhero_Male_Roughness.png",
    "T_Superhero_Female_Roughness.png"
)

function Make-TextureImport {
    param(
        [string]$FileName,
        [bool]$IsNormal = $false,
        [int]$SizeLimit = 1024
    )
    $importPath = Join-Path $root "$FileName.import"
    if (-not (Test-Path (Join-Path $root $FileName))) { return }
    $normal = if ($IsNormal) { 1 } else { 0 }
    $content = @"
[remap]

importer="texture"
type="CompressedTexture2D"
uid=""
valid=false

[deps]

source_file="res://assets/models/characters/quaternius-universal/$FileName"

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=$normal
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=$SizeLimit
detect_3d/compress_to=1
"@
    Set-Content -Path $importPath -Value $content -Encoding UTF8
}

Get-ChildItem $root -Filter '*.png' | ForEach-Object {
    $name = $_.Name
    $isNormal = $normalMaps -contains $name
    $limit = if ($name -like 'T_Eye_*') { 256 } else { 1024 }
    Make-TextureImport -FileName $name -IsNormal $isNormal -SizeLimit $limit
}

foreach ($gltf in @('Superhero_Male_FullBody.gltf','Superhero_Female_FullBody.gltf')) {
    $importPath = Join-Path $root "$gltf.import"
    if (-not (Test-Path $importPath)) { continue }
    $text = Get-Content $importPath -Raw
    $text = $text -replace 'meshes/generate_lods=true','meshes/generate_lods=false'
    $text = $text -replace 'meshes/create_shadow_meshes=true','meshes/create_shadow_meshes=false'
    Set-Content -Path $importPath -Value $text -Encoding UTF8
}

Write-Output 'Universal character imports reset for lightweight import.'