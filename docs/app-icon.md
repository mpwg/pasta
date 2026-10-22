<!--
SPDX-FileCopyrightText: 2026 Matthias Wallner-Géhri
SPDX-License-Identifier: GPL-3.0-or-later
-->

# Pasta app icon

The selected design is a golden farfalle clip on an ivory clipboard against an orange background.

![Pasta app icon](images/pasta-icon.png)

## Editing and integration

Open the editable source, [`Pasta/AppIcon.icon`](../Pasta/AppIcon.icon), in Apple's Icon Composer. The orange gradient is a native background. The separate foreground asset `Assets/pasta-clip.png` is 1024 × 1024 with alpha transparency; the gray presentation background was removed. Icon Composer renders the outer shape and appearance variants, including the system-derived dark background.

Xcode discovers the icon in the synchronized app directory and compiles it with `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`. Settings displays the icon from the running app bundle.

## Provenance

The artwork was generated with the built-in image generation tool and its foreground extracted with the same tool. No external image service or CLI fallback was used. The package was created and validated with the installed [compose-app-icon skill](https://github.com/giginet/apple-icon-composer-skill).

Final editing prompt, using the selected design as a reference:

> Use case: background-extraction. Edit target: the attached selected macOS Pasta app icon. Extract ONLY the ivory clipboard, its overlapping ivory paper sheets, and the golden farfalle pasta clip, retaining their exact design, relative positions, proportions, colors and beautiful tactile shading. Remove BOTH the gray outside background AND the entire orange rounded-square background tile completely. Deliver the clipboard-and-farfalle foreground centered on a square fully transparent canvas with comfortable transparent margins around all sides (roughly 15% on left/right and 8% top/bottom). Preserve the object, do not redesign, no extra objects, no text, no gray border, no orange background, no baked-in background shadow or glow. True alpha transparency around the extracted object and soft edge antialiasing. This foreground will be layered over an orange native Icon Composer background.

## Historical verification — October 22, 2026

- Package and asset references passed the skill's schema validator.
- Apple's `ictool` rendered light and dark macOS previews, which were visually inspected.
- Xcode built successfully; the build log confirmed `AppIcon.icon` as input to `actool` and generation of `AppIcon.icns` and `Assets.car`.
- The built bundle had `CFBundleIconName = AppIcon`; its exported icon had no gray outer border.
- Xcode MCP test run at 14:11 CEST: 17 passed, 0 failed, 0 skipped, including English and German Settings and English fallback.

These are historical development results, not evidence for later release builds.
