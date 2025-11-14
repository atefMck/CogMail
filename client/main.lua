-- Email Client Main File with Basalt GUI
local basalt = require("basalt")

-- Check if basalt is available
if not basalt then
    error("Basalt library not found. Please install Basalt2.")
end

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
local showLogin, showInbox, showCompose

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

-- Start with login screen
showLogin()

-- Run the GUI
basalt.run()

