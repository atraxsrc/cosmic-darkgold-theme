# Firefox - DarkGold / Harbor Dark

Firefox chrome matching the COSMIC DarkGold rice. Same layout as Monochrome
Dark and Cosmic Night, with gray / lime swapped for gold and charcoal.

Two layers, use one or both:

1. **Theme (colours):** the [cosmic-darkgold-theme](https://addons.mozilla.org/en-US/firefox/addon/cosmic-darkgold-theme/)
   add-on (formerly harbordark) colours the toolbar, tabs and frame. This is the main look.
2. **Stylesheets (optional):** `chrome/userChrome.css` / `userContent.css`
   add rounded corners, gold menu hover, gold accents and a blank new-tab
   grid on top of whatever theme is active.

The stylesheets are written to sit on top of cosmic-darkgold-theme. They also work with
Firefox's built-in Dark theme if you would rather not install the add-on.

## Palette

| Hex       | Role                      |
|-----------|---------------------------|
| `#1B1B1B` | Frame, page chrome        |
| `#252525` | Panels, menus             |
| `#3D382C` | Menu hover row            |
| `#4A4334` | Menu pressed row          |
| `#3D3D3D` | Separators, menu border   |
| `#6d6d6d` | Muted text                |
| `#C0AF7F` | Accent, URL bar border    |
| `#a99b7a` | Secondary border / links  |
| `#E1CE98` | Body text                 |
| `#efebdc` | Hover text                |

## Structure

```
firefox/
├── theme/            WebExtension theme source (cosmic-darkgold-theme)
│   ├── manifest.json     the 37 colour keys of the published add-on
│   └── icons/            32 / 48 / 64 / 96 / 128, the pair's samurai (shared with White Gold)
├── chrome/
│   ├── userChrome.css    browser UI: rounded corners, gold menu hover
│   └── userContent.css   new tab page: gold accents, blank shortcut tiles
└── install.sh            copies chrome/ into the default profile
```

## Theme

`theme/` is the source of the cosmic-darkgold-theme add-on, the baseline the
other rices' Firefox themes copy. Icons take the calm accent (gold), and
everything "hot" (tab line, pressed button, menu and sidebar selection,
attention, the focused URL bar ring and URL bar text selection) takes the loud
one (coral). Loading takes gold. Every text colour clears WCAG AA (4.5:1) on
its background; icons, the tab line and the URL bar ring clear 3:1.

| Hex       | Where in the theme                          |
|-----------|---------------------------------------------|
| `#1B1B1B` | Frame, new tab, toolbar edges, text on coral selections |
| `#2A2A29` | Toolbar, active tab, menus                  |
| `#3C3C39` | URL bar field, button hover, separators, sidebar border |
| `#EFEBDC` | Body text                                   |
| `#A99B7A` | Inactive tab text, menu border              |
| `#C0AF7F` | Icons, loading                              |
| `#E75A50` | Focused URL bar ring and text selection, tab line, pressed button, menu and sidebar selection, attention |

The colours are the published 1.3 exactly. The manifest is 1.4 because it adds
a `description` and the `icons` (1.3 had none) and drops 1.3's blank
background image, a leftover from Firefox Color.

Build the package:

```bash
cd theme && zip -r -X ../cosmic-darkgold.zip . -x '.*'
```

Try it without installing: `about:debugging#/runtime/this-firefox` → **Load
Temporary Add-on** → pick `theme/manifest.json`. It is gone on restart.

## Setup

```bash
./install.sh
```

Copies `chrome/` into your `*.default-release` profile, backs up anything it
replaces, and adds two prefs to `user.js`: one so Firefox reads the
stylesheets, one so the accent (URL bar ring, buttons) comes from the theme
and not the desktop. Then **fully restart**
Firefox. `userChrome.css` is parsed only at startup.

To install into another profile (a test profile, say), pass its folder:

```bash
./install.sh ~/.mozilla/firefox/<profile>
```

Every rice's `install.sh` takes the same argument, so switching a test
profile between rices is one command plus a restart.

Manual equivalent:

1. `about:config` → `toolkit.legacyUserProfileCustomizations.stylesheets` = `true`
2. `about:support` → Profile Directory → Open Directory
3. Copy `chrome/` in
4. Restart

To undo: delete the two files and restart, or run the Monochrome / Tokyo Night
`firefox/install.sh` to switch back.

## Notes

- **Never set `--panel-*` or `--arrowpanel-*` on `:root`.** Those variables leak
  into the toolbar and blank the URL bar. They stay on the popup elements.
- **Context menus do not get an extra element border.** A second stroke made
  the right-click panel look detached. Hover is a gold-tinted `#3D382C` row
  with a 3px gold rail on the left, not a full ring. (The old `#2E2E2E` was
  almost invisible on `#252525`.)
- **Native menu styling is switched off** (`appearance: none`) on menus and
  menu rows. Without it the COSMIC/GTK hover paints over the colours above.
- **`[_moz-menuactive="true"]` is required.** Firefox marks the active
  context-menu row with that attribute, not only `:hover`.
- **`userContent.css` is colours plus one hide rule.** It sets accent / focus /
  link colours and hides shortcut artwork (`opacity: 0`) so the new-tab tiles
  stay blank. No size or position rules on the tiles.

## License

MIT, same as the rest of the repo.
