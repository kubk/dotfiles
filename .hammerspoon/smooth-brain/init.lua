-- Smooth Brain: type as fast as you can, skip spaces, ignore typos; then press Return three times (or
-- Hyper+W) and the paragraph you just typed is fixed in place by a very fast model.
--
--   * Triple Return in a text field: the first two Returns go through as usual (no lag on a normal Enter),
--     the third is swallowed, and the paragraph is fixed (the two line breaks go away with it). Shift+Return
--     three times works too, for chat apps where Return sends.
--   * Hyper+W (⌘⌥⌃⇧W): same, from anywhere in a text field.
--   * Only the last paragraph is sent (or, with Hyper+W, exactly the text you selected, however many paragraphs).
--   * Keep typing while it works: nothing is selected until the fix is back, and keys pressed during the swap
--     (~0.1 s) are held and replayed.
--   * Line breaks are kept exactly; they never go through the model.
--   * Your clipboard is left alone: native apps are edited through Accessibility; in browsers the fix is pasted
--     from a transient clipboard entry (clipboard managers skip it) and everything on the clipboard is put back.
--   * Images in the paragraph survive: its HTML is fixed with every tag held in place.
--
-- Model: Qwen 3.8 27B on Cerebras via OpenRouter, falling back to the fastest other provider when Cerebras
-- is rate-limited. Needs an OpenRouter API key: asked for on first use, kept in the macOS Keychain.
--
-- Use: require("smooth-brain").start()
--      require("smooth-brain").start({ hotkey = { {"cmd","alt"}, "f" }, tripleReturn = false })
--      Turns on "Launch Hammerspoon at login" so it survives restarts; start({ autoLaunch = false }) to opt out.

local M = {}

local MODEL = "qwen/qwen3.8-27b"
local PROVIDER = { only = { "cerebras" }, allow_fallbacks = false }
local FALLBACK_PROVIDER = { ignore = { "cerebras" }, sort = "throughput" }

local PROMPT = [[The user typed the text below as fast as possible and did not correct anything: words may be
run together with missing spaces, letters may be missing, doubled, swapped or wrong, and punctuation or
capitalisation may be sloppy. Rewrite it as the text they meant to type. Keep their words, wording, language,
tone, line breaks, markdown, links, @mentions, emoji and anything that is already correct; do not rephrase,
add, explain or answer it. Reply with the corrected text only.]]

-- OpenRouter key: OPENROUTER_API_KEY in Hammerspoon's environment, else the macOS Keychain. Never logged.
local KC_SERVICE, KC_ACCOUNT = "smooth-brain-openrouter", "openrouter"

local function apiKey()
  if M.key then return M.key end
  local env = os.getenv("OPENROUTER_API_KEY")
  if env and env ~= "" then M.key = env; return M.key end
  local out, ok = hs.execute(string.format("/usr/bin/security find-generic-password -s %s -a %s -w 2>/dev/null", KC_SERVICE, KC_ACCOUNT))
  local k = ok and out and out:gsub("%s+$", "") or ""
  if k ~= "" then M.key = k end
  return M.key
end

local function storeKey(k)
  M.key = k
  M.kcTask = hs.task.new("/usr/bin/security", function(code)
    if code ~= 0 then hs.alert.show("Couldn't save the key to the Keychain (it's kept until Hammerspoon restarts)") end
  end, { "add-generic-password", "-U", "-s", KC_SERVICE, "-a", KC_ACCOUNT, "-w", k })
  M.kcTask:start()
end

