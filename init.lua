-- >> ENV FILE LOADER
-- Load environment variables from .env file
local function loadEnvFile()
    local envPath = os.getenv("HOME") .. "/.hammerspoon/.env"
    local envVars = {}
    
    local file = io.open(envPath, "r")
    if file then
        for line in file:lines() do
            -- Skip empty lines and comments
            line = line:match("^%s*(.-)%s*$") -- trim whitespace
            if line ~= "" and not line:match("^#") then
                local key, value = line:match("^([^=]+)=(.+)$")
                if key and value then
                    key = key:match("^%s*(.-)%s*$") -- trim key
                    value = value:match("^%s*(.-)%s*$") -- trim value
                    -- Remove quotes if present
                    if value:match('^".*"$') or value:match("^'.*'$") then
                        value = value:sub(2, -2)
                    end
                    envVars[key] = value
                end
            end
        end
        file:close()
    end
    
    return envVars
end

-- Load .env file and create a getter function
local envVars = loadEnvFile()
local function getEnv(key)
    -- First check .env file, then fallback to system environment
    return envVars[key] or os.getenv(key) or ""
end
-- << ENV FILE LOADER

-- >> RUPEE SYMBOL HOTKEY
-- Replace Option+4 with ₹ symbol
local function insertRupeeSymbol()
    hs.eventtap.keyStrokes("₹")
end

hs.hotkey.bind({"alt"}, "4", insertRupeeSymbol)

-- require("hs.ipc")
hs.ipc.cliInstall()
-- Customize the alert appearance
hs.alert.defaultStyle.strokeColor = { white = 1, alpha = 0.20 }
hs.alert.defaultStyle.fillColor = { white = 0, alpha = 0.6 }
hs.alert.defaultStyle.textColor = { white = 1, alpha = .9 }
hs.alert.defaultStyle.textSize = 32
hs.alert.defaultStyle.radius = 16
hs.alert.defaultStyle.fadeInDuration = 0.15
hs.alert.defaultStyle.fadeOutDuration = .5
hs.alert.defaultStyle.padding = 24

-- >> SIGNAL LOCK
-- Set the password hash and time limit
-- Store the SHA256 hash of your password in .env file as HS_SIGNAL_PASSWORD_HASH
-- Example: echo -n 'yourpassword' | shasum -a 256 | awk '{print $1}'
local passwordHash = getEnv("HS_SIGNAL_PASSWORD_HASH")
if passwordHash == "" then
    hs.alert.show("Warning: HS_SIGNAL_PASSWORD_HASH not set in .env")
end
local passwordEntered = false
local lastPasswordTime = 0
local timeLimit = 3600000000000 -- 1 hour in nanoseconds (Hammerspoon uses nanoseconds for timers)
local isPromptOpen = false -- Flag to check if prompt is already open

-- Function to prompt for the password
function promptForPassword()
    -- Prevent multiple prompts
    if isPromptOpen then return end
    isPromptOpen = true

    local hideTimer = nil
    local function enforceFocusAndHide()
        if signalApp then
            signalApp:hide()
        end
        local frontApp = hs.application.frontmostApplication()
        if frontApp and frontApp:name() ~= "Hammerspoon" then
            local hsApp = hs.application.get("Hammerspoon")
            if hsApp then
                hsApp:activate(true)
            else
                hs.application.launchOrFocus("Hammerspoon")
            end
        end
    end

    -- Start a timer to continuously hide Signal and keep Hammerspoon focused while the prompt is open
    hideTimer = hs.timer.doEvery(0.05, enforceFocusAndHide)

    -- Give initial focus to Hammerspoon before showing the dialog
    local hsApp = hs.application.get("Hammerspoon")
    if hsApp then
        hsApp:activate(true)
    else
        hs.application.launchOrFocus("Hammerspoon")
    end
    hs.timer.usleep(150000)

    -- Show the password prompt
    local button, input = hs.dialog.textPrompt("Password Required", "Please enter the password to continue:", "", "OK", "Cancel", true)   
    
    -- Hash the input and compare with stored hash
    if button == "OK" and input ~= "" and hs.hash.SHA256(input) == passwordHash then
        passwordEntered = true
        lastPasswordTime = hs.timer.absoluteTime()
        -- Stop the hiding timer
        if hideTimer then
            hideTimer:stop()
        end
        -- Unhide and activate Signal if it was hidden
        if signalApp then
            signalApp:unhide()
            signalApp:activate()
        else
            hs.application.launchOrFocus("Signal")
        end
    else
        hs.alert.show("Incorrect password. Access denied.")
    end

    -- Stop the hiding timer if it's still running
    if hideTimer then
        hideTimer:stop()
    end

    -- Reset the prompt flag
    isPromptOpen = false
end

-- Function to handle application events
function appWatcher(appName, eventType, app)
    if signalApp and not passwordEntered then
        signalApp:hide()
    end
    if appName == "Signal" then
        signalApp = app -- Store the reference to the Signal app

        -- Hide the application immediately upon launch or activation
        if eventType == hs.application.watcher.launched or eventType == hs.application.watcher.activated then
            if not passwordEntered or (hs.timer.absoluteTime() - lastPasswordTime > timeLimit) then
                signalApp:hide()
                hs.timer.doAfter(.5, function()
                    promptForPassword()
                end)
            end
        elseif eventType == hs.application.watcher.terminated then
            -- Reset the flag when the application is closed
            passwordEntered = false
            signalApp = nil -- Clear the reference
        end
    end
