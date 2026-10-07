--- === BrowserRouter ===
---
--- Route http(s) links to different browsers based on URL patterns.
---
--- Make Hammerspoon the default web browser (System Settings > Desktop & Dock >
--- Default web browser), then every link you click is handed to this Spoon,
--- which picks a browser using an ordered list of rules (first match wins) and
--- falls back to `defaultBrowser`.
---
--- Rules can also pass a profile (Chromium-based browsers) and extra
--- command-line flags to the target browser:
---
---   hs.loadSpoon("BrowserRouter")
---   spoon.BrowserRouter:configure({
---     defaultBrowser = "app.zen-browser.zen",
---     rules = {
---       {
---         browser = "com.google.Chrome",
---         profile = "Profile 1",
---         args    = { "--no-default-browser-check" },
---         hosts   = { "^https://work%.example%.com/" },
---       },
---     },
---   }):start()
---
--- Download: https://github.com/thedenische/BrowserRouter.spoon

-- `hs` (and `spoon`) are injected by the Hammerspoon runtime; see .luarc.json
-- for the lua-language-server global declarations.

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "BrowserRouter"
obj.version = "1.0.0"
obj.author = "Denis Che <the.denis.che@gmail.com>"
obj.homepage = "https://github.com/thedenische/BrowserRouter.spoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"

--- BrowserRouter.browsers
--- Variable
--- Dictionary of short browser names to bundle IDs. `browser` / `defaultBrowser`
--- accept either a name from this table (e.g. `"chrome"`) or a raw bundle ID.
--- Add your own entries as needed.
obj.browsers = {
    zen      = "app.zen-browser.zen",
    firefox  = "org.mozilla.firefox",
    chrome   = "com.google.Chrome",
    chromium = "org.chromium.Chromium",
    safari   = "com.apple.Safari",
    arc      = "company.thebrowser.Browser",
    brave    = "com.brave.Browser",
    edge     = "com.microsoft.edgemac",
    vivaldi  = "com.vivaldi.Vivaldi",
    opera    = "com.operasoftware.Opera",
}

--- BrowserRouter.defaultBrowser
--- Variable
--- Bundle ID (or name from `browsers`) of the browser used when no rule
--- matches. Default: `"chromium"`.
obj.defaultBrowser = "chromium"

--- BrowserRouter.defaultProfile
--- Variable
--- Optional profile directory (Chromium-based browsers) for the default browser.
obj.defaultProfile = nil

--- BrowserRouter.defaultArgs
--- Variable
--- Optional list of extra command-line flags for the default browser.
obj.defaultArgs = nil