-- Ask for the key (first use, or after it was refused). Returns the key or nil.
function M.askKey(why)
  hs.focus()
  local info = (why and (why .. "\n\n") or "")
    .. "Smooth Brain sends the text you're fixing to an AI model through OpenRouter.\n"
    .. "Paste an OpenRouter API key (it's stored in your Keychain).\n\n"
    .. "Don't have one? Leave the field empty and press Save to open https://openrouter.ai/keys"
  while true do
    local button, text = hs.dialog.textPrompt("OpenRouter API key", info, "", "Save", "Cancel")
    if button ~= "Save" then return nil end
    local k = (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if k ~= "" then storeKey(k); return k end
    hs.urlevent.openURL("https://openrouter.ai/keys")
  end
end

-- Log (no keys, no content): ~/.hammerspoon/smooth-brain.log
local LOG = os.getenv("HOME") .. "/.hammerspoon/smooth-brain.log"
local function wlog(fmt, ...)
  local ok, line = pcall(string.format, fmt, ...)
  local f = io.open(LOG, "a")
  if f then f:write(os.date("%Y-%m-%d %H:%M:%S "), ok and line or fmt, "\n"); f:close() end
end
local windows = { wlog = wlog }

local BROWSERS = { ["com.google.Chrome"] = true, ["com.google.Chrome.beta"] = true, ["company.thebrowser.Browser"] = true,
  ["com.apple.Safari"] = true, ["org.mozilla.firefox"] = true, ["com.brave.Browser"] = true, ["com.microsoft.edgemac"] = true }

-- One request; onDone(reply) or onDone(nil, message). On a rate limit, retries once on another provider.
-- hs.http keeps its connection to OpenRouter open between requests (a new connection per fix costs ~0.5 s).
local function complete(system, text, onDone, fallback)
  local key = apiKey() or M.askKey()
  if not key then return onDone(nil, "No OpenRouter API key") end
  local body = hs.json.encode({
    model = MODEL, provider = fallback and FALLBACK_PROVIDER or PROVIDER, reasoning = { enabled = false },
    temperature = 0.2, max_tokens = 4000,
    messages = { { role = "system", content = system }, { role = "user", content = text } },
  })
  hs.http.asyncPost("https://openrouter.ai/api/v1/chat/completions", body,
    { Authorization = "Bearer " .. key, ["Content-Type"] = "application/json" },
    function(status, resp)
      local ok, j = pcall(hs.json.decode, resp or "")
      local reply = ok and type(j) == "table" and j.choices and j.choices[1] and j.choices[1].message and j.choices[1].message.content
      if status == 200 and type(reply) == "string" and reply:match("%S") then return onDone(reply) end
      if status == 401 then M.key = nil; local k = M.askKey("OpenRouter refused that key."); if k then return complete(system, text, onDone, fallback) end end
      if not fallback and (status == 429 or status >= 500 or status < 0) then return complete(system, text, onDone, true) end
      local err = ok and type(j) == "table" and j.error and j.error.message or ("HTTP " .. tostring(status))
      onDone(nil, err)
    end)
end

-- Keep the connection warm: a tiny request every 45 s, and on the first Return of a possible triple Return.
function M.warm()
  local key = apiKey(); if not key then return end
  hs.http.asyncGet("https://openrouter.ai/api/v1/key", { Authorization = "Bearer " .. key }, function() end)
end

-- The model sometimes wraps its reply in a code fence or backticks; strip a wrapper around the whole reply.
local function unwrap(t)
  t = t:gsub("^%s+", ""):gsub("%s+$", "")
  return t:match("^```[%w%-]*\n(.-)\n?```$") or t:match("^`([^`\n]+)`$") or t
end

local HTML_RULE = [[

The text contains markers like ⟦0⟧, ⟦1⟧, ⟦2⟧ standing for formatting and images. Keep every marker exactly as
written, in the same order and in the same place relative to the words around it; never add, drop, renumber or
move one. Keep HTML entities such as &amp; and &nbsp; as they are.]]

local TRANSIENT = "org.nspasteboard.TransientType"
local function snapshotClipboard() return hs.pasteboard.readAllData() or {} end
local function restoreClipboard(snap)
  if snap and next(snap) then hs.pasteboard.writeAllData(snap) else hs.pasteboard.clearContents() end
end
-- Keys sent from here are tagged, so the typing hold below lets them through (and other taps can tell them apart).
local MINE = 0x736d6f6f
local SRC = hs.eventtap.event.properties.eventSourceUserData
local function key(mods, k)
  for _, down in ipairs({ true, false }) do
    local e = hs.eventtap.event.newKeyEvent(mods, k, down)
    e:setProperty(SRC, MINE); e:post()
  end
end

-- You can keep typing while a fix is on its way. Only the moment the paragraph is swapped (≈0.1 s) holds your
-- keystrokes, which are then replayed in order, so nothing lands inside the selection being replaced.
local held
M.holdTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp }, function(e)
  if not held or e:getProperty(SRC) == MINE then return false end
  held[#held + 1] = e:copy()
  return true
end)
local function hold()
  held = held or {}
  M.holdTap:start()
  M.holdSafety = hs.timer.doAfter(2, function() if held then M.releaseTyping() end end)