end

-- Create an application watcher

appWatcher = hs.application.watcher.new(appWatcher)
appWatcher:start()

-- << SIGNAL LOCK

-- >> MUSIC
-- Bind the F7 key
hs.hotkey.bind({}, 'F7', function()
    local appName = 'YouTube Music'
    local appPath = '/Users/omshejul/Applications/Brave Browser Apps.localized/YouTube Music.app'
    local bundleID = 'com.brave.Browser.app.cinhimbnkkaeohfgghhklpknlkffjgod'

    local app = hs.application.get(bundleID)

    if not app then
        -- Launch YouTube Music using its path
        hs.application.open(appPath)
    else
        -- Send the Play/Pause media key globally
        hs.eventtap.event.newSystemKeyEvent('PLAY', true):post()
        hs.eventtap.event.newSystemKeyEvent('PLAY', false):post()
    end
end)
-- << MUSIC


-- >> SYNC PROGRESS
-- Define the menu bar icon

-- Function to display the icon
function showSyncIcon()
    syncMenu = hs.menubar.new()
    -- syncMenu:setIcon(hs.image.imageFromName("NSActionTemplate"))
    syncMenu:setTitle("🔄")
end

-- Function to remove the icon
function removeSyncIcon()
    syncMenu:removeFromMenuBar()
end
-- << SYNC PROGRESS

-- >> KEYBOARD PROGRESS
-- Define the menu bar icon for keyboard

-- Function to display the keyboard icon
function showKeyboardIcon()
    keyboardMenu = hs.menubar.new()
    keyboardMenu:setTitle("🅾️")
    keyboardMenu:setClickCallback(function()
        hs.eventtap.keyStroke({"cmd", "alt", "shift", "ctrl"}, "o")
    end)
end

-- Function to remove the keyboard icon
function removeKeyboardIcon()
    if keyboardMenu then
        keyboardMenu:delete()
        keyboardMenu = nil
    end
end

-- To run this command from the terminal:
-- hs -c "showKeyboardIcon()"
-- or
-- hs -c "removeKeyboardIcon()"
-- << KEYBOARD PROGRESS







-- >> PAGE UP/DOWN SCROLLING
-- Define the slow scroll function
function scrollSlowly(direction)
    local scrollAmount = 3  -- Change this value to adjust scroll speed
    if direction == "up" then
        hs.eventtap.scrollWheel({0, scrollAmount}, {}, "line")
    elseif direction == "down" then
        hs.eventtap.scrollWheel({0, -scrollAmount}, {}, "line")
    end
end

-- Bind Control + Page Up to slow scroll up
hs.hotkey.bind({"ctrl"}, "pageup", function()
    scrollSlowly("up")
end)

-- Bind Control + Page Down to slow scroll down
hs.hotkey.bind({"ctrl"}, "pagedown", function()
    scrollSlowly("down")
end)

-- Function to handle the cmd + esc key combination
function sendEnter()
    hs.eventtap.keyStroke({}, "return")
end
-- << PAGE UP/DOWN SCROLLING

-- Bind the sendEnter function to the cmd + esc hotkey
hs.hotkey.bind({"cmd"}, "escape", sendEnter)

-- Keep screen on time in hhmm format
local startTime = 0700
local endTime = 2100

-- Load necessary modules
local caffeinate = require "hs.caffeinate"
local menubar = require "hs.menubar"

-- Create a menubar item
local displayMenu = menubar.new()
displayMenu:setTitle("🔘")

-- Track the state of display sleep prevention and manual override
local displayAwake = false
local manualOverride = false

-- Function to update the menubar item based on the state
local function updateMenubar()
    if displayAwake then
        displayMenu:setTitle("✅")
        displayMenu:setTooltip("Click to allow display sleep")
    else
        displayMenu:setTitle("🔘")
        displayMenu:setTooltip("Click to prevent display sleep")
    end
end

-- Function to toggle display sleep prevention manually
function toggleDisplaySleep()
    manualOverride = true
    displayAwake = not displayAwake
    caffeinate.set("displayIdle", displayAwake, true)
    updateMenubar()
end

-- Function to enable display sleep prevention
function enableDisplaySleepPrevention()
    displayAwake = true
    caffeinate.set("displayIdle", displayAwake, true)
    updateMenubar()
end

-- Function to disable display sleep prevention
function disableDisplaySleepPrevention()
    displayAwake = false
    caffeinate.set("displayIdle", displayAwake, true)
    updateMenubar()
end

-- Function to check if current time is within the specified range
local function isWithinTimeRange()
    local currentTime = tonumber(os.date("%H%M"))
    if startTime < endTime then
        return currentTime >= startTime and currentTime < endTime
    else
        return currentTime >= startTime or currentTime < endTime
    end
end

