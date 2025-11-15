-- Email Client Main File with Basalt GUI

-- Version Information
local CLIENT_VERSION = "1.0.0"

local basalt = require("basalt")

-- Check if basalt is available
if not basalt then
    error("Basalt library not found. Please install Basalt2.")
end

local Network = require("network")
local Login = require("screens/login")
local Inbox = require("screens/inbox")
local Compose = require("screens/compose")

-- Create main frame for terminal
local main = basalt.getMainFrame()
    :setBackground(colors.black)

local currentAccount = nil
local currentScreen = nil
local inboxScreen = nil  -- Keep reference to inbox screen

-- Forward declarations
local showLogin, showInbox, showCompose, showVersionCheck

-- Helper function to compare version strings (simple semantic versioning)
local function compareVersions(v1, v2)
    if v1 == v2 then return 0 end
    
    local parts1 = {}
    local parts2 = {}
    
    for part in v1:gmatch("%d+") do
        table.insert(parts1, tonumber(part))
    end
    for part in v2:gmatch("%d+") do
        table.insert(parts2, tonumber(part))
    end
    
    local maxLen = math.max(#parts1, #parts2)
    for i = 1, maxLen do
        local p1 = parts1[i] or 0
        local p2 = parts2[i] or 0
        if p1 > p2 then return 1 end
        if p1 < p2 then return -1 end
    end
    
    return 0
end

-- Helper function to update client
local function updateClient(targetVersion)
    local clientUrl = "https://raw.githubusercontent.com/atefMck/CogMail/refs/heads/main/build/mailingClient.lua"
    local installPath = "mailingClient.lua"
    
    print("Downloading client version " .. (targetVersion or "latest") .. "...")
    local request = http.get(clientUrl)
    if not request then
        return false, "Failed to download client"
    end
    
    local file = fs.open(installPath, "w")
    if not file then
        request.close()
        return false, "Could not write to " .. installPath
    end
    
    file.write(request.readAll())
    file.close()
    request.close()
    
    return true, "Client updated successfully"
end

-- Define showInbox first so it's available when showLogin creates its callback
showInbox = function()
    -- Make sure we have an account
    if not currentAccount then
        showLogin()
        return
    end
    
    -- If inbox already exists and is valid, just show it and refresh
    if inboxScreen then
        -- Check if inbox screen is still valid (has destroy method)
        if inboxScreen.destroy then
            inboxScreen:setVisible(true)
            -- Refresh the inbox to reload emails
            if inboxScreen.refresh then
                inboxScreen.refresh()
            end
            currentScreen = inboxScreen
            return
        else
            -- Inbox screen was destroyed, clear reference
            inboxScreen = nil
        end
    end
    
    -- Create new inbox screen
    inboxScreen = Inbox.create(main, currentAccount, function()
        showCompose()
    end, function()
        currentAccount = nil
        inboxScreen = nil
        showLogin()
    end)
    
    currentScreen = inboxScreen
end

-- Define showCompose
showCompose = function()
    -- Make sure we have an account
    if not currentAccount then
        showLogin()
        return
    end
    
    -- Hide inbox instead of destroying it
    if inboxScreen then
        inboxScreen:setVisible(false)
    end
    
    -- Destroy any other current screen (like email view)
    if currentScreen and currentScreen ~= inboxScreen and currentScreen.destroy then
        currentScreen:destroy()
    end
    
    currentScreen = Compose.create(main, currentAccount, function()
        showInbox()
    end)
end

-- Define showLogin (can now reference showInbox)
showLogin = function()
    -- Clear inbox screen reference when logging out
    inboxScreen = nil
    currentAccount = nil
    
    if currentScreen and currentScreen.destroy then
        currentScreen:destroy()
    end
    
    -- Create callback that has access to showInbox
    local function onLoginSuccess(account)
        currentAccount = account
        showInbox()
    end
    
    currentScreen = Login.create(main, onLoginSuccess, function()
        -- Callback to recreate login screen (for account creation redirect)
        showLogin()
    end)
end

-- Version check dialog
showVersionCheck = function()
    if currentScreen and currentScreen.destroy then
        currentScreen:destroy()
    end
    
    local checkScreen = main:addFrame()
        :setSize("{parent.width}", "{parent.height}")
        :setBackground(colors.black)
    
    local statusLabel = checkScreen:addLabel()
        :setText("Checking server version...")
        :setPosition(2, 2)
        :setForeground(colors.white)
    
    -- Try to get server version
    basalt.schedule(function()
        sleep(0.1) -- Small delay to show the checking message
        local success, serverVersion = Network.getServerVersion()
        
        if not success then
            -- Can't connect to server, show error but allow continue
            statusLabel:setText("Warning: Could not connect to server")
            statusLabel:setForeground(colors.yellow)
            
            local continueBtn = checkScreen:addButton()
                :setText("Continue Anyway")
                :setPosition("{parent.width / 2 - 7}", "{parent.height - 2}")
                :setSize(14, 1)
                :setBackground(colors.gray)
                :setForeground(colors.white)
                :onClick(function()
                    checkScreen:destroy()
                    showLogin()
                end)
            return
        end
        
        local versionMatch = compareVersions(CLIENT_VERSION, serverVersion) == 0
        
        if versionMatch then
            -- Versions match, proceed to login
            checkScreen:destroy()
            showLogin()
            return
        end
        
        -- Versions don't match, show update dialog
        local needsUpdate = compareVersions(CLIENT_VERSION, serverVersion) < 0
        
        statusLabel:setText("Version Mismatch Detected!")
        statusLabel:setForeground(colors.red)
        
        local infoLabel = checkScreen:addLabel()
            :setText("Client Version: " .. CLIENT_VERSION .. "\nServer Version: " .. serverVersion)
            :setPosition(2, 4)
            :setSize("{parent.width - 4}", 2)
            :setForeground(colors.white)
        
        local actionLabel = checkScreen:addLabel()
            :setText(needsUpdate and "Your client is outdated. Please update to match the server." or "Your client is newer than the server. Please downgrade or update the server.")
            :setPosition(2, 7)
            :setSize("{parent.width - 4}", 2)
            :setForeground(colors.yellow)
        
        local updateBtn = checkScreen:addButton()
            :setText(needsUpdate and "Update Client" or "Downgrade Client")
            :setPosition("{parent.width / 2 - 15}", "{parent.height - 4}")
            :setSize(14, 1)
            :setBackground(needsUpdate and colors.green or colors.orange)
            :setForeground(colors.white)
        
        -- Capture updateBtn and statusLabel in local variables for closure
        local updateBtnRef = updateBtn
        local statusLabelRef = statusLabel
        
        updateBtn:onClick(function()
                updateBtnRef:setText("Updating...")
                updateBtnRef:setEnabled(false)
                
                basalt.schedule(function()
                    local success, message = updateClient(serverVersion)
                    if success then
                        statusLabelRef:setText("Update successful! Restarting...")
                        statusLabelRef:setForeground(colors.green)
                        sleep(2)
                        os.reboot()
                    else
                        statusLabelRef:setText("Update failed: " .. message)
                        statusLabelRef:setForeground(colors.red)
                        updateBtnRef:setText("Retry")
                        updateBtnRef:setEnabled(true)
                    end
                end)
            end)
        
        local continueBtn = checkScreen:addButton()
            :setText("Continue Anyway")
            :setPosition("{parent.width / 2 + 1}", "{parent.height - 4}")
            :setSize(14, 1)
            :setBackground(colors.gray)
            :setForeground(colors.white)
            :onClick(function()
                checkScreen:destroy()
                showLogin()
            end)
        
        local cancelBtn = checkScreen:addButton()
            :setText("Exit")
            :setPosition("{parent.width / 2 - 7}", "{parent.height - 2}")
            :setSize(14, 1)
            :setBackground(colors.red)
            :setForeground(colors.white)
            :onClick(function()
                basalt.stop()
            end)
    end)
    
    currentScreen = checkScreen
end

-- Start with version check, then login
showVersionCheck()

-- Run the GUI
basalt.run()