end
function M.releaseTyping()
  local evs = held or {}
  held = nil
  M.holdTap:stop()
  if M.holdSafety then M.holdSafety:stop(); M.holdSafety = nil end
  for _, e in ipairs(evs) do e:post() end
end

-- Typing tracker: the paragraph you're typing, rebuilt from your keystrokes, so a fix in a browser can start without
-- selecting anything. Anything it can't follow (arrows, a click, a paste, ⌘/⌃ shortcuts, ⌥⌫, switching apps)
-- marks it unreliable until the next line break, and the fix then reads the field the old way.
local T = { buf = "", lastPara = nil, ok = true, after = nil, afterOk = true }
M.typing = T
local KC = hs.keycodes.map
local function popChar(str)
  local last = utf8.offset(str, -1)
  return last and str:sub(1, last - 1) or str
end
M.trackTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown, hs.eventtap.event.types.leftMouseDown }, function(e)
  if e:getType() == hs.eventtap.event.types.leftMouseDown then T.ok = false; T.afterOk = false; return false end
  if e:getProperty(SRC) == MINE then return false end
  local code, f = e:getKeyCode(), e:getFlags()
  if f.cmd or f.ctrl or f.fn then T.ok = false; T.afterOk = false; return false end
  if code == KC["return"] then
    if T.after then T.after = T.after .. "\n" end
    if T.buf:match("%S") then T.lastPara, T.lastOk = T.buf, T.ok end
    T.buf = ""; T.ok = true
    return false
  end
  if code == KC.delete then
    if f.alt then T.ok = false; T.afterOk = false; return false end
    if T.buf == "" then T.ok = false else T.buf = popChar(T.buf) end
    if T.after then if T.after == "" then T.afterOk = false else T.after = popChar(T.after) end end
    return false
  end
  if code == KC.left or code == KC.right or code == KC.up or code == KC.down or code == KC.tab
     or code == KC.forwarddelete or code == KC.home or code == KC["end"] or code == KC.pageup or code == KC.pagedown then
    T.ok = false; T.afterOk = false; return false
  end
  local ch = e:getCharacters(false)
  if ch and ch ~= "" and not ch:find("[%c]") then
    T.buf = T.buf .. ch
    if T.after then T.after = T.after .. ch end
  end
  return false
end):start()
M.trackApps = hs.application.watcher.new(function(_, ev) if ev == hs.application.watcher.activated then T.ok = false; T.lastOk = false; T.buf = "" end end):start()

-- Paste over the selection from a transient entry, then put the user's clipboard back.
local function pasteTransient(data)
  local snap = snapshotClipboard()
  data[TRANSIENT] = ""
  hs.pasteboard.writeAllData(data)
  key({ "cmd" }, "v")
  M.restoreTimer = hs.timer.doAfter(0.4, function() restoreClipboard(snap) end)
end

-- UTF-16 offsets (Accessibility) <-> byte offsets (Lua strings)
local function bytesForUnits(s, units)
  local u = 0
  for pos, cp in utf8.codes(s) do
    if u >= units then return pos - 1 end
    u = u + (cp > 0xFFFF and 2 or 1)
  end
  return #s