-- Function to check the current time and update display sleep prevention
local function checkTimeAndUpdate()
    if (tonumber(os.date("%H")%3)== 0) then
        manualOverride = false
    end
    if not manualOverride then
        local shouldBeAwake = isWithinTimeRange()
        if displayAwake ~= shouldBeAwake then
            displayAwake = shouldBeAwake
            caffeinate.set("displayIdle", displayAwake, true)
            hs.alert.show("Display sleep prevention: " .. (displayAwake and "Enabled" or "Disabled"))
            updateMenubar()
        end
    end
end

-- Set the click callback function for the menubar item
displayMenu:setClickCallback(toggleDisplaySleep)

-- Timer to check every minute
-- local timer = hs.timer.doEvery(60, checkTimeAndUpdate)

-- Start the timer
-- timer:start()

-- Initial update to set the default state in the menu
-- checkTimeAndUpdate()


-- >> SPEAK WORD
hs.hotkey.bind({"ctrl", "alt", "cmd", "shift"}, "L", function()
    -- Command to execute your Python script
    local pythonScript = "/usr/local/bin/python3 -u ~/SavedMain/python/Assisto_PY/googleTTS/tts_all.py"
    
    -- Execute the script
    hs.execute(pythonScript, true)
end)
-- << SPEAK WORD


-- Function to search Google for selected text

function googleSearch(browserBundleID)
    local oldClipboard = hs.pasteboard.getContents()
    hs.eventtap.keyStroke({"cmd"}, "c")
    hs.timer.usleep(200000)

    local selectedText = hs.pasteboard.getContents()
    local url

    if selectedText:match("://") then
        url = selectedText
    elseif selectedText ~= "" then
        url = "http://www.google.com/search?q=" .. hs.http.encodeForQuery(selectedText)
    else
        url = "http://www.google.com"
    end

    if browserBundleID then
        hs.urlevent.openURLWithBundle(url, browserBundleID)
    else
        hs.urlevent.openURL(url)
    end
end

function perplexitySearch(browserBundleID)
    local oldClipboard = hs.pasteboard.getContents()
    hs.eventtap.keyStroke({"cmd"}, "c")
    hs.timer.usleep(200000)

    local selectedText = hs.pasteboard.getContents()
    local url

    if selectedText:match("://") then
        url = selectedText
    elseif selectedText ~= "" then
        url = "https://www.perplexity.ai/search?focus=internet&q=" .. hs.http.encodeForQuery(selectedText)
    else
        url = "https://www.perplexity.ai"
    end

    hs.urlevent.openURLWithBundle(url, browserBundleID)
end

function chatgptSearch(browserBundleID)
    local oldClipboard = hs.pasteboard.getContents()
    hs.eventtap.keyStroke({"cmd"}, "c")
    hs.timer.usleep(200000)

    local selectedText = hs.pasteboard.getContents()
    local url

    if selectedText:match("://") then
        url = selectedText
    elseif selectedText ~= "" then
        url = "https://chat.openai.com/?q=" .. hs.http.encodeForQuery(selectedText)
    else
        url = "https://chat.openai.com"
    end

    if browserBundleID then
        hs.urlevent.openURLWithBundle(url, browserBundleID)
    else
        hs.urlevent.openURL(url)
    end
end

function claudeSearch(browserBundleID)
    local oldClipboard = hs.pasteboard.getContents()
    hs.eventtap.keyStroke({"cmd"}, "c")
    hs.timer.usleep(200000)

    local selectedText = hs.pasteboard.getContents()
    local url

    if selectedText:match("://") then
        url = selectedText
    elseif selectedText ~= "" then
        url = "https://claude.ai/chat?q=" .. hs.http.encodeForQuery(selectedText)
    else
        url = "https://claude.ai"
    end

    if browserBundleID then
        hs.urlevent.openURLWithBundle(url, browserBundleID)
    else
        hs.urlevent.openURL(url)
    end
end

function googleAISearch(browserBundleID)
    local oldClipboard = hs.pasteboard.getContents()
    hs.eventtap.keyStroke({"cmd"}, "c")
    hs.timer.usleep(200000)

    local selectedText = hs.pasteboard.getContents()
    local url

    if selectedText:match("://") then
        url = selectedText
    elseif selectedText ~= "" then
        url = "https://www.google.com/search?q=" .. hs.http.encodeForQuery(selectedText) .. "&udm=50"
    else
        url = "https://www.google.com/search?udm=50"
    end

    if browserBundleID then
        hs.urlevent.openURLWithBundle(url, browserBundleID)
    else
        hs.urlevent.openURL(url)
    end
end

