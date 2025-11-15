-- Email Client Installer
-- Download and install the CogMail email client

-- TODO: Replace with your actual GitHub repository URL
local clientUrl = "https://raw.githubusercontent.com/atefMck/CogMail/refs/heads/main/build/mailingClient.lua"
local basaltUrl = "https://raw.githubusercontent.com/Pyroxenium/Basalt2/refs/heads/main/release/basalt-full.lua"

local args = {...}

-- Help command
if (args[1] == "-h") or (args[1] == "--help") then
    print("Usage: installClient.lua [options]")
    print("Options:")
    print("  -h, --help        Show this help message")
    print("  -q, --quick       Quick install with defaults (no GUI)")
    return
end

-- Quick install mode (no GUI)
if (args[1] == "-q") or (args[1] == "--quick") then
    print("Quick installing email client...")
    
    -- Download client
    print("Downloading client...")
    local request = http.get(clientUrl)
    if not request then
        error("Failed to download client")
    end
    
    local installPath = args[2] or "mailingClient.lua"
    local file = fs.open(installPath, "w")
    file.write(request.readAll())
    file.close()
    request.close()
    
    print("Client installed to: " .. installPath)
    print("To run: local client = require(\"" .. installPath:gsub(".lua", "") .. "\"); client.runClient()")
    return
end

-- GUI Install mode
local basalt

-- Try to load Basalt locally first
local basaltFile = fs.open("basalt.lua", "r")
if basaltFile then
    basalt = load(basaltFile.readAll(), "basalt", "bt", _ENV)()
    basaltFile.close()
else
    -- Download Basalt for GUI
    print("Downloading Basalt GUI framework...")
    local basaltRequest = http.get(basaltUrl)
    if not basaltRequest then
        error("Failed to download Basalt. Please install Basalt manually or use -q for quick install.")
    end
    local basaltContent = basaltRequest.readAll()
    basaltRequest.close()
    
    -- Save Basalt to disk for future use
    local basaltSaveFile = fs.open("basalt.lua", "w")
    if basaltSaveFile then
        basaltSaveFile.write(basaltContent)
        basaltSaveFile.close()
        print("Basalt saved to basalt.lua")
    end
    
    basalt = load(basaltContent, "basalt", "bt", _ENV)()
end

local coloring = {foreground = colors.black, background = colors.white}
local currentScreen = 1
local screens = {}
local main = basalt.getMainFrame():setBackground(colors.black)

-- Screen positioning
local function getScreenPosition(index)
    return (main:getWidth() * (index - 1)) + 2
end

local function createScreen(index)
    local screen = main:addScrollFrame(coloring)
        :setScrollBarBackgroundColor(colors.gray)
        :setScrollBarBackgroundColor2(colors.black)
        :setScrollBarColor(colors.lightGray)
        :setSize("{parent.width - 2}", "{parent.height - 4}")
        :setPosition(function()
            return getScreenPosition(index)
        end, 2)
    
    screens[index] = screen
    return screen
end

local backButton
local nextButton

local function switchScreen(direction)
    local newScreen = currentScreen + direction
    
    if screens[newScreen] then
        main:animate():moveOffset((newScreen - 1) * main:getWidth(), 0, 0.5):start()
        currentScreen = newScreen
    end
    
    basalt.schedule(function()
        sleep(0.1)
        backButton:setVisible(true)
        nextButton:setVisible(true)
        if newScreen == 1 then
            backButton:setVisible(false)
        end
        if newScreen == 3 then
            nextButton:setVisible(false)
        end
    end)
end

nextButton = main:addButton()
    :setBackground("{self.clicked and colors.black or colors.white}")
    :setForeground("{self.clicked and colors.white or colors.black}")
    :setSize(8, 1)
    :setText("Next")
    :setPosition("{parent.width - 9}", "{parent.height - 1}")
    :setIgnoreOffset(true)
    :onClick(function() switchScreen(1) end)

backButton = main:addButton()
    :setBackground("{self.clicked and colors.black or colors.white}")
    :setForeground("{self.clicked and colors.white or colors.black}")
    :setSize(8, 1)
    :setText("Back")
    :setPosition(2, "{parent.height - 1}")
    :setIgnoreOffset(true)
    :onClick(function() switchScreen(-1) end)
    :setVisible(false)

-- Screen 1: Welcome
local welcomeScreen = createScreen(1)
welcomeScreen:addLabel(coloring)
    :setText("Welcome to CogMail Client!")
    :setPosition(2, 2)

