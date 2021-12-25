-- -----------------------------------------------------------------------
--           ** HammerSpoon Config File by S1ngS1ng with ❤️ **           --
-- -----------------------------------------------------------------------

--   ***   Please refer to README.MD for instructions. Cheers!    ***   --

-- -----------------------------------------------------------------------
--                         ** Something Global **                       --
-- -----------------------------------------------------------------------
-- Uncomment this following line if you don't wish to see animations
-- hs.window.animationDuration = 0

-- -----------------------------------------------------------------------
--                            ** Requires **                            --
-- -----------------------------------------------------------------------
require ("window-management")
require ("vim-binding")
require ("key-binding")

fw = hs.window.focusedWindow
hs.application.enableSpotlightForNameSearches(true)
-- -----------------------------------------------------------------------
--                            ** For Debug **                           --
-- -----------------------------------------------------------------------
function reloadConfig(files)
  local doReload = false
  for _,file in pairs(files) do
    if file:sub(-4) == ".lua" then
      doReload = true
    end
  end
  if doReload then
    hs.reload()
    hs.alert.show('Config Reloaded')
  end
end
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()

-- Well, sometimes auto-reload is not working, you know u.u
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "r", function()
  hs.reload()
end)
hs.alert.show("Config loaded")

--
-- zk@20191212
--
appmod = {"cmd", "ctrl"}
applist = {
    {shortcut = 'c', appname = 'Google Chrome'},
    {shortcut = 'f', appname = 'Finder'},
    {shortcut = 'j', appname = 'IntelliJ IDEA'},
    {shortcut = 't', appname = 'iTerm2'},
    {shortcut = 'w', appname = 'WeChat'},
    {shortcut = 'x', appname = 'WeChat'},
    {shortcut = 'q', appname = 'QQ'},
    {shortcut = 's', appname = 'System Preferences'},
    {shortcut = 'p', appname = 'Activity Monitor'},
}


hs.fnutils.each(applist, function(item)
    hs.hotkey.bind(appmod, item.shortcut, item.appname, function() activateApp(item.appname) end)
end)

function activateApp(appname)
    launchOrCycleFocus(appname)()
    local app = hs.application.find(appname)
    if app then
        app:activate()
        hs.timer.doAfter(0.1, highlightActiveWin)
        app:unhide()
    end
end

-- Needed to enable cycling of application windows
lastToggledApplication = ''

function launchOrCycleFocus(applicationName)
  return function()
    local nextWindow = nil
    local targetWindow = nil
    local focusedWindow          = hs.window.focusedWindow()
    local lastToggledApplication = focusedWindow and focusedWindow:application():name()

    if not focusedWindow then return nil end
    if lastToggledApplication == applicationName then
      nextWindow = getNextWindow(applicationName, focusedWindow)
      -- Becoming main means
      -- * gain focus (although docs say differently?)
      -- * next call to launchOrFocus will focus the main window <- important
      -- * when fetching allWindows() from an application mainWindow will be the first one
      --
      -- If we have two applications, each with multiple windows
      -- i.e:
      --
      -- Google Chrome: {window1} {window2}
      -- Firefox:       {window1} {window2} {window3}
      --
      -- and we want to move between Google Chrome {window2} and Firefox {window3}
      -- when pressing the hotkeys for those applications, then using becomeMain
      -- we cycle until those windows (i.e press hotkey twice for Chrome) have focus
      -- and then the launchOrFocus will trigger that specific window.
      nextWindow:becomeMain()
      nextWindow:focus()
    else
      hs.application.launchOrFocus(applicationName)
    end

    if nextWindow then
      targetWindow = nextWindow
    else
      targetWindow = hs.window.focusedWindow()
    end

    if not targetWindow then
      return nil
    end
  end
end

function getNextWindow(windows, window)
  if type(windows) == "string" then
    windows = hs.application.find(windows):allWindows()
  end

  windows = hs.fnutils.filter(windows, hs.window.isStandard)
  windows = hs.fnutils.filter(windows, hs.window.isVisible)

  -- need to sort by ID, since the default order of the window
  -- isn't usable when we change the mainWindow
  -- since mainWindow is always the first of the windows
  -- hence we would always get the window succeeding mainWindow
  table.sort(windows, function(w1, w2)
    return w1:id() > w2:id()
  end)

  lastIndex = hs.fnutils.indexOf(windows, window)
  if not lastIndex then return window end

  return windows[getNextIndex(windows, lastIndex)]
end

-- Fetch next index but cycle back when at the end
--
-- > getNextIndex({1,2,3}, 3)
-- 1
-- > getNextIndex({1}, 1)
-- 1
-- @return int
local function getNextIndex(table, currentIndex)
  nextIndex = currentIndex + 1
  if nextIndex > #table then
    nextIndex = 1
  end

  return nextIndex
end

function highlightActiveWin()
    if fw() then
        local rect = hs.drawing.rectangle(fw():frame())
        rect:setStrokeColor({["red"]=1,  ["blue"]=0, ["green"]=1, ["alpha"]=1})
        rect:setStrokeWidth(5)
        rect:setFill(false)
        rect:show()
        hs.timer.doAfter(0.3, function() rect:delete() end)
    end
end

globalGC = hs.timer.doEvery(180, collectgarbage)