function ocrSearch(browserBundleID)
    local oldClipboard = hs.pasteboard.getContents()
    hs.eventtap.keyStroke({"cmd", "shift"}, "1")

    -- Function to handle clipboard changes
    local function handleClipboardChange()
        local newClipboard = hs.pasteboard.getContents()

        -- Check if clipboard content has changed
        if newClipboard ~= oldClipboard then
            clipboardWatcher:stop() -- Stop watching the clipboard

            local selectedText = newClipboard
            local url

            if selectedText:match("://") then
                url = selectedText
            elseif selectedText ~= "" then
                url = "http://www.google.com/search?q=" .. hs.http.encodeForQuery(selectedText)
            else
                url = "http://www.google.com"
            end

            hs.urlevent.openURLWithBundle(url, browserBundleID)
            -- hs.pasteboard.setContents(oldClipboard) -- Restore old clipboard contents
        end
    end

    -- Set up the clipboard watcher
    clipboardWatcher = hs.pasteboard.watcher.new(handleClipboardChange)
    clipboardWatcher:start()

    -- Function to stop the watcher and display timeout alert if no change in clipboard content
    local function checkTimeout()
        local newClipboard = hs.pasteboard.getContents()
        if newClipboard == oldClipboard then
            clipboardWatcher:stop()
            hs.eventtap.keyStroke({}, "escape")
            hs.alert.show("Search timed out")
        end
    end

    -- Set a timer to check for timeout after 10 seconds
    hs.timer.doAfter(10, checkTimeout)
end


function googleMultiSearch()
    local oldClipboard = hs.pasteboard.getContents()
    hs.eventtap.keyStroke({"cmd"}, "c")
    hs.eventtap.keyStroke({"cmd"}, "c")
    hs.timer.usleep(200000)

    local selectedText = hs.pasteboard.getContents()
    local lines = hs.fnutils.split(selectedText, "\n")

    for _, line in ipairs(lines) do
        local url
        url = "http://www.google.com/search?q=" .. hs.http.encodeForQuery(line)
        hs.timer.usleep(300000)
        hs.urlevent.openURLWithBundle(url, 'com.brave.Browser')
        -- hs.execute("open -a 'Google Chrome' " .. url)
        -- hs.execute("open -a 'Google Chrome' --new-window " .. url)
    end
end

function youtubeSearch()
    -- Clear the clipboard
    -- hs.pasteboard.clearContents()

    -- Copy to clipboard
    hs.eventtap.keyStroke({"cmd"}, "c")
    hs.timer.usleep(200000)  -- Wait a bit for the clipboard to populate

    local selectedText = hs.pasteboard.getContents()  -- Get the clipboard content
    local url

    -- Check if selectedText starts with "http://" or "https://"
    if selectedText ~= "" then
        url = "https://www.youtube.com/results?search_query=" .. hs.http.encodeForQuery(selectedText)
    else
        url = "https://www.youtube.com"  -- if no text selected, just open Google
    end
    hs.execute("open " .. url)

    -- hs.urlevent.openURLWithBundle(url, 'com.google.Chrome')
end
-- Function to type clipboard contents
function typeClipboardContents()
    local clipboardContents = hs.pasteboard.getContents()  -- Get the clipboard content
    if clipboardContents ~= "" then
        hs.eventtap.keyStrokes(clipboardContents)  -- Type the clipboard content
    end
end
-- make a note
-- Function to open Notepad and create a new note
function openNewNotepad()
    hs.alert.show("Opening Notepad")
    local filePath = "/Users/omshejul/SavedMain/notepad/note" .. os.date("%d%m%y_%H%M%S")
    hs.execute("/usr/bin/touch " .. filePath)
    local command = "/opt/homebrew/bin/code /Users/omshejul/SavedMain/notepad " .. filePath
    hs.execute(command)
end
function openNewZedNotepad()
    hs.alert.show("Opening Zed")
    local filePath = "/Users/omshejul/SavedMain/notepad/note" .. os.date("%d-%b-%Y_%H:%M:%S")
    hs.execute("/usr/bin/touch " .. filePath)
    local command = "/usr/local/bin/zed /Users/omshejul/SavedMain/notepad " .. filePath
    hs.execute(command)
end
function openZedNotepad()
    hs.alert.show("Opening Zed")
    local command = "/usr/local/bin/zed /Users/omshejul/SavedMain/notepad"
    hs.execute(command)
end


-- Hotkey: ctrl+q to Google search selected text
hs.hotkey.bind({"ctrl"}, "q", function() googleSearch() end)
hs.hotkey.bind({"ctrl","cmd", "shift", "alt"}, "p", function() perplexitySearch("company.thebrowser.Browser") end)
hs.hotkey.bind({"ctrl", "shift"}, "1", function() ocrSearch("company.thebrowser.Browser") end)
-- hs.hotkey.bind({"ctrl"}, "w", function() googleSearch("company.thebrowser.Browser") end)
hs.hotkey.bind({"ctrl", "shift"}, "q", googleMultiSearch) -- search line by line
-- Binds the "ctrl + y" hotkey to the youtubeSearch function.
hs.hotkey.bind({"ctrl"}, "y", youtubeSearch)
hs.hotkey.bind({"ctrl", "shift"}, "t", openNewNotepad)
hs.hotkey.bind({"ctrl", "shift", "cmd"}, "z", openNewZedNotepad)
hs.hotkey.bind({"ctrl", "shift", "cmd"}, "o", openZedNotepad)
-- Hotkey: ctrl+cmd+v to type clipboard contents
hs.hotkey.bind({"ctrl", "cmd"}, "v", typeClipboardContents)

