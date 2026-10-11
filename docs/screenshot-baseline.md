# Screenshot baseline

One hero screenshot per rice, same scene in every repo, so the only thing that
changes between the six images is the palette. Stored at `assets/screenshot.png`
and embedded under the title of each README.

## The scene

| Where | What | Why it is there |
|-------|------|-----------------|
| Top panel | Workspaces, status applets, clock | Panel colours, applet icons |
| Left column, top | COSMIC Terminal running `fastfetch` | Names the DE, terminal scheme and font, prints the palette dots with the rice name |
| Left column, bottom | COSMIC Terminal with LazyVim on `cosmic/<Rice>.ron` | Terminal scheme, syntax colours, status line, and the file is the theme itself |
| Bottom right | Postilla on `docs/showcase.md`, editor + preview | A libcosmic window: header bar, frosted glass, squared corners, accent, icon pack, and the note renders the palette table, a Mermaid diagram and a Typst formula |
| Everything else | The rice's wallpaper | The recolour, uncovered on the right |

Nothing else open. No Files, no browser, no btop, no notifications.

## Wallpaper per rice

All in [cool-wallpapers](https://github.com/atraxsrc/cool-wallpapers), folder `cosmic/<rice>/`.

| Rice | File |
|------|------|
| DarkGold | `darkgold-reaper-skull-3440x1440.png` |
| WhiteGold | `whitegold-samurai-3840x2166.png` |
| TokyoNight | `tokyonight-astronaut-7168x4032.png` |
| Monochrome | `cosmic-astronaut-gray-standard-5376x3072.jpg` (top of `cosmic/`) |
| Noir | `noir-reaper-skull-3840x1609.png` |
| Dossier | `dossier-eagle-3584x2016.png` |

## Before capturing

Apply the whole rice first, or the shot documents the wrong thing:

1. Appearance: import `cosmic/<Rice>.ron` into the right slot (Dark or Light).
2. Terminal: import `cosmic-term/<Rice>-term.ron` and select it for the profile.
3. `./cosmic/install.sh` for fonts, icons and the terminal look; icons installed.
4. `./cursors/install.sh` where the rice ships one, then log out and in.
5. `./zsh/install.sh` and `./fastfetch/install.sh`, then `exec zsh`.
6. Wallpaper from the table above.
7. `./nvim/install.sh`, then restart Neovim, so the LazyVim pane uses the rice colorscheme
   and `.ron` files are highlighted.

## Terminal panes

Run from inside the rice repo so the prompt shows the folder name only:

```bash
cd ~/Documents/projects/repos/github/cosmic-<rice>-theme
clear && fastfetch           # top pane
nvim cosmic/<Rice>.ron       # bottom pane, scroll so the palette block is visible
```

Postilla: open the rice repo as the vault, open `docs/showcase.md`, layout editor + preview
(`Ctrl+2`). First import `cosmic-term/<Rice>-term.ron` in Settings → Appearance → Import
theme and turn on painting the window with it, so the editor matches the terminal.
Scroll the preview so the palette table and the diagram are both visible.

## PII check

- Prompt shows the directory only, never `user@host`.
- No `lsd -l` or `ls -l` on screen: the owner column prints the username. `lsd --tree` is fine.
- No process list (btop shows the account name in the User column).
- No Files window on Home: the dotfolders fingerprint the machine.
- No browser, no password manager, no notification popups.
- fastfetch config has no `title`, `user` or `localip` module. The ones in these repos do not.
- `update_system.sh` prints the `0XDEV1` banner. Public already, but keep it off screen unless that is the point.

## Capture and hand-off

- Capture the full screen at 3840x2160 with COSMIC's screenshot tool (Super + Print).
- Drop the PNG anywhere in the rice repo. It is then resized to 2560x1440, metadata stripped, placed at `assets/screenshot.png` and embedded as:

```markdown
![Pop!_OS COSMIC desktop with the <Rice> theme](assets/screenshot.png)
```

Expect 1 to 2 MB per repo. GitHub renders READMEs under 1000 px wide, so 4K would only add weight.

## Optional second shot

COSMIC Settings open on Appearance beside Firefox with the rice stylesheets. Proves the import and the browser theme. Not part of the baseline; do the hero shot for all six first.
