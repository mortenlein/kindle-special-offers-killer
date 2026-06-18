#!/bin/sh
#
# kindle-deads.sh - Replace Amazon "Special Offers" ad images on a jailbroken
# Kindle (4/5 Non-Touch) with your own screensaver, and blank the home-screen
# ad banner.
#
# Runs as root at boot, invoked by a one-line hook appended to the linkss
# screensaver hack's boot script (/mnt/us/linkss/bin/linkss).
#
# Why this exists: on ad-supported Kindles the sleep image is NOT served from
# the normal screensaver path that the linkss hack replaces. It comes from the
# "Special Offers" ad subsystem, which draws GIFs from
#   /opt/amazon/screen_saver/adunits/<res>/screensvr.gif
#   /opt/amazon/screen_saver/adunits/<res>/screensaver-unregistered.gif   (placeholder)
#   /opt/amazon/screen_saver/adunits/<res>/banner.gif / banner-unregistered.gif
# This script swaps those for your image (sleep) and a blank (banner).
#
#   * Idempotent + self-healing (re-applies if the system ever restores an ad).
#   * Reversible: each modified file is backed up next to it as *.orig. To undo,
#     create an empty file named RESTORE in /mnt/us/linkss/deads and reboot once.
#   * Logs to /mnt/us/deads.log.
#
# Part of: https://github.com/mortenlein/kindle-special-offers-killer  (MIT)

LOG=/mnt/us/deads.log
DEADS=/mnt/us/linkss/deads
IMG=$DEADS/screensaver.gif
SS_ROOT=/opt/amazon/screen_saver/adunits

exec >> "$LOG" 2>&1

remount_rw() { mntroot rw 2>&1 || mount -o remount,rw / 2>&1; }
remount_ro() { sync; mntroot ro 2>&1 || mount -o remount,ro / 2>&1; }

# Permanently disabled (set after a completed RESTORE)?
[ -f "$DEADS/DISABLED" ] && exit 0

# --- Uninstall path: restore Amazon's originals, then disable ourselves -------
if [ -f "$DEADS/RESTORE" ]; then
    echo "===== deads RESTORE: $(date 2>/dev/null) ====="
    remount_rw
    for f in $(find "$SS_ROOT" -name '*.orig' 2>/dev/null); do
        orig="${f%.orig}"
        cp -f "$f" "$orig" && echo "restored $orig"
    done
    remount_ro
    rm -f "$DEADS/RESTORE"
    : > "$DEADS/DISABLED"
    echo "restore complete; mod disabled (delete $DEADS/DISABLED to re-enable)."
    exit 0
fi

[ -f "$IMG" ] || { echo "$(date): custom screensaver GIF missing at $IMG"; exit 0; }
[ -d "$SS_ROOT" ] || { echo "$(date): $SS_ROOT not found (not a Special Offers device?)"; exit 0; }

# --- Fast path: is there anything to do? -------------------------------------
need=0
for d in "$SS_ROOT"/*/ ; do
    [ -d "$d" ] || continue
    for s in screensvr.gif screensaver-unregistered.gif ; do
        [ -f "$d$s" ] && { cmp -s "$IMG" "$d$s" 2>/dev/null || need=1; }
    done
    blank="$DEADS/blank-banner-$(basename "$d").gif"
    if [ -f "$blank" ]; then
        for b in banner.gif banner-unregistered.gif ; do
            [ -f "$d$b" ] && { cmp -s "$blank" "$d$b" 2>/dev/null || need=1; }
        done
    else
        [ -f "$d""banner.gif" ] && need=1
    fi
done
[ "$need" = 0 ] && exit 0

# --- Apply -------------------------------------------------------------------
echo "===== deads run: $(date 2>/dev/null) ====="
mkdir -p "$DEADS"
remount_rw

for d in "$SS_ROOT"/*/ ; do
    [ -d "$d" ] || continue
    res=$(basename "$d")

    # Sleep screensaver -> your image
    for name in screensvr.gif screensaver-unregistered.gif ; do
        f="$d$name"; [ -f "$f" ] || continue
        [ -e "$f.orig" ] || cp -p "$f" "$f.orig"
        cmp -s "$IMG" "$f" 2>/dev/null || { cp -f "$IMG" "$f" && echo "screensaver: $f"; }
    done

    # Home banner -> same-size blank (generated once, from the original banner)
    for name in banner.gif banner-unregistered.gif ; do
        f="$d$name"; [ -f "$f" ] || continue
        [ -e "$f.orig" ] || cp -p "$f" "$f.orig"
    done
    blank="$DEADS/blank-banner-$res.gif"
    if [ ! -f "$blank" ] && [ -x /mnt/us/linkss/bin/convert ]; then
        export LD_LIBRARY_PATH=/mnt/us/linkss/lib
        export MAGICK_CONFIGURE_PATH=/mnt/us/linkss/etc/ImageMagick-6
        src="$d""banner.gif.orig"; [ -f "$src" ] || src="$d""banner.gif"
        [ -f "$src" ] && /mnt/us/linkss/bin/convert "$src" -evaluate set 100% "$blank" 2>&1
    fi
    if [ -f "$blank" ]; then
        for name in banner.gif banner-unregistered.gif ; do
            f="$d$name"; [ -f "$f" ] || continue
            cmp -s "$blank" "$f" 2>/dev/null || { cp -f "$blank" "$f" && echo "banner: $f"; }
        done
    fi
done

remount_ro
echo "deads done."
exit 0