-- Hotkey: F13 to bring meet window to top and press cmd+d
-- /Users/omshejul/Applications/Orion/WebApps/Meet.app/Contents/MacOS/Meet

appBundleID = "com.apple.Safari"
-- appBundleID = "com.brave.Browser.app.mhglifepdajnkbflieebooepjeldkkkc"
local function bringToFrontAndUnmute()
    local app = hs.application.find(appBundleID)
    if app then
        app:activate()
        hs.alert.show("Toggling Mic")
        hs.eventtap.keyStroke({"cmd"}, "d")
    else
        hs.alert.show("App not found")
    end
end
local function openAndMuteThenHide()
    local app = hs.application.find(appBundleID)
    if app then
        hs.timer.doAfter(.1, function()
            app:activate()  
            hs.alert.show("Muting and Hiding")
            hs.eventtap.keyStroke({"cmd"}, "d")
        end)
        hs.timer.doAfter(.5, function()
            app:hide()
        end)
    else
        hs.alert.show("Failed to open App")
    end
end

-- Hotkey: F13 to bring browser app to front and press cmd+m
hs.hotkey.bind({}, "F13", bringToFrontAndUnmute)


-- Hotkey: F14 to open browser app, press cmd+d to mute, and hide the window
hs.hotkey.bind({}, "F14", openAndMuteThenHide)















-- AUTOSCROLL WITH MOUSE WHEEL BUTTON
-- timginter @ GitHub
------------------------------------------------------------------------------------------

-- id of mouse wheel button
local mouseScrollButtonId = 2


-- scroll speed and direction config
local scrollSpeedMultiplier = 0.01
local scrollSpeedSquareAcceleration = true
local reverseVerticalScrollDirection = true
local mouseScrollTimerDelay = 0.0001

-- circle config
local mouseScrollCircleRad = 10
local mouseScrollCircleDeadZone = 10

------------------------------------------------------------------------------------------

local mouseScrollCircle = nil
local mouseScrollTimer = nil
local mouseScrollStartPos = 0
local mouseScrollDragPosX = nil
local mouseScrollDragPosY = nil

overrideScrollMouseDown = hs.eventtap.new({ hs.eventtap.event.types.otherMouseDown }, function(e)
    -- uncomment line below to see the ID of pressed button
    -- print(e:getProperty(hs.eventtap.event.properties['mouseEventButtonNumber']))

    if e:getProperty(hs.eventtap.event.properties['mouseEventButtonNumber']) == mouseScrollButtonId then
        -- remove circle if exists
        if mouseScrollCircle then
            mouseScrollCircle:delete()
            mouseScrollCircle = nil
        end

        -- stop timer if running
        if mouseScrollTimer then
            mouseScrollTimer:stop()
            mouseScrollTimer = nil
        end

        -- save mouse coordinates
        mouseScrollStartPos = hs.mouse.getAbsolutePosition()
        mouseScrollDragPosX = mouseScrollStartPos.x
        mouseScrollDragPosY = mouseScrollStartPos.y

        -- start scroll timer
        mouseScrollTimer = hs.timer.doAfter(mouseScrollTimerDelay, mouseScrollTimerFunction)

        -- don't send scroll button down event
        return true
    end
end)

overrideScrollMouseUp = hs.eventtap.new({ hs.eventtap.event.types.otherMouseUp }, function(e)
    if e:getProperty(hs.eventtap.event.properties['mouseEventButtonNumber']) == mouseScrollButtonId then
        -- send original button up event if released within 'mouseScrollCircleDeadZone' pixels of original position and scroll circle doesn't exist
        mouseScrollPos = hs.mouse.getAbsolutePosition()
        xDiff = math.abs(mouseScrollPos.x - mouseScrollStartPos.x)
        yDiff = math.abs(mouseScrollPos.y - mouseScrollStartPos.y)
        if (xDiff < mouseScrollCircleDeadZone and yDiff < mouseScrollCircleDeadZone) and not mouseScrollCircle then
            -- disable scroll mouse override
            overrideScrollMouseDown:stop()
            overrideScrollMouseUp:stop()

            -- send scroll mouse click
            hs.eventtap.otherClick(e:location(), mouseScrollButtonId)

            -- re-enable scroll mouse override
            overrideScrollMouseDown:start()
            overrideScrollMouseUp:start()
        end

        -- remove circle if exists
        if mouseScrollCircle then
            mouseScrollCircle:delete()
            mouseScrollCircle = nil
        end

        -- stop timer if running
        if mouseScrollTimer then
            mouseScrollTimer:stop()
            mouseScrollTimer = nil
        end

        -- don't send scroll button up event
        return true
    end
end)

overrideScrollMouseDrag = hs.eventtap.new({ hs.eventtap.event.types.otherMouseDragged }, function(e)
    -- sanity check
    if mouseScrollDragPosX == nil or mouseScrollDragPosY == nil then
        return true
    end

    -- update mouse coordinates
    mouseScrollDragPosX = mouseScrollDragPosX + e:getProperty(hs.eventtap.event.properties['mouseEventDeltaX'])
    mouseScrollDragPosY = mouseScrollDragPosY + e:getProperty(hs.eventtap.event.properties['mouseEventDeltaY'])

    -- don't send scroll button drag event
    return true
end)

