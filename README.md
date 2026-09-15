# Window Sweaters

A small native macOS menu-bar app that dresses your windows in knitted borders.
Procedurally rendered yarn, app-inspired colourways, and a little warmth for your desktop.

![Four overlapping windows edged with knitted borders in green, blue and rust colourways](docs/hero.jpg)

*Stylized promotional mockup. See the actual rendered borders in [Sweaters](#sweaters).*

## Install

With [Homebrew](https://brew.sh):

```sh
brew trust saragordic/tap
brew install --cask saragordic/tap/window-sweaters
```

This opens with no security prompt at all. Homebrew requires the trust step for
any third-party tap.

Otherwise download `WindowSweaters-<version>.zip` from [Releases](../../releases),
unzip it, and move **Window Sweaters.app** to your Applications folder.

The app is ad-hoc signed and is not notarized by Apple. If macOS blocks the first launch:

1. Try opening **Window Sweaters.app** once.
2. Open **System Settings → Privacy & Security** and find the blocked-app message.
3. Click **Open Anyway**, then confirm.

See [Apple’s instructions for opening an unnotarized app](https://support.apple.com/en-us/102445).

## What is supported

**macOS 13 Ventura or later, on Apple Silicon or Intel.** The download is a universal
binary and both slices are built against macOS 13.

Hands-on development and testing have been on Apple Silicon running macOS 26. The Intel
slice and macOS 13 through 15 are covered by the build but have not been exercised on
that hardware. Window tracking uses private system APIs, so if something misbehaves on
another release or machine, please open an issue and include your macOS version,
hardware and display arrangement.

## Using it

Open the yarn icon in the menu bar to change patterns, border width and stitch
size, pause sweaters, or quit. New installations use **12 pt borders**, six stitch
rows, and **Pattern → By App**. Your saved choices take precedence.

If macOS requests Accessibility access, enable the app in System Settings →
Privacy & Security → Accessibility. That permission supports focus detection;
this app does not need Full Disk Access.

## Build from source

Requires Apple's Command Line Tools (`xcode-select --install`) and Python 3 for the local installer.

```sh
git clone https://github.com/saragordic/window-sweaters.git
cd window-sweaters
./scripts/build-app.sh
python3 scripts/install-local.py
```

The build creates `outputs/Window Sweaters.app`. The installer puts one copy in
`~/Applications/Window Sweaters.app` and opens it. It replaces only this app or
its previous **Knit Borders** installation, with a backup in the temporary folder.
Local builds are ad-hoc signed, not Developer ID signed or notarized.

## Sweaters

![Eight apps shown in By App and Zigzag styles, with enlarged yarn details](docs/collection/styles-comparison.png)

Eight favourite apps, each shown in **By App** and **Zigzag**, straight from the
renderer at 12 pt. The [collection catalogue](docs/COLLECTION.md) shows all 37 app colourways and
close-up yarn details. Download the [By App PDF](docs/catalogues/Window-Sweaters-Catalogue.pdf)
or [Zigzag PDF](docs/catalogues/Window-Sweaters-Zigzag-Catalogue.pdf) to browse offline.

Unknown apps receive a consistent fallback colour; the
app does not extract colours from icons. App names identify the inspiration and
do not imply affiliation or endorsement.

The monochrome [yarn icon](assets/yarn-menu-icon.svg) uses a native AppKit template
so its tint follows the menu bar's appearance.

## Current limitations

Window Sweaters and [JankyBorders](https://github.com/FelixKratz/JankyBorders) can be
installed side by side, but running both at once means two sets of borders on the same
windows. Quit one before starting the other. Window Sweaters reads its own optional
config from `~/.config/window-sweaters/sweatersrc` and never JankyBorders' `bordersrc`.

This is an experimental desktop utility. Window tracking uses private SkyLight
APIs, which may change between macOS releases. Borders deliberately hide during
resizing and reappear when the window settles. Movement, stacking, display
transfers and window lifecycles have automated coverage, but that does not
establish perfect behaviour in every app, Space or display arrangement.

## Personal colourways

Advanced customisation is file-based for now. Edit the files below, then restart
the app to load your changes.
For compatibility, custom files remain in:

```text
~/Library/Application Support/Knit Borders/apps.conf
~/Library/Application Support/Knit Borders/charts/
```

Example rule:

```text
Claude = #D58561 atelier-claude
```

Rules match process-name prefixes, case-insensitively; the longest matching rule
wins. PNG charts can override built-in patterns. Built-ins need no external files.
Your personal configuration is not included in this repository.

## Development

```sh
make test       # renderer, collection, tracking, lifecycle, focus and menu checks
make catalogue  # regenerate the visual catalogue from the native renderer
make bench     # renderer benchmark
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for testing and compatibility conventions.

## Credits and license

Built on [JankyBorders](https://github.com/FelixKratz/JankyBorders) by Felix Kratz.
This project retains the existing [GNU GPL v3 license](LICENSE).
See [NOTICE.md](NOTICE.md) for attribution.
