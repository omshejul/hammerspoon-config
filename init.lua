require("hs.ipc")
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

-- >> SYNC PROGRESS
-- Define the menu bar icon

-- Function to display the icon
function showSyncIcon()
    syncMenu = hs.menubar.new()
    syncMenu:setIcon(hs.image.imageFromName("NSActionTemplate"))
    syncMenu:setTitle("🔄")
end

-- Function to remove the icon
function removeSyncIcon()
    syncMenu:removeFromMenuBar()
end
-- << SYNC PROGRESS



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
local endTime = 2200

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
local function toggleDisplaySleep()
    manualOverride = true
    displayAwake = not displayAwake
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
local timer = hs.timer.doEvery(60, checkTimeAndUpdate)

-- Start the timer
timer:start()


-- Initial update to set the default state in the menu
checkTimeAndUpdate()


-- >> SPEAK WORD
hs.hotkey.bind({"ctrl", "alt", "cmd", "shift"}, "L", function()
    -- Command to execute your Python script
    local pythonScript = "/usr/local/bin/python3 -u ~/SavedMain/python/Assisto_PY/googleTTS/tts.py"
    
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

    hs.urlevent.openURLWithBundle(url, browserBundleID)
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
hs.hotkey.bind({"ctrl"}, "q", function() googleSearch("company.thebrowser.Browser") end)
hs.hotkey.bind({"ctrl","cmd", "shift", "alt"}, "p", function() perplexitySearch("company.thebrowser.Browser") end)
hs.hotkey.bind({"ctrl", "shift"}, "1", function() ocrSearch("company.thebrowser.Browser") end)
hs.hotkey.bind({"ctrl"}, "w", function() googleSearch("company.thebrowser.Browser") end)
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

appBundleID = "com.apple.Safari.WebApp.2B5674E7-0B4C-4BE1-B195-07FF44758532"
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



-- Function to toggle the Arc application
function toggleArc()
    local appName = "Arc"
    local app = hs.application.find(appName)
    
    if app then
        if app:isFrontmost() then
            hs.eventtap.keyStroke({"cmd"}, "h")
        else
            hs.application.launchOrFocus(appName)
        end
    else
        hs.application.launchOrFocus(appName)
    end
end

-- Bind the F15 key to the toggleArc function
hs.hotkey.bind({}, "F15", toggleArc)









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


-- Reload Hammerspoon configuration
hs.alert.show("Hammerspoon config loaded")