function mouseScrollTimerFunction()
    -- sanity check
    if mouseScrollDragPosX ~= nil and mouseScrollDragPosY ~= nil then
        -- get cursor position difference from original click
        xDiff = math.abs(mouseScrollDragPosX - mouseScrollStartPos.x)
        yDiff = math.abs(mouseScrollDragPosY - mouseScrollStartPos.y)

        -- draw circle if not yet drawn and cursor moved more than 'mouseScrollCircleDeadZone' pixels
        if mouseScrollCircle == nil and (xDiff > mouseScrollCircleDeadZone or yDiff > mouseScrollCircleDeadZone) then
            mouseScrollCircle = hs.drawing.circle(hs.geometry.rect(mouseScrollStartPos.x - mouseScrollCircleRad, mouseScrollStartPos.y - mouseScrollCircleRad, mouseScrollCircleRad * 2, mouseScrollCircleRad * 2))
            mouseScrollCircle:setStrokeColor({["red"]=0.3, ["green"]=0.3, ["blue"]=0.3, ["alpha"]=1})
            mouseScrollCircle:setFill(false)
            mouseScrollCircle:setStrokeWidth(1)
            mouseScrollCircle:show()
        end

        -- send scroll event if cursor moved more than circle's radius
        if xDiff > mouseScrollCircleRad or yDiff > mouseScrollCircleRad then
            -- get real xDiff and yDiff
            deltaX = mouseScrollDragPosX - mouseScrollStartPos.x
            deltaY = mouseScrollDragPosY - mouseScrollStartPos.y

            -- use 'scrollSpeedMultiplier'
            deltaX = deltaX * scrollSpeedMultiplier
            deltaY = deltaY * scrollSpeedMultiplier

            -- square for better scroll acceleration
            if scrollSpeedSquareAcceleration then
                -- mod to keep negative values
                deltaXDirMod = 1
                deltaYDirMod = 1

                if deltaX < 0 then
                    deltaXDirMod = -1
                end
                if deltaY < 0 then
                    deltaYDirMod = -1
                end

                deltaX = deltaX * deltaX * deltaXDirMod
                deltaY = deltaY * deltaY * deltaYDirMod
            end

            -- math.ceil / math.floor - scroll event accepts only integers
             deltaXRounding = math.ceil
             deltaYRounding = math.ceil

             if deltaX < 0 then
                 deltaXRounding = math.floor
             end
             if deltaY < 0 then
                 deltaYRounding = math.floor
             end

             deltaX = deltaXRounding(deltaX)
             deltaY = deltaYRounding(deltaY)

            -- reverse Y scroll if 'reverseVerticalScrollDirection' set to true
            if reverseVerticalScrollDirection then
                deltaY = deltaY * -1
            end

            -- send scroll event
            hs.eventtap.event.newScrollEvent({-deltaX, deltaY}, {}, 'pixel'):post()
        end
    end

    -- restart timer
    mouseScrollTimer = hs.timer.doAfter(mouseScrollTimerDelay, mouseScrollTimerFunction)
end

-- start override functions
overrideScrollMouseDown:start()
overrideScrollMouseUp:start()
overrideScrollMouseDrag:start()
-- ==========================================================================================

-- >> CUSTOM MENU EXAMPLE
-- Example of a keybind-triggered menu using hs.chooser
-- You can customize the menu items and their actions

-- Helper function to load custom icons
-- Place your icon files in ~/.hammerspoon/icons/ or specify full paths
-- Supports: PNG, JPEG, SVG, PDF, TIFF, GIF, and other macOS-supported formats
local function loadIcon(iconName)
    local iconPath = os.getenv("HOME") .. "/.hammerspoon/icons/" .. iconName
    local image = hs.image.imageFromPath(iconPath)
    -- Fallback to system icon if custom icon doesn't exist
    if not image then
        return hs.image.imageFromName("NSActionTemplate")
    end
    return image
end

-- Helper function to add padding to SVG icons
local function addPaddingToSVG(iconPath, paddingPercent)
    paddingPercent = paddingPercent or 20  -- Default 20% padding
    
    local file = io.open(iconPath, "r")
    if not file then
        return nil
    end
    
    local svgContent = file:read("*all")
    file:close()
    
    -- Extract viewBox values (usually "0 0 width height")
    local viewBox = svgContent:match('viewBox="([^"]*)"')
    if not viewBox then
        -- If no viewBox, try to get width and height
        local width = svgContent:match('width="([^"]*)"') or "24"
        local height = svgContent:match('height="([^"]*)"') or "24"
        viewBox = "0 0 " .. width .. " " .. height
    end
    
    local x, y, width, height = viewBox:match("([%d.]+)%s+([%d.]+)%s+([%d.]+)%s+([%d.]+)")
    if not x or not y or not width or not height then
        return nil
    end
    
    width = tonumber(width)
    height = tonumber(height)
    
    -- Calculate padding amount
    local paddingX = width * (paddingPercent / 100)
    local paddingY = height * (paddingPercent / 100)
    
    -- New viewBox with padding
    local newViewBox = string.format("%.2f %.2f %.2f %.2f", 
        -paddingX, -paddingY, 
        width + (paddingX * 2), 
        height + (paddingY * 2))
    
    -- Replace or add viewBox
    if svgContent:match('viewBox=') then
        svgContent = svgContent:gsub('viewBox="[^"]*"', 'viewBox="' .. newViewBox .. '"')
    else
        -- Add viewBox to svg tag
        svgContent = svgContent:gsub('(<svg[^>]*)>', '%1 viewBox="' .. newViewBox .. '">', 1)
    end
    
    -- Create temporary file
    local tempPath = os.getenv("HOME") .. "/.hammerspoon/icons/.temp_padded_" .. hs.hash.SHA256(iconPath):sub(1, 8) .. ".svg"
    local tempFile = io.open(tempPath, "w")
    if tempFile then
        tempFile:write(svgContent)
        tempFile:close()
        
        local image = hs.image.imageFromPath(tempPath)
        
        -- Clean up temp file after a delay
        hs.timer.doAfter(1, function()
            os.remove(tempPath)
        end)
        
        return image
    end
    
    return nil
