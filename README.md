# BrowserRouter.spoon

A small Hammerspoon [Spoon](https://www.hammerspoon.org/Spoons/) that routes
http(s) links to different browsers based on URL patterns. Rules are checked in
order (first match wins); anything unmatched goes to a default browser. Rules can
also pick a Chromium profile and pass extra command-line flags.

## Requirements

- [Hammerspoon](https://www.hammerspoon.org/), set as the default web browser
  (System Settings → Desktop & Dock → Default web browser).

## Installation

Clone into `~/.config/hammerspoon/Spoons/`:

```sh
git clone https://github.com/thedenische/BrowserRouter.spoon.git \
  ~/.config/hammerspoon/Spoons/BrowserRouter.spoon
```

## Usage

```lua
hs.loadSpoon("BrowserRouter")
spoon.BrowserRouter:configure({
  defaultBrowser = "zen",
  rules = {
    {
      browser = "chrome",
      args    = { "--no-default-browser-check" },
      hosts   = { "^https://github%.com/login/device" },
    },
    {
      browser = "chrome",
      profile = "Profile 1",
      hosts   = { "^https://[%w.-]*%.work%.example%.com/" },
    },
  },
}):start()
```

To keep private host patterns out of a public dotfiles repo, put the table in a
separate gitignored module and load it with `loadConfig`. A missing file is
ignored (defaults are used); a file that fails to load is reported in the
Hammerspoon console and an alert:

```lua
hs.loadSpoon("BrowserRouter"):loadConfig("browsers_config"):start()
```

A commented template with all options is included as
[`config.example.lua`](./config.example.lua); copy it to get started:

```sh
cp ~/.config/hammerspoon/Spoons/BrowserRouter.spoon/config.example.lua \
   ~/.config/hammerspoon/browsers_config.lua
```

### Rules

| Field     | Description                                                              |
| --------- | ------------------------------------------------------------------------ |
| `browser` | Bundle ID or name of the target browser (required)                       |
| `hosts`   | List of [Lua patterns](https://www.lua.org/manual/5.4/manual.html#6.4.1) matched against the full URL |
| `match`   | Optional `function(url, scheme, host, params) -> boolean`                |
| `profile` | Optional Chromium profile directory (`"Default"`, `"Profile 1"`, …)      |
| `args`    | Optional list of extra command-line flags                                |

### Browser names

`browser` and `defaultBrowser` accept a raw bundle ID or a short name from
`spoon.BrowserRouter.browsers`:

| Name       | Bundle ID                    |
| ---------- | ---------------------------- |
| `zen`      | `app.zen-browser.zen`        |
| `firefox`  | `org.mozilla.firefox`        |
| `chrome`   | `com.google.Chrome`          |
| `chromium` | `org.chromium.Chromium`      |
| `safari`   | `com.apple.Safari`           |
| `arc`      | `company.thebrowser.Browser` |
| `brave`    | `com.brave.Browser`          |
| `edge`     | `com.microsoft.edgemac`      |
| `vivaldi`  | `com.vivaldi.Vivaldi`        |
| `opera`    | `com.operasoftware.Opera`    |

Add your own via `configure({ browsers = { name = "bundle.id" } })`. Find a
bundle ID with `osascript -e 'id of app "App Name"'`.

## API

- `spoon.BrowserRouter:configure(config)` — set any of `defaultBrowser`,
  `defaultProfile`, `defaultArgs`, `rules`, `urlRewriters`, `browsers`
  (merged into the built-in name dictionary).
- `spoon.BrowserRouter:loadConfig(moduleName)` — `require` a config module and
  apply it with `configure`; missing module is ignored, load errors are reported.
- `spoon.BrowserRouter:start()` / `:stop()` — install / remove
  `hs.urlevent.httpCallback`.
- `spoon.BrowserRouter:route(url)` — route a URL as if it was clicked.
- `spoon.BrowserRouter:openURL(url, browser[, profile[, args]])`.
- `spoon.BrowserRouter.urlRewriters` — list of
  `function(url, scheme, host, params) -> newUrl|nil` applied before routing.
  By default unwraps Microsoft Teams redirect links.

## Known limitations

- **Profile and flags only apply on launch.** They are passed as command-line
  arguments, so if the browser is already running the URL opens in its current
  (last used) profile and flags are ignored.

## License

[MIT](./LICENSE)
