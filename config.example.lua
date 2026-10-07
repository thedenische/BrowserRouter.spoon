--
-- BrowserRouter configuration (example)
--
-- Copy this file next to your init.lua as `browsers_config.lua` and customize:
--
--   cp Spoons/BrowserRouter.spoon/config.example.lua ~/.config/hammerspoon/browsers_config.lua
--
-- then load it from init.lua:
--
--   hs.loadSpoon("BrowserRouter"):loadConfig("browsers_config"):start()
--
-- Keep the real file out of version control if it holds private host patterns.
--
-- Rules are evaluated in order; first match wins.
-- Patterns are Lua patterns (https://www.lua.org/manual/5.4/manual.html#6.4.1)
-- matched against the full URL.
--
-- `browser` / `defaultBrowser` accept a short name (resolved via
-- `spoon.BrowserRouter.browsers`) or a raw bundle ID:
--   zen       -> app.zen-browser.zen
--   firefox   -> org.mozilla.firefox
--   chrome    -> com.google.Chrome
--   chromium  -> org.chromium.Chromium
--   safari    -> com.apple.Safari
--   arc       -> company.thebrowser.Browser
--   brave     -> com.brave.Browser
--   edge      -> com.microsoft.edgemac
--   vivaldi   -> com.vivaldi.Vivaldi
--   opera     -> com.operasoftware.Opera
-- Add your own names via a top-level `browsers = { name = "bundle.id" }`.
-- Find a bundle ID with: osascript -e 'id of app "App Name"'
--
-- Optional `profile` field works for Chromium-based browsers (Chrome, Edge,
-- Brave, Vivaldi, Chromium). Use the profile's directory name, e.g. "Default",
-- "Profile 1". Find it in chrome://version under "Profile Path".
--
-- Optional `args` field passes extra command-line flags, e.g.
-- { "--no-default-browser-check" }. Profile and args only apply when the
-- browser is launched (ignored if it's already running).
--
-- Optional `match` field is a `function(url, scheme, host, params) -> boolean`,
-- checked in addition to `hosts`.
--

return {
    defaultBrowser = "zen",

    rules = {
        {
            browser = "zen",
            hosts = {
                -- "^https://[%w.-]*%.example%.com/",
            },
        },
        -- Example: Chrome with a custom profile and no default-browser prompt:
        -- {
        --     browser = "chrome",
        --     profile = "Profile 1",
        --     args = { "--no-default-browser-check" },
        --     hosts = { "^https://work%.example%.com/" },
        -- },
    },
}