end

-- Helper function to load icons from popular icon libraries
-- Examples:
-- loadIconFromLibrary("heroicons", "document-text", "outline")  -- Heroicons
-- loadIconFromLibrary("lucide", "file-text")  -- Lucide icons
-- You can download SVG icons from:
-- - Heroicons: https://heroicons.com/
-- - Lucide: https://lucide.dev/
-- - React Icons: https://react-icons.github.io/react-icons/ (download SVG)
-- - Font Awesome: https://fontawesome.com/icons (download SVG)
-- - Material Icons: https://fonts.google.com/icons (download SVG)
local function loadIconFromLibrary(library, iconName, style)
    local iconPath
    -- Heroicons uses style (outline/solid), other libraries don't
    if library == "heroicons" then
        style = style or "solid"  -- default to solid for heroicons
        iconPath = os.getenv("HOME") .. "/.hammerspoon/icons/" .. library .. "/" .. style .. "/" .. iconName .. ".svg"
    elseif library == "react-icons" then
        -- React Icons (like FcGoogle)
        iconPath = os.getenv("HOME") .. "/.hammerspoon/icons/" .. library .. "/" .. iconName .. ".svg"
    else
        -- For lucide, simple-icons, etc. (no style)
        iconPath = os.getenv("HOME") .. "/.hammerspoon/icons/" .. library .. "/" .. iconName .. ".svg"
    end
    
    -- Try to load with padding first
    local image = addPaddingToSVG(iconPath, 20)  -- 20% padding
    if image then
        return image
    end
    
    -- Fallback to regular loading
    image = hs.image.imageFromPath(iconPath)
    if not image then
        return hs.image.imageFromName("NSActionTemplate")
    end
    return image
end

-- Function to show pasteboard submenu with frequently used text
local function showPasteboardMenu()
    -- Define frequently used text items
    -- Set these environment variables in ~/.hammerspoon/.env file:
    -- HS_ADDRESS="Your address"
    -- HS_WEBSITE="https://yourwebsite.com"
    -- HS_EMAIL="your@email.com"
    -- HS_GITHUB="https://github.com/yourusername"
    -- HS_LINKEDIN="https://www.linkedin.com/in/yourusername/"
    -- HS_TWITTER="https://x.com/yourusername"
    -- HS_INSTAGRAM="https://www.instagram.com/yourusername/"
    -- HS_PHONE="+1 2345678900"
    local pasteboardItems = {
        {
            text = "Address",
            subText = getEnv("HS_ADDRESS"),
            value = getEnv("HS_ADDRESS")
        },
        {
            text = "Calender",
            subText = getEnv("HS_CALENDERLINK"),
            value = getEnv("HS_CALENDERLINK")
        },
        {
            text = "Website",
            subText = getEnv("HS_WEBSITE"),
            value = getEnv("HS_WEBSITE")
        },
        {
            text = "Email",
            subText = getEnv("HS_EMAIL"),
            value = getEnv("HS_EMAIL")
        },
        {
            text = "Github",
            subText = getEnv("HS_GITHUB"),
            value = getEnv("HS_GITHUB")
        },
        {
            text = "LinkedIn",
            subText = getEnv("HS_LINKEDIN"),
            value = getEnv("HS_LINKEDIN")
        },
        {
            text = "Twitter",
            subText = getEnv("HS_TWITTER"),
            value = getEnv("HS_TWITTER")
        },
        {
            text = "Instagram",
            subText = getEnv("HS_INSTAGRAM"),
            value = getEnv("HS_INSTAGRAM")
        },
        {
            text = "Phone",
            subText = getEnv("HS_PHONE"),
            value = getEnv("HS_PHONE")
        }
    }
    
    local pasteboardActions = {}
    for _, item in ipairs(pasteboardItems) do
        pasteboardActions[item.text] = function()
            -- Type the text at cursor position
            hs.eventtap.keyStrokes(item.value)
        end
    end
    
    local pasteboardChooser = hs.chooser.new(function(choice)
        if choice and choice.text and pasteboardActions[choice.text] then
            pasteboardActions[choice.text]()
        end
    end)
    
    pasteboardChooser:choices(pasteboardItems)
    pasteboardChooser:searchSubText(true)
    pasteboardChooser:bgDark(false)
    pasteboardChooser:fgColor({ white = 0, alpha = 1 })
    pasteboardChooser:subTextColor({ white = 0.4, alpha = 1 })
    pasteboardChooser:rows(10)
    pasteboardChooser:width(40)
    pasteboardChooser:show()
