-- Email Server Installer
-- Download and install the CogMail email server

-- TODO: Replace with your actual GitHub repository URL
local serverUrl = "https://raw.githubusercontent.com/atefMck/CogMail/refs/heads/main/build/mailingServer.lua"
local basaltUrl = "https://raw.githubusercontent.com/Pyroxenium/Basalt2/refs/heads/main/release/basalt-full.lua"

local args = {...}

-- Help command
if (args[1] == "-h") or (args[1] == "--help") then
    print("Usage: installServer.lua [options]")
    print("Options:")
    print("  -h, --help        Show this help message")
    print("  -q, --quick       Quick install with defaults (no GUI)")
    return
end

-- Quick install mode (no GUI)
if (args[1] == "-q") or (args[1] == "--quick") then
    print("Quick installing email server...")
    
    -- Download server
    print("Downloading server...")
    local request = http.get(serverUrl)
    if not request then
        error("Failed to download server")
    end
    
    local installPath = args[2] or "mailingServer.lua"
    local file = fs.open(installPath, "w")
    file.write(request.readAll())
    file.close()
    request.close()
    
    -- Configure settings
    settings.define("email.encryption_key", {
        description = "Encryption key for email server data",
        default = "email_server_key_2024",
        type = "string"
    })
    
    settings.define("email.password_salt", {
        description = "Salt key for password hashing",
        default = "email_server_salt_2024",
        type = "string"
    })
    
    settings.load()
    settings.save()
    
    print("Server installed to: " .. installPath)
    print("To run: local server = require(\"" .. installPath:gsub(".lua", "") .. "\"); server.runServer()")
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
    basalt = load(basaltRequest.readAll(), "basalt", "bt", _ENV)()
    basaltRequest.close()
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
    :setText("Welcome to CogMail Server!")
    :setPosition(2, 2)

welcomeScreen:addLabel(coloring)
    :setWidth("{parent.width - 2}")
    :setAutoSize(false)
    :setText([[CogMail is an email server for ComputerCraft that allows computers to send and receive emails through a network.

This installer will help you:
• Download and install the server
• Configure encryption and password settings
• Set up automatic startup (optional)

The server requires a modem to communicate with clients. Make sure you have a modem attached before running the server.

Let's get started!]])
    :setPosition(2, 4)

-- Screen 2: Configuration
local configScreen = createScreen(2)
configScreen:addLabel(coloring)
    :setText("Configuration")
    :setPosition(2, 2)

configScreen:addLabel(coloring)
    :setText("Encryption Key:")
    :setPosition(2, 4)

local encryptionKeyInput = configScreen:addInput()
    :setPosition(2, 5)
    :setSize("{parent.width - 4}", 1)
    :setBackground(colors.black)
    :setForeground(colors.white)
    :setPlaceholder("email_server_key_2024")
    :setText("email_server_key_2024")

configScreen:addLabel(coloring)
    :setText("Password Salt:")
    :setPosition(2, 7)

local passwordSaltInput = configScreen:addInput()
    :setPosition(2, 8)
    :setSize("{parent.width - 4}", 1)
    :setBackground(colors.black)
    :setForeground(colors.white)
    :setPlaceholder("email_server_salt_2024")
    :setText("email_server_salt_2024")

configScreen:addLabel(coloring)
    :setText("Installation Path:")
    :setPosition(2, 10)

local installPathInput = configScreen:addInput()
    :setPosition(2, 11)
    :setSize("{parent.width - 4}", 1)
    :setBackground(colors.black)
    :setForeground(colors.white)
    :setPlaceholder("mailingServer.lua")
    :setText("mailingServer.lua")

local startupCheckbox = configScreen:addCheckBox(coloring)
    :setText("[ ] Run server on startup")
    :setCheckedText("[x] Run server on startup")
    :setPosition(2, 13)
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

local function installServer()
    currentlyInstalling = true
    installButton:setVisible(false)
    
    local encryptionKey = encryptionKeyInput:getText()
    if encryptionKey == "" then
        encryptionKey = "email_server_key_2024"
    end
    
    local passwordSalt = passwordSaltInput:getText()
    if passwordSalt == "" then
        passwordSalt = "email_server_salt_2024"
    end
    
    local installPath = installPathInput:getText()
    if installPath == "" then
        installPath = "mailingServer.lua"
    end
    installPath = installPath:gsub(".lua", "") .. ".lua"
    
    local runOnStartup = startupCheckbox:getChecked()
    
    logMessage(log, "Starting installation...")
    updateProgress(progressBar, 10)
    
    -- Download server
    logMessage(log, "Downloading server from repository...")
    local request = http.get(serverUrl)
    if not request then
        logMessage(log, "Error: Failed to download server")
        logMessage(log, "Please check your internet connection and try again.")
        currentlyInstalling = false
        installButton:setVisible(true)
        return
    end
    
    updateProgress(progressBar, 50)
    logMessage(log, "Server downloaded successfully")
    
    -- Save server file
    logMessage(log, "Installing server to " .. installPath .. "...")
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
    logMessage(log, "Server file installed")
    
    -- Configure settings
    logMessage(log, "Configuring settings...")
    settings.define("email.encryption_key", {
        description = "Encryption key for email server data",
        default = "email_server_key_2024",
        type = "string"
    })
    
    settings.define("email.password_salt", {
        description = "Salt key for password hashing",
        default = "email_server_salt_2024",
        type = "string"
    })
    
    settings.load()
    settings.set("email.encryption_key", encryptionKey)
    settings.set("email.password_salt", passwordSalt)
    
    if settings.save() then
        logMessage(log, "Settings configured and saved")
    else
        logMessage(log, "Warning: Could not save settings file")
    end
    
    updateProgress(progressBar, 85)
    
    -- Create startup file if requested
    if runOnStartup then
        logMessage(log, "Creating startup file...")
        local startupContent = "-- Auto-start Email Server\n"
        startupContent = startupContent .. 'local server = require("' .. installPath:gsub(".lua", "") .. '")\n'
        startupContent = startupContent .. "server.runServer()\n"
        
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
    logMessage(log, "Server installed to: " .. installPath)
    logMessage(log, "Encryption Key: " .. encryptionKey)
    logMessage(log, "Password Salt: " .. passwordSalt)
    if runOnStartup then
        logMessage(log, "Server will start automatically on boot")
    else
        logMessage(log, "To run manually:")
        logMessage(log, '  local server = require("' .. installPath:gsub(".lua", "") .. '")')
        logMessage(log, "  server.runServer()")
    end
    
    currentlyInstalling = false
    installButton:setVisible(true)
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
        basalt.schedule(installServer)
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
