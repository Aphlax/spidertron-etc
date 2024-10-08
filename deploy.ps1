# Before submitting & deploying, make sure you have:
# - updated the mod version in info.json and
# - updated the changelog in description.txt.
# Deploy this mod with ".\deploy.ps1 -v 1.0.X".
# Navigate to https://mods.factorio.com/mod/spidertron-etc/downloads, then click Edit Releases (after logging in).
# Upload the new release, then head to Information and copy the description.txt (and updated images) into the mod.

param($v)

if (-not ($v -match "^[0-9]\.[0-9]\.[0-9]+$")) {
  throw "Version must be in the format -v 1.0.0"
}

$directories = @(
  @("/", @("control.lua", "data.lua", "info.json", "thumbnail.png")),
  @("/entities/", "*.lua"),
  @("/graphics/", "*.png"),
  @("/graphics/entity/", "*.png"),
  @("/graphics/icon/", "*.png"),
  @("/graphics/technology/", "*.png"),
  @("/graphics/informatron/", "*.png"),
  @("/locale/en/", "base.cfg"),
  @("/scripts/", "*.lua"),
  @("/scripts/lib/", "*.lua")
)
$targetDir = join-path -path $pwd -childPath "bin/spidertron-etc_$v"

if (test-path -path $targetDir) {
  throw "version $v already exists!"
}

$info = get-content "./info.json" | convertFrom-json
if ($info.version -ne $v) {
  throw "Version in info.json ($($info.version)) must match $v."
}

forEach($dir in $directories) {
  $from = join-path -path $pwd -childPath "$($dir[0])*"
  $to = join-path -path $targetDir -childPath $dir[0]
  $files = get-childItem -path $from -include $dir[1] -file
  mkdir $to > $null
  cp $files $to
}

&"C:\Program Files\7-Zip\7z" a -tzip "$targetDir.zip" $targetDir