end

local function showCustomMenu()
    -- Define menu items with icons
    -- To use custom icons, place image files in ~/.hammerspoon/icons/ and uncomment the image lines
    -- Supported formats: PNG, JPEG, SVG, PDF, TIFF, GIF, and other macOS-supported formats
    -- 
    -- Icon Library Examples:
    -- - Heroicons: https://heroicons.com/ (download SVG, place in ~/.hammerspoon/icons/heroicons/outline/)
    -- - Lucide: https://lucide.dev/ (download SVG, place in ~/.hammerspoon/icons/lucide/)
    -- - React Icons: https://react-icons.github.io/react-icons/ (download SVG from GitHub)
    -- - Font Awesome: https://fontawesome.com/icons (download SVG)
    -- - Material Icons: https://fonts.google.com/icons (download SVG)
    --
    -- Example usage:
    -- image = loadIcon("notepad.png")  -- Simple file in icons folder
    -- image = loadIconFromLibrary("heroicons", "document-text", "outline")  -- From icon library
    -- image = loadIconFromLibrary("lucide", "file-text")  -- Lucide icons
    local menuItems = {
        {
            text = "Pasteboard",
            subText = "Frequently used text snippets",
            image = loadIconFromLibrary("heroicons", "clipboard", "solid")
        },
        {
            text = "Reload Config",
            subText = "Reload Hammerspoon configuration",
            image = loadIconFromLibrary("heroicons", "arrow-path", "solid")
        },
        {
            text = "Open Notepad",
            subText = "Create a new note",
            image = loadIconFromLibrary("heroicons", "clipboard-document", "solid")
        },
        {
            text = "Google Search",
            subText = "Search selected text on Google",
            image = loadIconFromLibrary("react-icons", "fagoogle")
        },
        {
            text = "YouTube Search",
            subText = "Search selected text on YouTube",
            image = loadIconFromLibrary("simple-icons", "youtube")
        },
        {
            text = "Perplexity Search",
            subText = "Search selected text on Perplexity AI",
            image = loadIconFromLibrary("simple-icons", "perplexity")
        },
        {
            text = "ChatGPT Search",
            subText = "Search selected text on ChatGPT",
            image = loadIconFromLibrary("simple-icons", "openai")
        },
        {
            text = "Claude Search",
            subText = "Search selected text on Claude AI",
            image = loadIconFromLibrary("simple-icons", "anthropic")
        },
        {
            text = "Google AI Search",
            subText = "Search selected text on Google with AI mode",
            image = loadIconFromLibrary("react-icons", "rigeminifill")
        },
        {
            text = "Toggle Display Sleep",
            subText = "Toggle display sleep prevention",
            image = loadIconFromLibrary("heroicons", "computer-desktop", "solid")
        }
    }
    
    -- Map menu item text to their actions
    local menuActions = {
        ["Open Notepad"] = function()
            openNewZedNotepad()
        end,
        ["Google Search"] = function()
            googleSearch()
        end,
        ["YouTube Search"] = function()
            youtubeSearch()
        end,
        ["Perplexity Search"] = function()
            perplexitySearch("company.thebrowser.Browser")
        end,
        ["ChatGPT Search"] = function()
            chatgptSearch("company.thebrowser.Browser")
        end,
        ["Claude Search"] = function()
            claudeSearch("company.thebrowser.Browser")
        end,
        ["Google AI Search"] = function()
            googleAISearch("company.thebrowser.Browser")
        end,
        ["Reload Config"] = function()
            hs.reload()
        end,
        ["Pasteboard"] = function()
            showPasteboardMenu()
        end,
        ["Toggle Display Sleep"] = function()
            toggleDisplaySleep()
        end
    }
    
    local chooser = hs.chooser.new(function(choice)
        if choice and choice.text and menuActions[choice.text] then
            menuActions[choice.text]()
        end
    end)
    
    chooser:choices(menuItems)
    chooser:searchSubText(true)  -- Allow searching in subText as well
    
    -- Styling for light theme
    chooser:bgDark(false)  -- Use light background
    chooser:fgColor({ white = 0, alpha = 1 })  -- Dark text on light background
    chooser:subTextColor({ white = 0.4, alpha = 1 })  -- Gray subtext
    chooser:rows(10)  -- Show up to 10 items
    chooser:width(40)  -- Set width percentage (50% of screen)
    
    chooser:show()  -- Show the menu
end

-- Bind a hotkey to show the menu (example: Cmd+Shift+M)
hs.hotkey.bind({"cmd", "shift"}, "m", showCustomMenu)

-- << CUSTOM MENU EXAMPLE

-- Reload Hammerspoon configuration
hs.alert.show("Hammerspoon config loaded")