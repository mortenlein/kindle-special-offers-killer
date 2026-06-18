#!/usr/bin/env bash
#
# install.sh - stage the kindle-deads mod onto a jailbroken Kindle that already
# has the linkss screensaver hack installed.
#
# Usage:
#   ./install.sh <KINDLE_DRIVE_ROOT> <IMAGE_FILE>
#
# Examples:
#   ./install.sh /g ./examples/thewave.png        # Windows: Kindle is drive G:
#   ./install.sh /Volumes/Kindle my-photo.png     # macOS
#   ./install.sh /media/$USER/Kindle my-photo.png # Linux
#
# It converts your image to a 600x800 grayscale GIF, copies the boot worker
# into linkss/bin, wires the boot hook into linkss/bin/linkss, and stages the
# GIF. After it finishes: eject the Kindle and reboot it once.
set -eu

self_dir=$(cd "$(dirname "$0")" && pwd)

die() { echo "ERROR: $*" >&2; exit 1; }

[ $# -eq 2 ] || die "Usage: $0 <KINDLE_DRIVE_ROOT> <IMAGE_FILE>"
root=$1
img=$2

[ -d "$root/linkss/bin" ] || die "$root/linkss/bin not found.
Is the Kindle mounted at '$root', jailbroken, and does it have the linkss
screensaver hack installed? See the README for prerequisites."
[ -f "$img" ] || die "image not found: $img"

deads="$root/linkss/deads"
mkdir -p "$deads"
out="$deads/screensaver.gif"

echo ">> Converting '$img' -> 600x800 GIF"
if command -v magick >/dev/null 2>&1; then
    magick "$img" -resize 600x800 -background white -gravity center -extent 600x800 -colorspace Gray "$out"
elif command -v convert >/dev/null 2>&1; then
    convert "$img" -resize 600x800 -background white -gravity center -extent 600x800 -colorspace Gray "$out"
elif command -v powershell.exe >/dev/null 2>&1; then
    ps1="$self_dir/tools/png2kindlegif.ps1"
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$ps1" 2>/dev/null || echo "$ps1")" \
        -In "$(cygpath -w "$img" 2>/dev/null || echo "$img")" \
        -Out "$(cygpath -w "$out" 2>/dev/null || echo "$out")"
else
    die "need ImageMagick (magick/convert) or Windows PowerShell to build the GIF"
fi
[ -f "$out" ] || die "GIF was not created at $out"
echo "   wrote $out"

echo ">> Installing boot worker"
cp "$self_dir/linkss/bin/kindle-deads.sh" "$root/linkss/bin/kindle-deads.sh"

echo ">> Wiring boot hook into linkss"
linkss="$root/linkss/bin/linkss"
[ -f "$linkss" ] || die "$linkss not found (linkss hack not installed?)"
if grep -q 'kindle-deads.sh' "$linkss"; then
    echo "   hook already present"
else
    cp "$linkss" "$linkss.orig-preDeads" 2>/dev/null || true
    printf '\n# === kindle-special-offers-killer: replace ad images ===\n[ -f /mnt/us/linkss/bin/kindle-deads.sh ] && sh /mnt/us/linkss/bin/kindle-deads.sh\n' >> "$linkss"
    echo "   hook added (original saved as linkss.orig-preDeads)"
fi

cat <<EOF

Done staging to: $root

Next, on the Kindle itself:
  1. Safely eject the drive and unplug it.
  2. Menu > Settings > Menu > Restart.
  3. Let it boot, then press power to sleep it -> your image should appear.

Keep Wi-Fi OFF and never accept an Amazon software update: an OTA re-locks the
jailbreak and the ads come back. Check /mnt/us/deads.log (= ${root}/deads.log)
if anything looks off.
EOF
