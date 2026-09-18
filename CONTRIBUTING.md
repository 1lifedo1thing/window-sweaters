# Contributing

Use the macOS Command Line Tools and run `make test` before submitting changes.
Keep changes focused and include reproduction steps and relevant validation.
Do not run live-window probes unattended: they create visible temporary windows.

## Compatibility contracts

- Keep `CFBundleIdentifier` as **`local.knitborders.app`**. The previous
  `local.knitborders` identity failed menu-bar hosting on the development Mac;
  changing only the identity restored it. Do not revert it as part of a rename.
- Preserve existing preferences and the legacy Application Support paths.
- The default border width is 12 pt. A default change must not overwrite a user's
  saved selection. Keep the native menu and renderer defaults consistent.
- AppKit UI, tracked-window state and geometry updates belong on the main thread.
  Keep slow window-list collection off it. Preserve resize suppression and
  window lifecycle safeguards when changing rendering.
- A visible status-item flag or successful WindowServer transaction does not
  prove that pixels are visible. Document the limits of automated checks.

## Visual changes

Use `make catalogue` to inspect full windows and enlarged corners, plus 1x/2x
renderer checks from `make test`. When adding an app, update its rule, chart, catalogue metadata, collection count
checks, public collection page, and both PDF catalogues. Catalogue exports must
use built-in profiles without loading personal settings or PNG overrides.
Keep the SVG and native status-icon geometry
in sync. Use original artwork; do not add third-party reference images without
appropriate permission.

## Manual checks

Test menu actions, dragging, resizing from every edge, close/minimize/restore,
overlapping apps, and a display transfer in each direction. Include the macOS
version and display arrangement when reporting a tracking problem. Avoid
including window titles, private content or personal configuration in reports.

Optional probes can be built with `make bin/live-display`, `make bin/live-resize`
and `make bin/live-order`. Read each probe's source for its scope before running.
The display probe uses its own temporary window and a separate border connection.

## Before publishing a release

Run the tests and manual checks on the intended macOS versions. Update both the
bundle version in `AppInfo.plist` and command-line version in `src/main.c`.
Release builds must keep `ARCHS` and `DEPLOY` in the Makefile: without an explicit
`-mmacosx-version-min`, clang targets whatever macOS built it and the binary then
refuses to launch below that version, no matter what `LSMinimumSystemVersion` says.
Confirm with `vtool -show-build` that both slices report the intended `minos`.
Distribution signing and notarization are not configured by the local build.
Publish source with the license and attribution; do not upload local logs,
archives, personal settings, build products or developer signing credentials.

## Automatic colourways

`src/autoyarn.m` handles apps without built-in or personal rules. The window
owner PID selects the icon; decoding and colour extraction run on a serial
worker. Cache updates, chart generation and redraw callbacks run on the main
thread. Never capture a border pointer in an icon job: its window may close
before the job completes.

`tests/autoyarn.m` supplies synthetic icons to the same decoder and cache. It
checks contrast after softening, transparency, asynchronous completion, rule
precedence, mode changes, reloads, relaunches and cache/table limits without
requiring running apps. The native menu test checks generated-chart filtering.

Automatic sweaters use two yarns. Pattern shape is a stable hash of the app
name, independent of icon colour. Colourless icons retain the existing name-
based fallback. The cache holds 64 recent processes; a full chart table can
retain the icon colour without a motif until chart space is available.