end
local function unitsOf(s)
  local u = 0
  for _, cp in utf8.codes(s) do u = u + (cp > 0xFFFF and 2 or 1) end
  return u
end

-- Line breaks are kept exactly, not left to the model (it merged a blank line between paragraphs into a single
-- break, 2026-10-22): runs of line breaks are taken out, the lines go to the model one per line, and the original
-- runs go back between the fixed lines. If the reply doesn't have the same number of lines, it's used as is.
local function splitLines(body)
  local lines, seps, i = {}, {}, 1
  while true do
    local a, b = body:find("\n+", i)
    if not a then lines[#lines + 1] = body:sub(i); break end
    lines[#lines + 1] = body:sub(i, a - 1); seps[#seps + 1] = body:sub(a, b); i = b + 1
  end
  return lines, seps
end
local function rejoin(reply, lines, seps)
  local got = {}
  for l in (reply .. "\n"):gmatch("(.-)\n+") do got[#got + 1] = l end
  if #got ~= #lines then
    windows.wlog("fix typos: reply has %d lines for %d sent, using it as is", #got, #lines)
    return reply
  end
  local out = {}
  for k, l in ipairs(got) do out[#out + 1] = l; if seps[k] then out[#out + 1] = seps[k] end end
  return table.concat(out)
end

-- Ask the model for the fixed version of `text` (only the part after the last fix); onDone(fixed) or nothing.
local function fixText(text, onDone, onFail)
  local done = M.lastFixed and #M.lastFixed > 0 and text:sub(1, #M.lastFixed) == M.lastFixed and M.lastFixed or ""
  local new = text:sub(#done + 1)
  if new:match("^%s*$") then onFail(); return hs.alert.show("Already fixed", 1) end
  local lead, body, trail = new:match("^(%s*)(.-)(%s*)$")
  local lines, seps = splitLines(body)
  local alert = hs.alert.show("Fixing typos…", 10)
  complete(PROMPT, table.concat(lines, "\n"), function(reply)
    hs.alert.closeSpecific(alert)
    if not reply then return onFail() end
    local fixed = done .. lead .. rejoin(unwrap(reply), lines, seps) .. trail
    M.lastFixed = fixed
    onDone(fixed)
  end)
end

local function fixHTML(html)
  local tags = {}
  local marked = html:gsub("<[^>]*>", function(t) tags[#tags + 1] = t; return "⟦" .. (#tags - 1) .. "⟧" end)
  -- (with an image in the paragraph the selection stays up during the request, so typing is held until it's done)
  hold()
  local function giveUp(msg) key({}, "right"); M.releaseTyping(); hs.alert.show(msg, 2) end
  local alert = hs.alert.show("Fixing typos…", 10)
  complete(PROMPT .. HTML_RULE, marked, function(reply)
    hs.alert.closeSpecific(alert)
    if not reply then return giveUp("Typo fix failed: nothing changed") end
    reply = unwrap(reply)
    local i = 0
    for n in reply:gmatch("⟦(%d+)⟧") do
      if tonumber(n) ~= i then return giveUp("Couldn't fix it without touching the image: nothing changed") end
      i = i + 1
    end
    if i ~= #tags then return giveUp("Couldn't fix it without touching the image: nothing changed") end
    local fixed = reply:gsub("⟦(%d+)⟧", function(n) return tags[tonumber(n) + 1] end)
    local plain = fixed:gsub("<br[^>]*>", "\n"):gsub("</div>", "\n"):gsub("</p>", "\n"):gsub("<[^>]*>", "")
                       :gsub("&nbsp;", " "):gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&quot;", '"'):gsub("&amp;", "&")
    M.lastFixed = nil
    pasteTransient({ ["public.html"] = fixed, ["public.utf8-plain-text"] = plain })
    hs.timer.doAfter(0.12, M.releaseTyping)
  end)
end

-- Native text views: read the paragraph before the caret from AXValue and leave the caret where it is (keep
-- typing). When the fix arrives, check the paragraph is still there unchanged, select exactly it, set
-- AXSelectedText, and put the caret back after whatever was typed meanwhile.
-- Returns false when the field doesn't support it (then the keyboard path runs instead).
-- opts.trailingBreaks: the caret sits after line breaks a triple Return just typed; they're replaced too (removed),
-- so nothing has to delete them first (Electron apps like Slack applied the deletes late and the paragraph
-- before the caret read as empty).
local function fixViaAX(el, opts)
  local value, r = el:attributeValue("AXValue"), el:attributeValue("AXSelectedTextRange")
  if type(value) ~= "string" or type(r) ~= "table" or not r.location then return false end
  if not el:isAttributeSettable("AXSelectedTextRange") then return false end
  local caret = bytesForUnits(value, r.location + (r.length or 0))
  local prefix = value:sub(1, caret)
  local trimmed = prefix:gsub("%s+$", "")   -- the paragraph is the last one with text in it
  local start = (trimmed:match(".*()\n") or 0) + 1
  local para = trimmed:sub(start)
  -- Empty here doesn't mean the field is empty: some Electron editors (Linear) report a blank or partial AXValue.
  -- Let the keyboard path select the paragraph instead.
  if not para:match("%S") then return false end
  local covered = opts.trailingBreaks and prefix:sub(start) or para
  local range = { location = unitsOf(value:sub(1, start - 1)), length = unitsOf(covered) }
  fixText(para, function(fixed)
    hold()
    local now = el:attributeValue("AXValue")
    if type(now) ~= "string" or now:sub(start, start + #covered - 1) ~= covered then
      M.releaseTyping()
      return hs.alert.show("The paragraph changed meanwhile: nothing replaced", 2)
    end
    local cur = el:attributeValue("AXSelectedTextRange")
    el:setAttributeValue("AXSelectedTextRange", range)
    el:setAttributeValue("AXSelectedText", fixed)
    local after = el:attributeValue("AXValue")
    if after == now then pasteTransient({ ["public.utf8-plain-text"] = fixed }) end   -- setter ignored: paste instead
    hs.timer.doAfter(after == now and 0.1 or 0, function()
      -- caret back where you were typing, shifted by the length change
      if type(cur) == "table" and cur.location and cur.location >= range.location + range.length then
        local loc = cur.location + unitsOf(fixed) - range.length
        el:setAttributeValue("AXSelectedTextRange", { location = loc, length = cur.length or 0 })
      end
      M.releaseTyping()
    end)
  end, function() end)
  return true
end

-- The current selection's text: Accessibility when it looks real (editors that draw their own text, like Google
-- Docs, report a placeholder; an image shows up as U+FFFC), else a copy with the clipboard put back right away.
-- cb(text, html)
local function readSelection(el, cb)
  local sel = el and el:attributeValue("AXSelectedText")
  if type(sel) == "string" and #sel > 2 and not sel:find("\xEF\xBF\xBC", 1, true) then return cb(sel, nil) end
  local snap = snapshotClipboard()
  local before = hs.pasteboard.changeCount()
  key({ "cmd" }, "c")
  local tries = 0
  M.fixTimer = hs.timer.doEvery(0.01, function()
    tries = tries + 1
    if hs.pasteboard.changeCount() == before and tries < 30 then return end
    M.fixTimer:stop(); M.fixTimer = nil
    local copied = hs.pasteboard.changeCount() ~= before
    local text = copied and (hs.pasteboard.getContents() or "") or ""
    local html = copied and hs.pasteboard.readDataForUTI(nil, "public.html")
    restoreClipboard(snap)
    cb(text, html)
  end)
end

-- Keyboard path, when the fix arrives: select back to the paragraph (⌥⇧↑, twice if you've started a new one),
-- find the original text in the selection and paste the fix in its place, keeping what you typed after it.
local function replaceTyped(el, orig, fixed, presses)
  presses = presses or 1
  key({ "alt", "shift" }, "up")
  hs.timer.doAfter(0.04, function()
    readSelection(el, function(cur)
      cur = cur or ""
      local p
      local from = 1
      while true do   -- the last occurrence: the paragraph nearest the caret
        local q = cur:find(orig, from, true)
        if not q then break end
        p = q; from = q + 1
      end
      if p then
        -- Shrink the selection so it starts at the paragraph itself (⇧→ moves its start, one character per press):
        -- re-pasting the blank lines above it as plain text collapsed them.
        local before = cur:sub(1, p - 1)
        local n = 0
        for _ in utf8.codes(before) do n = n + 1 end
        for _ = 1, n do key({ "shift" }, "right") end
        hs.timer.doAfter(n > 0 and 0.04 or 0, function()
          pasteTransient({ ["public.utf8-plain-text"] = fixed .. cur:sub(p + #orig) })
          hs.timer.doAfter(0.12, M.releaseTyping)
        end)
        return
      end
      if presses < 2 then return replaceTyped(el, orig, fixed, presses + 1) end
      key({}, "right")
      M.releaseTyping()
      hs.alert.show("The paragraph changed meanwhile: nothing replaced", 2)
    end)
  end)
end

-- Text selected when Hyper-W is pressed: fix exactly the selection, however many paragraphs. You chose it, so it stays
-- selected and typing is held until the fix is in.
-- Whitespace at the edges of the selection (a triple-click takes the paragraph's line break with it) is never
-- replaced: apps dropped a trailing break when the fix went in, joining two paragraphs.
local function fixSelection(el, browser, text)
  hold()
  local lead, body, trail = text:match("^(%s*)(.-)(%s*)$")
  M.lastFixed = nil
  fixText(body, function(fixed)
    local before = el:attributeValue("AXValue")
    local r = el:attributeValue("AXSelectedTextRange")
    -- Line breaks are pasted, never written through Accessibility: Linear's editor dropped them that way, running
    -- three paragraphs into one (2026-10-22). A paste goes through the editor's own paragraph handling.
    if not browser and not fixed:find("\n") and el:isAttributeSettable("AXSelectedText") and type(r) == "table" and r.location then
      el:setAttributeValue("AXSelectedTextRange", { location = r.location + unitsOf(lead), length = unitsOf(body) })
      el:setAttributeValue("AXSelectedText", fixed)
      if el:attributeValue("AXValue") == before then pasteTransient({ ["public.utf8-plain-text"] = fixed }) end
      return hs.timer.doAfter(0.12, M.releaseTyping)
    end
    -- browsers: pull the end of the selection back over the trailing whitespace (⇧←), if the selection runs that way
    local n = 0
    for _ in utf8.codes(trail) do n = n + 1 end
    for _ = 1, n do key({ "shift" }, "left") end
    hs.timer.doAfter(n > 0 and 0.04 or 0, function()
      local now = el:attributeValue("AXSelectedText")
      local paste = lead .. fixed
      if n > 0 and now ~= lead .. body then   -- it ran the other way (or can't be read): undo, and paste the edges too
        for _ = 1, n do key({ "shift" }, "right") end
        paste = lead .. fixed .. trail
      end
      hs.timer.doAfter(n > 0 and 0.04 or 0, function()
        pasteTransient({ ["public.utf8-plain-text"] = paste })
        hs.timer.doAfter(0.12, M.releaseTyping)
      end)
    end)
  end, function() M.releaseTyping() end)
end

function M.run(opts)
  opts = opts or {}
  local front = hs.application.frontmostApplication()
  local browser = front and BROWSERS[front:bundleID() or ""]
  local el = hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")
  if not opts.trailingBreaks and el then
    local sel = el:attributeValue("AXSelectedText")
    -- (2 characters or fewer: web editors that draw their own text report a placeholder, not the selection)
    if type(sel) == "string" and #sel > 2 and sel:match("%S") then
      windows.wlog("fix typos: %s, %d chars selected, fixing the selection", front and front:bundleID() or "?", #sel)
      M.lastFixed = nil
      if sel:find("\xEF\xBF\xBC", 1, true) then   -- an image in it: fix through the HTML
        return readSelection(el, function(text, html)
          if html and (html:find("<img", 1, true) or html:find("<video", 1, true) or html:find("<iframe", 1, true)) then return fixHTML(html) end
          fixSelection(el, browser, text)
        end)
      end
      return fixSelection(el, browser, sel)
    end
  end
  windows.wlog("fix typos: %s, role %s, %s", front and front:bundleID() or "?", el and tostring(el:attributeValue("AXRole")) or "none",
               browser and "keyboard path" or "accessibility path")
  if el and not browser and fixViaAX(el, opts) then return end
  if el and not browser then windows.wlog("fix typos: accessibility gave no paragraph (AXValue %d chars), using the keyboard",
                                          #(tostring(el:attributeValue("AXValue") or ""))) end
  -- Tracked path (no selection until the fix is back): the paragraph comes from the typing tracker.
  local para, paraOk
  if opts.trailingBreaks then para, paraOk = T.lastPara, T.lastOk and T.buf == ""
  else para, paraOk = T.buf, T.ok end
  if para and paraOk and para:match("%S") then
    windows.wlog("fix typos: tracked paragraph (%d chars), no selection", #para)
    if opts.trailingBreaks then key({}, "delete"); key({}, "delete") end   -- the two line breaks, right away
    T.after, T.afterOk = "", true
    local orig = para
    return fixText(orig, function(fixed)
      local after, afterOk = T.after or "", T.afterOk
      T.after = nil
      hold()
      if not afterOk then return replaceTyped(el, orig, fixed) end   -- lost track meanwhile: find it the old way
      -- select back over the paragraph and what you typed since, check it, paste the fix + your new text
      local n = 0
      for _ in utf8.codes(orig .. after) do n = n + 1 end
      for _ = 1, n do key({ "shift" }, "left") end
      hs.timer.doAfter(0.05, function()
        local sel = el and el:attributeValue("AXSelectedText")
        if type(sel) == "string" and sel ~= orig .. after and #sel > 2 then
          key({}, "right"); M.releaseTyping()
          windows.wlog("fix typos: tracked text didn't match the field, nothing replaced")
          return hs.alert.show("The paragraph changed meanwhile: nothing replaced", 2)
        end
        pasteTransient({ ["public.utf8-plain-text"] = fixed .. after })
        hs.timer.doAfter(0.12, M.releaseTyping)
      end)
    end, function() T.after = nil end)
  end
  -- Keyboard path: delete a triple Return's line breaks, select back to the start of the paragraph, read it,
  -- and put the caret straight back so you can keep typing while the fix is on its way.
  hold()   -- just for the read (≈0.1 s)
  local settle = 0.03
  if opts.trailingBreaks then
    key({}, "delete"); key({}, "delete")
    settle = 0.12   -- let the page apply the deletes before selecting
  end
  hs.timer.doAfter(settle - 0.03, function() key({ "alt", "shift" }, "up") end)
  hs.timer.doAfter(settle, function()
    readSelection(el, function(text, html)
      if html and (html:find("<img", 1, true) or html:find("<video", 1, true) or html:find("<iframe", 1, true)) then
        M.releaseTyping()
        return fixHTML(html)   -- keeps the selection and holds typing until it's done
      end
      key({}, "right")   -- deselect: caret back at the end of the paragraph
      M.releaseTyping()
      if not text:match("%S") then return hs.alert.show("Nothing to fix", 1) end
      -- the selection can start in the blank line(s) above the paragraph: those are never sent or replaced
      local orig = text:gsub("^%s+", "")
      fixText(orig, function(fixed) hold(); replaceTyped(el, orig, fixed) end, function() end)
    end)
  end)
end


local function startTripleReturn()
  if M.tap then M.tap:stop() end
  local WINDOW = 0.6   -- seconds for all three presses
  local RETURN = hs.keycodes.map["return"]
  local presses = {}

  local SRC, MINE = hs.eventtap.event.properties.eventSourceUserData, 0x736d6f6f   -- keys sent by this module

  -- Single-line fields (search boxes, titles) submit on Return and on Shift+Return, so there a Shift+Return waits
  -- WINDOW seconds: two more make a triple (fix, nothing submitted); otherwise it goes through, just late.
  local pendingShift, shiftTimer = 0, nil
  local function sendShiftReturns(n)
    for _ = 1, n do
      for _, down in ipairs({ true, false }) do
        local e = hs.eventtap.event.newKeyEvent({ "shift" }, "return", down)
        e:setProperty(SRC, MINE); e:post()
      end
    end
  end

  local function focusedRole()
    local el = hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")
    return el and el:attributeValue("AXRole")
  end

  M.tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(e)
    if e:getProperty(SRC) == MINE then return false end
    if e:getKeyCode() ~= RETURN then presses = {}; return false end
    local f = e:getFlags()
    if f.cmd or f.ctrl or f.alt or f.fn then presses = {}; return false end   -- Shift is fine: Shift+Return is a line break in chat apps
    if e:getProperty(hs.eventtap.event.properties.keyboardEventAutorepeat) ~= 0 then return false end
    if f.shift then
      local role = focusedRole()
      if role == "AXTextField" or role == "AXComboBox" then
        pendingShift = pendingShift + 1
        if shiftTimer then shiftTimer:stop(); shiftTimer = nil end
        if pendingShift == 1 then M.warm() end
        if pendingShift >= 3 then
          pendingShift = 0
          hs.timer.doAfter(0, function() M.run({}) end)
          return true
        end
        shiftTimer = hs.timer.doAfter(WINDOW, function() local n = pendingShift; pendingShift = 0; shiftTimer = nil; sendShiftReturns(n) end)
        return true
      end
    end
    local now = hs.timer.secondsSinceEpoch()
    presses[#presses + 1] = now
    while #presses > 0 and now - presses[1] > WINDOW do table.remove(presses, 1) end
    if #presses == 1 then M.warm() end   -- a triple Return may be coming: make sure the connection is open
    if #presses < 3 then return false end
    presses = {}
    local role = focusedRole()
    if role ~= "AXTextArea" and role ~= "AXTextField" and role ~= "AXComboBox" then
      wlog("triple Return ignored: focused role %s", tostring(role))
      return false
    end
    -- a multi-line field took the first two Returns as line breaks: the fix replaces them along with the paragraph
    hs.timer.doAfter(0, function() M.run({ trailingBreaks = role == "AXTextArea" }) end)
    return true
  end):start()

  -- macOS turns an event tap off if Hammerspoon stalls for a moment; turn it back on.
  if M.tapWatchdog then M.tapWatchdog:stop() end
  M.tapWatchdog = hs.timer.doEvery(3, function()
    for _, tp in ipairs({ M.tap, M.trackTap }) do if tp and not tp:isEnabled() then tp:start() end end
  end)
end

function M.start(opts)
  opts = opts or {}
  local hk = opts.hotkey or { { "cmd", "alt", "ctrl", "shift" }, "w" }
  if M.hotkey then M.hotkey:delete() end
  M.hotkey = hs.hotkey.bind(hk[1], hk[2], function() M.run() end)
  if opts.tripleReturn ~= false then startTripleReturn() elseif M.tap then M.tap:stop(); M.tap = nil end
  if M.warmTimer then M.warmTimer:stop() end
  M.warmTimer = hs.timer.doEvery(45, M.warm)
  if opts.autoLaunch ~= false then hs.autoLaunch(true) end
  return M
end

return M