--- BrowserRouter.rules
--- Variable
--- Ordered list of routing rules; the first matching rule wins. Each rule is a
--- table with:
---  * browser - bundle ID or name from `browsers` of the target browser (required)
---  * hosts - list of Lua patterns matched against the full URL
---  * match - optional `function(url, scheme, host, params) -> boolean`, checked
---    in addition to `hosts`
---  * profile - optional profile directory name (Chromium-based browsers, e.g.
---    `"Default"`, `"Profile 1"`; see chrome://version > Profile Path)
---  * args - optional list of extra command-line flags (e.g.
---    `{ "--no-default-browser-check" }`)
obj.rules = {}

--- BrowserRouter.urlRewriters
--- Variable
--- List of `function(url, scheme, host, params) -> newUrl|nil` applied before
--- routing, e.g. to unwrap redirect links. Returning nil keeps the URL as is.
--- By default unwraps links opened from Microsoft Teams.
obj.urlRewriters = {
    function(_, _, host, params)
        if host == "statics.teams.cdn.office.net" and params and params.url then
            return params.url
        end
    end,
}

--- BrowserRouter:configure(config) -> self
--- Method
--- Set any of `defaultBrowser`, `defaultProfile`, `defaultArgs`, `rules`,
--- `urlRewriters`, `browsers` from a table (e.g. one loaded from a private
--- config file). `browsers` entries are merged into the built-in dictionary.
---
--- Parameters:
---  * config - table with any of the fields above; missing fields are left
---    unchanged
---
--- Returns:
---  * The BrowserRouter object
function obj:configure(config)
    for _, key in ipairs({ "defaultBrowser", "defaultProfile", "defaultArgs", "rules", "urlRewriters" }) do
        if config and config[key] ~= nil then
            self[key] = config[key]
        end
    end
    for name, id in pairs(config and config.browsers or {}) do
        self.browsers[name] = id
    end
    return self
end

--- BrowserRouter:loadConfig(moduleName) -> self
--- Method
--- Load a config table from a Lua module (via `require`) and apply it with
--- `configure`. Meant for a private, gitignored file: if the module doesn't
--- exist the defaults are kept silently, but if it exists and fails to load
--- (e.g. a syntax error) the error is printed to the Hammerspoon console and an
--- alert is shown.
---
--- Parameters:
---  * moduleName - name of the module to require, e.g. `"browsers_config"`
---
--- Returns:
---  * The BrowserRouter object
function obj:loadConfig(moduleName)
    local ok, result = pcall(require, moduleName)
    if ok then
        return self:configure(result)
    end
    if not tostring(result):find("module '" .. moduleName .. "' not found", 1, true) then
        hs.printf("%s failed to load: %s", moduleName, tostring(result))
        hs.alert.show(moduleName .. " failed to load (see Hammerspoon console)", 5)
    end
    return self
end

local function ruleMatches(rule, url, scheme, host, params)
    for _, pattern in ipairs(rule.hosts or {}) do
        if string.match(url, pattern) then
            return true
        end
    end
    if rule.match and rule.match(url, scheme, host, params) then
        return true
    end
    return false
end

--- BrowserRouter:openURL(url, browser[, profile[, args]]) -> self
--- Method
--- Open `url` in the browser with bundle ID `browser`.
---
--- Parameters:
---  * url - the URL to open
---  * browser - bundle ID or name from `browsers`
---  * profile - optional profile directory (Chromium-based browsers)
---  * args - optional list of extra command-line flags
---
--- Returns:
---  * The BrowserRouter object
---
--- Notes:
---  * Profile and flags are command-line arguments, so they only take effect
---    when the browser is launched; if it is already running the URL opens in
---    its current (last used) profile.
function obj:openURL(url, browser, profile, args)
    browser = self.browsers[browser] or browser
    local flags = {}
    if profile then
        table.insert(flags, "--profile-directory=" .. profile)
    end
    for _, a in ipairs(args or {}) do
        table.insert(flags, a)
    end

    if #flags == 0 then
        hs.urlevent.openURLWithBundle(url, browser)
        return self
    end

    -- The URL must come before --args so `open` delivers it even when the
    -- browser is already running (launch args are ignored in that case).
    local taskArgs = { "-b", browser, url, "--args" }
    for _, a in ipairs(flags) do
        table.insert(taskArgs, a)
    end
    hs.task.new("/usr/bin/open", nil, taskArgs):start()
    return self
end

--- BrowserRouter:route(url[, scheme, host, params]) -> self
--- Method
--- Rewrite `url` via `urlRewriters`, find the first matching rule and open it
--- in that rule's browser (or the default browser).
---
--- Parameters:
---  * url - the full URL
---  * scheme, host, params - optional, as passed by `hs.urlevent.httpCallback`
---
--- Returns:
---  * The BrowserRouter object
function obj:route(url, scheme, host, params)
    for _, rewrite in ipairs(self.urlRewriters or {}) do
        url = rewrite(url, scheme, host, params) or url
    end

    for _, rule in ipairs(self.rules or {}) do
        if ruleMatches(rule, url, scheme, host, params) then
            return self:openURL(url, rule.browser, rule.profile, rule.args)
        end
    end
    return self:openURL(url, self.defaultBrowser, self.defaultProfile, self.defaultArgs)
end

--- BrowserRouter:start() -> self
--- Method
--- Start handling http(s) links (sets `hs.urlevent.httpCallback`).
---
--- Returns:
---  * The BrowserRouter object
function obj:start()
    hs.urlevent.httpCallback = function(scheme, host, params, fullURL)
        self:route(fullURL, scheme, host, params)
    end
    return self
end

--- BrowserRouter:stop() -> self
--- Method
--- Stop handling http(s) links (clears `hs.urlevent.httpCallback`).
---
--- Returns:
---  * The BrowserRouter object
function obj:stop()
    hs.urlevent.httpCallback = nil
    return self
end

return obj
