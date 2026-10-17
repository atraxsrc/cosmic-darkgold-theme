# Cosmic DarkGold / Cosmic White Gold for Cursor

Colour themes for [Cursor](https://cursor.com) from the COSMIC
[DarkGold](https://github.com/atraxsrc/cosmic-darkgold-theme) rice and its light half
[White Gold](https://github.com/atraxsrc/cosmic-whitegold-theme): **Cosmic DarkGold** and **Cosmic White Gold** in one
extension. It is a plain VS Code theme extension, so VS Code and VSCodium
take it too. The same folder ships in both repos.

## Install

```bash
./vscode/install.sh                # Cursor
./vscode/install.sh code codium    # VS Code / VSCodium instead
```

It packs this folder into `vscode/cosmic-darkgold-theme-<version>.vsix` and installs
that with the editor's CLI (`cursor --install-extension`), so the theme is
listed under Extensions and running the script again updates it. Then press
<kbd>Ctrl</kbd>+<kbd>K</kbd> <kbd>Ctrl</kbd>+<kbd>T</kbd> and pick **Cosmic DarkGold** or **Cosmic White Gold**.

No CLI on the PATH (an AppImage, say): the script still builds the `.vsix`;
install it from Extensions → `...` → **Install from VSIX**.

## Follow COSMIC's Dark / Light toggle

COSMIC tells apps which mode is on through its desktop portal. With these
lines in Cursor's `settings.json` (<kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> →
**Preferences: Open User Settings (JSON)**), Cursor switches between the two
themes along with the desktop:

```jsonc
"window.autoDetectColorScheme": true,
"workbench.preferredDarkColorTheme": "Cosmic DarkGold",
"workbench.preferredLightColorTheme": "Cosmic White Gold"
```

## What it colours

Code is coloured the way Neovim is in the rice (`nvim/colors/*.lua`):

| Role | DarkGold | White Gold |
|------|----------|------------|
| Keywords, tags | ![#E75A50](https://placehold.co/12x12/E75A50/E75A50.png) `#E75A50` | ![#7A1F22](https://placehold.co/12x12/7A1F22/7A1F22.png) `#7A1F22` |
| Functions, tag attributes | ![#C0AF7F](https://placehold.co/12x12/C0AF7F/C0AF7F.png) `#C0AF7F` | ![#655628](https://placehold.co/12x12/655628/655628.png) `#655628` |
| Strings | ![#A99B7A](https://placehold.co/12x12/A99B7A/A99B7A.png) `#A99B7A` | ![#725C0A](https://placehold.co/12x12/725C0A/725C0A.png) `#725C0A` |
| Numbers, constants | ![#E58980](https://placehold.co/12x12/E58980/E58980.png) `#E58980` | ![#6C5319](https://placehold.co/12x12/6C5319/6C5319.png) `#6C5319` |
| Types, classes, modules | ![#7A858C](https://placehold.co/12x12/7A858C/7A858C.png) `#7A858C` | ![#4A545A](https://placehold.co/12x12/4A545A/4A545A.png) `#4A545A` |
| Imports, macros, decorators, escapes, `this` / `self` | ![#E1CE98](https://placehold.co/12x12/E1CE98/E1CE98.png) `#E1CE98` | ![#6A3D5A](https://placehold.co/12x12/6A3D5A/6A3D5A.png) `#6A3D5A` |
| Parameters (italic) | ![#A8A59B](https://placehold.co/12x12/A8A59B/A8A59B.png) `#A8A59B` | ![#665E4A](https://placehold.co/12x12/665E4A/665E4A.png) `#665E4A` |
| Operators, punctuation | ![#918F86](https://placehold.co/12x12/918F86/918F86.png) `#918F86` | ![#665E4A](https://placehold.co/12x12/665E4A/665E4A.png) `#665E4A` |
| Comments (italic) | ![#6D6D6D](https://placehold.co/12x12/6D6D6D/6D6D6D.png) `#6D6D6D` | ![#7A7259](https://placehold.co/12x12/7A7259/7A7259.png) `#7A7259` |
| Accent | ![#C0AF7F](https://placehold.co/12x12/C0AF7F/C0AF7F.png) `#C0AF7F` | ![#655628](https://placehold.co/12x12/655628/655628.png) `#655628` |

The workbench takes the window colour of the rice's `cosmic/*.ron` for the
editor, side bars, panel, title and status bar, the container colours for
menus, hovers, inputs and the command palette, and the accent for the active
tab line, buttons, badges and the menu highlight. The integrated terminal uses
the rice's COSMIC Terminal scheme (`cosmic-term/`), so command output looks the
same as in COSMIC Terminal.

Cursor's own panels (Agent, chat, inline diffs) have no colour keys of their
own. Cursor builds them from standard ones, and the theme sets those: the
button colour is the agent's accent, the side bar and panel colours are its
surfaces, the diff colours are its accept / reject highlights, and the
terminal's `blue` slot colours its links.

## Contrast

Text is at least 4.5:1 on the window background and on menus and hovers,
comments and line numbers at least 3:1, checked with a script over the text
and background pairs the theme sets.
Where a Neovim colour falls short, it is darkened (light theme) or lightened
(dark theme) just far enough here:

- **DarkGold**: types and links `#77838A` → `#7A858C`; warnings and modified files `#E58980` → `#E68E85`; added files and success marks `#A99B7A` → `#B2A587`.
- **White Gold**: warnings and modified files `#6C5319` → `#624C17`; added files and success marks `#725C0A` → `#604D08`.

On the highlighted current line, code can dip slightly under 4.5:1 and
comments under 3:1.
