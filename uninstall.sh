#!/usr/bin/env bash
#
# uninstall.sh - remove the kindle-deads mod and restore Amazon's original
# Special Offers images.
#
# Usage:
#   ./uninstall.sh <KINDLE_DRIVE_ROOT>
#
# Because the ad images live on the Kindle's internal (root) filesystem, the
# actual restore happens ON the device: this drops a RESTORE marker that the
# boot worker acts on at the next reboot (it copies every *.orig back and then
# disables itself). After you've rebooted once, run this again with --finish to
# strip the boot hook and worker from the card.
set -eu

die() { echo "ERROR: $*" >&2; exit 1; }

[ $# -ge 1 ] || die "Usage: $0 <KINDLE_DRIVE_ROOT> [--finish]"
root=$1
mode=${2:-}

[ -d "$root/linkss" ] || die "$root/linkss not found - is the Kindle mounted at '$root'?"

if [ "$mode" = "--finish" ]; then
    linkss="$root/linkss/bin/linkss"
    if [ -f "$linkss" ]; then
        grep -v 'kindle-special-offers-killer' "$linkss" | grep -v 'kindle-deads.sh' > "$linkss.tmp" \
            && mv "$linkss.tmp" "$linkss"
        echo "Removed boot hook from linkss."
    fi
    rm -f "$root/linkss/bin/kindle-deads.sh"
    rm -rf "$root/linkss/deads"
    echo "Removed worker and staging folder. Uninstall complete."
    exit 0
fi

mkdir -p "$root/linkss/deads"
: > "$root/linkss/deads/RESTORE"
cat <<EOF
Staged a RESTORE marker.

Now on the Kindle:
  1. Safely eject and unplug.
  2. Menu > Settings > Menu > Restart  (the worker restores Amazon's originals
     and disables itself; see ${root}/deads.log).
  3. Plug back in and run:  ./uninstall.sh "$root" --finish

That last step strips the boot hook and removes the mod's files from the card.
EOF
