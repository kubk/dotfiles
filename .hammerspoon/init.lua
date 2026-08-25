-- In Apple Mail only, make Command-V paste text without source formatting.
-- Images, files, every other shortcut, and every other application are untouched.

local mailBundleID = "com.apple.mail"

local function clipboardContainsFile()
  for _, contentType in ipairs(hs.pasteboard.contentTypes() or {}) do
    if contentType == "public.file-url"
      or contentType == "NSFilenamesPboardType"
    then
      return true
    end
  end

  return false
end

local mailPasteHotkey

local function sendNormalPaste()
  -- Prevent the synthetic Command-V below from triggering this hotkey again.
  mailPasteHotkey:disable()
  hs.eventtap.keyStroke({ "cmd" }, "v", 0)
  mailPasteHotkey:enable()
end

mailPasteHotkey = hs.hotkey.new({ "cmd" }, "v", function()
  local availableTypes = hs.pasteboard.typesAvailable()

  -- Let Mail handle screenshots, copied images, and files normally.
  if availableTypes.image or clipboardContainsFile() then
    sendNormalPaste()
    return
  end

  local plainText = hs.pasteboard.readString()

  if not plainText then
    sendNormalPaste()
    return
  end

  -- Give Mail only the plain-text representation, just as if the text had
  -- been copied from a browser address bar.
  hs.pasteboard.setContents(plainText)
  sendNormalPaste()
end)

local function updateMailPasteHotkey(application)
  if application and application:bundleID() == mailBundleID then
    mailPasteHotkey:enable()
  else
    mailPasteHotkey:disable()
  end
end

-- Own Command-V only while Mail is the frontmost application. This leaves all
-- existing shortcuts in every other application completely untouched.
mailPasteApplicationWatcher = hs.application.watcher.new(function(_, eventType, application)
  if eventType == hs.application.watcher.activated then
    updateMailPasteHotkey(application)
  end
end)

mailPasteApplicationWatcher:start()
updateMailPasteHotkey(hs.application.frontmostApplication())