welcomeScreen:addLabel(coloring)
    :setWidth("{parent.width - 2}")
    :setAutoSize(false)
    :setText([[CogMail is an email client for ComputerCraft that allows you to send and receive emails through a network.

This installer will help you:
• Download and install the client
• Configure installation settings
• Set up automatic startup (optional)

The client requires a modem to communicate with the email server. Make sure you have a modem attached and the server is running before using the client.

Let's get started!]])
    :setPosition(2, 4)

-- Screen 2: Configuration
local configScreen = createScreen(2)
configScreen:addLabel(coloring)
    :setText("Configuration")
    :setPosition(2, 2)

configScreen:addLabel(coloring)
    :setText("Installation Path:")
    :setPosition(2, 4)

local installPathInput = configScreen:addInput()
    :setPosition(2, 5)
    :setSize("{parent.width - 4}", 1)
    :setBackground(colors.black)
    :setForeground(colors.white)
    :setPlaceholder("mailingClient.lua")
    :setText("mailingClient.lua")

local startupCheckbox = configScreen:addCheckBox(coloring)
    :setText("[ ] Open client on startup")
    :setCheckedText("[x] Open client on startup")
    :setPosition(2, 7)
    :setChecked(false)

-- Screen 3: Installation Progress
local progressScreen = createScreen(3)
local installButton
local currentlyInstalling = false

local progressBar = progressScreen:addProgressBar()
    :setPosition(2, "{parent.height - 2}")
    :setSize("{parent.width - 12}", 2)

local log = progressScreen:addList("log")
    :setPosition(2, 2)
    :setSize("{parent.width - 2}", "{parent.height - 6}")
    :addItem("Ready to install...")

local function logMessage(log, message)
    log:addItem(message)
    log:scrollToBottom()
end

local function updateProgress(progressBar, percent)
    progressBar:setProgress(percent)
end

local function installClient()
    currentlyInstalling = true
    installButton:setVisible(false)
    
    local installPath = installPathInput:getText()
    if installPath == "" then
        installPath = "mailingClient.lua"
    end
    installPath = installPath:gsub(".lua", "") .. ".lua"
    
    local runOnStartup = startupCheckbox:getChecked()
    
    logMessage(log, "Starting installation...")
    updateProgress(progressBar, 10)
    
    -- Download client
    logMessage(log, "Downloading client from repository...")
    local request = http.get(clientUrl)
    if not request then
        logMessage(log, "Error: Failed to download client")
        logMessage(log, "Please check your internet connection and try again.")
        currentlyInstalling = false
        installButton:setVisible(true)
        return
    end
    
    updateProgress(progressBar, 50)
    logMessage(log, "Client downloaded successfully")
    
    -- Save client file
    logMessage(log, "Installing client to " .. installPath .. "...")
    local file = fs.open(installPath, "w")
    if not file then
        logMessage(log, "Error: Could not write to " .. installPath)
        currentlyInstalling = false
        installButton:setVisible(true)
        return
    end
    
    file.write(request.readAll())
    file.close()
    request.close()
    updateProgress(progressBar, 70)
    logMessage(log, "Client file installed")
    
    updateProgress(progressBar, 85)
    
    -- Create startup file if requested
    if runOnStartup then
        logMessage(log, "Creating startup file...")
        local startupContent = "-- Auto-start Email Client\n"
        startupContent = startupContent .. 'local client = require("' .. installPath:gsub(".lua", "") .. '")\n'
        startupContent = startupContent .. "client.runClient()\n"
        
        local startupFile = fs.open("startup.lua", "w")
        if startupFile then
            startupFile.write(startupContent)
            startupFile.close()
            logMessage(log, "Startup file created (startup.lua)")
        else
            logMessage(log, "Warning: Could not create startup.lua")
        end
    end
    
    updateProgress(progressBar, 100)
    logMessage(log, "")
    logMessage(log, "Installation complete!")
    logMessage(log, "")
    logMessage(log, "Client installed to: " .. installPath)
    if runOnStartup then
        logMessage(log, "Client will open automatically on boot")
        logMessage(log, "")
        logMessage(log, "Rebooting in 3 seconds...")
        currentlyInstalling = false
        installButton:setVisible(true)
        
        -- Wait a bit so user can see the message, then reboot
        basalt.schedule(function()
            sleep(3)
            os.reboot()
        end)
    else
        logMessage(log, "To run manually:")
        logMessage(log, '  local client = require("' .. installPath:gsub(".lua", "") .. '")')
        logMessage(log, "  client.runClient()")
        currentlyInstalling = false
        installButton:setVisible(true)
    end
end

installButton = progressScreen:addButton()
    :setBackground("{self.clicked and colors.lightGray or colors.black}")
    :setForeground("{self.clicked and colors.black or colors.lightGray}")
    :setText("Install")
    :setPosition("{parent.width - 9}", "{parent.height - 3}")
    :setSize(9, 1)
    :onClick(function(self)
        if currentlyInstalling then
            return
        end
        basalt.schedule(installClient)
    end)

local closeButton = progressScreen:addButton()
    :setBackground("{self.clicked and colors.lightGray or colors.black}")
    :setForeground("{self.clicked and colors.black or colors.lightGray}")
    :setText("Close")
    :setPosition("{parent.width - 9}", "{parent.height - 1}")
    :setSize(9, 1)
    :onClick(function(self)
        basalt.stop()
    end)

basalt.run()

