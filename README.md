# kindle-special-offers-killer

Replace the Amazon **"Special Offers"** ads on an old jailbroken Kindle with your
own screensaver — and blank the home-screen ad banner — **for free**, without
paying Amazon's removal fee and without SSH.

Built and tested on a **Kindle 4 Non-Touch (2011/2012), firmware 4.1.4** — the
600×800 e-ink models. It should also apply to the Kindle 5 (Basic, 2012) and
similar `adunits`-based ad firmware.

![the wave as a Kindle screensaver](examples/thewave.png)

---

## Why this is needed

The popular [NiLuJe ScreenSavers hack (`linkss`)][linkss] swaps the *normal*
screensaver folder. But on an **ad-supported** Kindle the sleep image doesn't
come from there — it's drawn by the Special Offers ad subsystem from GIFs under:

```
/opt/amazon/screen_saver/adunits/<resolution>/
  screensvr.gif                 <- the active ad sleep image
  screensaver-unregistered.gif  <- the "Please connect wirelessly..." placeholder
  banner.gif / banner-unregistered.gif   <- the home-screen ad strip
```

Those files sit on the Kindle's **internal root filesystem**, which the USB
cable never exposes — so you can't just drop a file on the drive. This project
adds a tiny **root boot-script** (run via the linkss hack) that, on every
startup, copies *your* image over the ad GIFs and blanks the banner.

- **Idempotent & self-healing** — does nothing once everything matches; re-applies if an ad ever sneaks back.
- **Reversible** — every changed file is backed up next to it as `*.orig`; a one-file `RESTORE` marker undoes everything.
- **No SSH / no networking** — runs entirely on the device at boot.

## Prerequisites

You need a Kindle that is **already**:

1. **Jailbroken** — e.g. NiLuJe's K4 jailbreak ([KindleModding mirror][k4jb]).
2. Running the **linkss ScreenSavers hack** ([thread][linkss]) — so a `linkss/`
   folder exists at the root of the Kindle's USB drive.

Keep **Wi-Fi OFF** throughout, and never accept an Amazon software update — an
OTA re-locks the jailbreak.

## Install

With the Kindle plugged in (showing as a USB drive), from a Bash shell
(Git Bash on Windows, Terminal on macOS/Linux):

```sh
./install.sh <KINDLE_DRIVE_ROOT> <YOUR_IMAGE>

# Windows, Kindle is drive G:
./install.sh /g ./examples/thewave.png

# macOS
./install.sh /Volumes/Kindle my-photo.png
```

Then, **on the Kindle**:

1. Safely eject and unplug.
2. `Menu → Settings → Menu → Restart`.
3. After it boots, press power to sleep it — your image appears. The
   home-screen banner is blank.

The installer converts your image to a 600×800 grayscale GIF (via ImageMagick,
or via the bundled PowerShell helper on Windows), installs the boot worker, and
wires it into `linkss/bin/linkss`.

## Uninstall / restore Amazon's originals

```sh
./uninstall.sh <KINDLE_DRIVE_ROOT>          # drops a RESTORE marker
# reboot the Kindle once (restores *.orig, disables the mod)
./uninstall.sh <KINDLE_DRIVE_ROOT> --finish # removes the hook + files from the card
```

## How it works (under the hood)

`linkss/bin/kindle-deads.sh` is appended to the linkss boot script so it runs as
root at startup. It remounts `/` read-write, loops over every
`/opt/amazon/screen_saver/adunits/<res>/` directory, replaces the screensaver
GIFs with your image, generates a same-size white banner with the linkss-bundled
ImageMagick (`convert ... -evaluate set 100%`) and installs it over the banner
GIFs, then remounts read-only. All output is logged to `/mnt/us/deads.log`.

## Repo layout

```
linkss/bin/kindle-deads.sh   the on-device boot worker (the core)
install.sh                   stage everything onto the Kindle (run on your PC)
uninstall.sh                 restore originals / remove the mod
tools/png2kindlegif.ps1      Windows image -> Kindle GIF converter (no ImageMagick needed)
examples/thewave.png         sample 600x800 screensaver (Hokusai's Great Wave)
```

## Disclaimer

Modifying your Kindle's system files is unsupported by Amazon, voids warranties,
and can in principle brick a device. This is provided **as-is, no warranty** —
use at your own risk. It only edits the Special Offers screensaver/banner assets
and keeps backups, but you are responsible for your device. Intended for
hardware you own.

## Credits

- [NiLuJe][linkss] — the Kindle jailbreak and ScreenSavers (`linkss`) hack this builds on.
- The [KindleModding][km] community for keeping legacy Kindle hacking alive.

[linkss]: https://www.mobileread.com/forums/showthread.php?t=88004
[k4jb]: https://kindlemodding.org/jailbreaking/Legacy/K4-Jailbreak/
[km]: https://kindlemodding.org/

## License

MIT — see [LICENSE](LICENSE).
