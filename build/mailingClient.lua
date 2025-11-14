-- Bundled Email Client
-- This file contains all client modules bundled together

-- ============================================================================
-- Network Communication Module
-- ============================================================================
local Network = {}
local modem = peripheral.find("modem") or error("No modem attached", 0)
local SERVER_CHANNEL = 100
local CLIENT_CHANNEL = 200

-- Open both channels - server channel for sending requests, client channel for receiving responses
modem.open(SERVER_CHANNEL)
modem.open(CLIENT_CHANNEL)

function Network.sendRequest(requestType, data, timeout)
    timeout = timeout or 5
    local request = {
        type = requestType
    }
    
    -- Merge data into request
    for k, v in pairs(data) do
        request[k] = v
    end
    
    -- Send request
    modem.transmit(SERVER_CHANNEL, CLIENT_CHANNEL, request)
    
    -- Wait for response with timeout
    local startTime = os.clock()
    local event, side, channel, replyChannel, message, distance
    
    while true do
        local elapsed = os.clock() - startTime
        if elapsed > timeout then
            return nil, "Request timeout"
        end
        
        event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
        
        if channel == CLIENT_CHANNEL then
            return message, nil
        end
    end
end

function Network.createAccount(username, password)
    local response, err = Network.sendRequest("create_account", {
        username = username,
        password = password
    })
    
    if err then
        return false, tostring(err)
    end
    
    if not response then
        return false, "No response from server"
    end
    
    if response.success then
        return true, response.account
    else
        local errorMsg = "Unknown error"
        if response.message then
            errorMsg = tostring(response.message)
        elseif type(response) == "string" then
            errorMsg = response
        end
        return false, errorMsg
    end
end

function Network.login(username, password)
    local response, err = Network.sendRequest("login", {
        username = username,
        password = password
    })
    
    if err then
        return false, tostring(err)
    end
    
    if not response then
        return false, "No response from server"
    end
    
    if response.success then
        return true, response.account
    else
        local errorMsg = "Unknown error"
        if response.message then
            errorMsg = tostring(response.message)
        elseif type(response) == "string" then
            errorMsg = response
        end
        return false, errorMsg
    end
end

function Network.sendEmail(fromId, toUsername, subject, body)
    local response, err = Network.sendRequest("send_email", {
        fromId = fromId,
        toUsername = toUsername,
        subject = subject,
        body = body
    })
    
    if err then
        return false, tostring(err)
    end
    
    if not response then
        return false, "No response from server"
    end
    
    if response.success then
        return true, response.email
    else
        local errorMsg = "Unknown error"
        if response.message then
            errorMsg = tostring(response.message)
        elseif type(response) == "string" then
            errorMsg = response
        end
        return false, errorMsg
    end
end

function Network.getInbox(accountId)
    local response, err = Network.sendRequest("get_inbox", {
        accountId = accountId
    })
    
    if err then
        return false, tostring(err)
    end
    
    if not response then
        return false, "No response from server"
    end
    
    if response.success then
        return true, response.inbox
    else
        local errorMsg = "Unknown error"
        if response.message then
            errorMsg = tostring(response.message)
        elseif type(response) == "string" then
            errorMsg = response
        end
        return false, errorMsg
    end
end

function Network.getEmail(emailId, accountId)
    local response, err = Network.sendRequest("get_email", {
        emailId = emailId,
        accountId = accountId
    })
    
    if err then
        return false, err
    end
    
    if not response then
        return false, "No response from server"
    end
    
    if response.success then
        return true, response.email
    else
        local errorMsg = "Unknown error"
        if response.message then
            errorMsg = tostring(response.message)
        elseif type(response) == "string" then
            errorMsg = response
        end
        return false, errorMsg
    end
end

function Network.deleteEmail(emailId, accountId)
    local response, err = Network.sendRequest("delete_email", {
        emailId = emailId,
        accountId = accountId
    })
    
    if err then
        return false, tostring(err)
    end
    
    if not response then
        return false, "No response from server"
    end
    
    if response.success then
        return true
    else
        local errorMsg = "Unknown error"
        if response.message then
            errorMsg = tostring(response.message)
        elseif type(response) == "string" then
            errorMsg = response
        end
        return false, errorMsg
    end
end

function Network.getAllUsernames()
    local response, err = Network.sendRequest("get_all_usernames", {})
    
    if err then
        return false, err
    end
    
    if not response then
        return false, "No response from server"
    end
    
    if response.success then
        return true, response.usernames or {}
    else
        local errorMsg = "Unknown error"
        if response.message then
            errorMsg = tostring(response.message)
        elseif type(response) == "string" then
            errorMsg = response
        end
        return false, errorMsg
    end
end

-- ============================================================================
-- Utility Module
-- ============================================================================
local Utils = {}

function Utils.getTerminalSize()
    local termObj = term.current()
    if termObj and termObj.getSize then
        return termObj.getSize()
    end
    -- Fallback to default size if term.current() doesn't work
    return 51, 19
end

function Utils.getResponsiveLayout()
    local width, height = Utils.getTerminalSize()
    
    return {
        width = width,
        height = height,
        -- Common spacing
        margin = 2,
        -- Button dimensions
        buttonHeight = math.max(1, math.floor(height / 15)),
        buttonWidth = math.max(10, math.floor(width / 3)),
        -- Input dimensions
        inputWidth = math.max(20, width - 4),
        inputHeight = 1,
        -- Label spacing
        labelSpacing = math.max(2, math.floor(height / 12)),
        -- Status label position
        statusY = math.max(10, height - 5),
        -- Button row position
        buttonY = math.max(12, height - 3)
    }
end

-- ============================================================================
-- Email View Screen Module
-- ============================================================================
local EmailView = {}

function EmailView.create(mainFrame, emailId, accountId, onBack)
    local basalt = require("basalt")
    local screen = mainFrame:addFrame()
        :setSize("{parent.width}", "{parent.height}")
        :setPosition(1, 1)
        :setBackground(colors.black)
    
    local emailLayout = Utils.getResponsiveLayout()
    
    -- Header section (responsive height)
    local headerY = emailLayout.margin
    local headerHeight = math.max(5, math.floor(emailLayout.height / 5))
    local headerFrame = screen:addFrame({x = 1, y = 1, width = "{parent.width}", height = headerHeight})
        :setBackground(colors.blue)
    
    -- Loading label
    local loadingLabel = headerFrame:addLabel({text = "Loading email...", x = emailLayout.margin, y = headerY, foreground = colors.yellow})
    
    -- Function to display email data
    local function displayEmail(emailData)
        loadingLabel:setText("")  -- Clear loading message
        
        -- Email metadata
        local metaY = headerY
        headerFrame:addLabel({text = "From:", x = emailLayout.margin, y = metaY, foreground = colors.lightGray})
        headerFrame:addLabel({text = emailData.fromUsername or "Unknown", x = emailLayout.margin + 6, y = metaY, foreground = colors.white})
        
        metaY = metaY + 1
        headerFrame:addLabel({text = "To:", x = emailLayout.margin, y = metaY, foreground = colors.lightGray})
        headerFrame:addLabel({text = emailData.toUsername or "Unknown", x = emailLayout.margin + 6, y = metaY, foreground = colors.white})
        
        metaY = metaY + 1
        headerFrame:addLabel({text = "Subject:", x = emailLayout.margin, y = metaY, foreground = colors.lightGray})
        local subjectText = emailData.subject or "(No Subject)"
        -- Truncate subject if too long
        if #subjectText > emailLayout.width - emailLayout.margin - 10 then
            subjectText = subjectText:sub(1, emailLayout.width - emailLayout.margin - 13) .. "..."
        end
        headerFrame:addLabel({text = subjectText, x = emailLayout.margin + 9, y = metaY, foreground = colors.white})
        
        metaY = metaY + 1
        local dateStr = os.date("%Y-%m-%d %H:%M:%S", emailData.timestamp)
        headerFrame:addLabel({text = "Date:", x = emailLayout.margin, y = metaY, foreground = colors.lightGray})
        headerFrame:addLabel({text = dateStr, x = emailLayout.margin + 6, y = metaY, foreground = colors.lightGray})
        
        -- Body section
        local bodyStartY = headerHeight + 1
        local bodyHeight = emailLayout.height - bodyStartY - emailLayout.buttonHeight - 2
        local bodyFrame = screen:addFrame({x = emailLayout.margin, y = bodyStartY, width = emailLayout.width - (emailLayout.margin * 2), height = bodyHeight})
            :setBackground(colors.gray)
        
        -- Body label
        screen:addLabel({text = "Message:", x = emailLayout.margin, y = bodyStartY - 1, foreground = colors.lightGray})
        
        -- Body text in a scrollable text box
        local bodyText = bodyFrame:addTextBox({x = 1, y = 1, width = "{parent.width}", height = "{parent.height}"})
            :setText(emailData.body or "(No message body)")
            :setBackground(colors.gray)
            :setForeground(colors.white)
            :setEditable(false)
        
        -- Buttons at bottom
        local buttonY = emailLayout.height - emailLayout.buttonHeight
        
        -- Back button
        local backBtn = screen:addButton({text = "Back to Inbox", x = emailLayout.margin, y = buttonY, width = emailLayout.buttonWidth, height = emailLayout.buttonHeight})
            :setBackground(colors.blue)
            :setForeground(colors.white)
            :onClick(function()
                if screen and screen.destroy then
                    screen:destroy()
                end
                if onBack then
                    onBack()
                end
            end)
        
        -- Delete button
        local deleteBtnX = emailLayout.margin + emailLayout.buttonWidth + 2
        local deleteBtn = screen:addButton({text = "Delete", x = deleteBtnX, y = buttonY, width = emailLayout.buttonWidth, height = emailLayout.buttonHeight})
            :setBackground(colors.red)
            :setForeground(colors.white)
            :onClick(function()
                Network.deleteEmail(emailId, accountId)
                if screen and screen.destroy then
                    screen:destroy()
                end
                if onBack then
                    onBack()
                end
            end)
    end
    
    -- Function to handle error
    local function displayError(errorMsg)
        loadingLabel:setText("Error loading email: " .. tostring(errorMsg or "Unknown error"))
            :setForeground(colors.red)
        
        -- Back button on error
        local buttonY = emailLayout.height - emailLayout.buttonHeight
        local backBtn = screen:addButton({text = "Back to Inbox", x = emailLayout.margin, y = buttonY, width = emailLayout.buttonWidth, height = emailLayout.buttonHeight})
            :setBackground(colors.blue)
            :setForeground(colors.white)
            :onClick(function()
                if screen and screen.destroy then
                    screen:destroy()
                end
                if onBack then
                    onBack()
                end
            end)
    end
    
    -- Load email data asynchronously to prevent blocking
    basalt.schedule(function()
        -- Update loading message to show we're trying
        loadingLabel:setText("Loading email... (connecting to server)")
            :setForeground(colors.yellow)
        
        local success, emailData = Network.getEmail(emailId, accountId)
        if success and emailData then
            displayEmail(emailData)
        else
            -- Check if it's a timeout error
            local errorMsg = tostring(emailData or "Unknown error")
            if errorMsg:find("timeout") or errorMsg:find("Request timeout") then
                errorMsg = "Server not responding. Please check if the server is running."
            end
            displayError(errorMsg)
        end
    end)
    
    return screen
end

-- ============================================================================
-- Account Creation Screen Module
-- ============================================================================
local AccountCreation = {}
local basalt = require("basalt")

-- Helper function to draw CogMail logo (text only)
local function drawLogoAccount(parent, x, y, foregroundColor)
    foregroundColor = foregroundColor or colors.orange
    -- Draw "CogMail" text only
    parent:addLabel({text = "CogMail", x = x, y = y, foreground = foregroundColor})
end

-- Helper function to safely convert anything to a string
local function safeToString(value)
    if value == nil then
        return ""
    elseif type(value) == "string" then
        return value
    elseif type(value) == "table" then
        if value.message then
            return tostring(value.message)
        else
            return "table"
        end
    else
        return tostring(value)
    end
end

function AccountCreation.create(mainFrame, onSuccess, onBackToLogin)
    local layout = Utils.getResponsiveLayout()
    local screen = mainFrame:addFrame()
        :setSize("{parent.width}", "{parent.height}")
        :setPosition(1, 1)
        :setBackground(colors.black)
    
    -- Draw logo at top center
    local logoX = math.max(1, math.floor((layout.width - 7) / 2))
    local logoY = layout.margin
    drawLogoAccount(screen, logoX, logoY, colors.orange)
    
    -- Calculate positions (adjusted for logo)
    local titleY = logoY + 2
    local usernameLabelY = titleY + layout.labelSpacing
    local usernameInputY = usernameLabelY + 1
    local passwordLabelY = usernameInputY + layout.labelSpacing
    local passwordInputY = passwordLabelY + 1
    local confirmLabelY = passwordInputY + layout.labelSpacing
    local confirmInputY = confirmLabelY + 1
    local statusY = confirmInputY + layout.labelSpacing
    local buttonY = layout.buttonY
    
    -- Title (smaller, since we have logo)
    screen:addLabel({text = "Create Account", x = layout.margin, y = titleY, foreground = colors.lightGray})
    
    -- Username input
    screen:addLabel({text = "Username:", x = layout.margin, y = usernameLabelY, foreground = colors.lightGray})
    local usernameInput = screen:addInput({x = layout.margin, y = usernameInputY, width = layout.inputWidth, height = layout.inputHeight})
        :setBackground(colors.gray)
        :setForeground(colors.white)
    
    -- Password input
    screen:addLabel({text = "Password:", x = layout.margin, y = passwordLabelY, foreground = colors.lightGray})
    local passwordInput = screen:addInput({x = layout.margin, y = passwordInputY, width = layout.inputWidth, height = layout.inputHeight})
        :setBackground(colors.gray)
        :setForeground(colors.white)
        :setReplaceChar("*")
    
    -- Confirm password input
    screen:addLabel({text = "Confirm Password:", x = layout.margin, y = confirmLabelY, foreground = colors.lightGray})
    local confirmInput = screen:addInput({x = layout.margin, y = confirmInputY, width = layout.inputWidth, height = layout.inputHeight})
        :setBackground(colors.gray)
        :setForeground(colors.white)
        :setReplaceChar("*")
    
    -- Status label
    local statusLabel = screen:addLabel({text = "", x = layout.margin, y = statusY, width = layout.inputWidth, height = 1})
        :setForeground(colors.red)
    
    -- Create button
    local createBtn = screen:addButton({text = "Create Account", x = layout.margin, y = buttonY, width = layout.buttonWidth, height = layout.buttonHeight})
        :setBackground(colors.green)
        :setForeground(colors.white)
        :onClick(function()
            -- Get input values directly from the text property
            local usernameRaw = usernameInput.text
            local passwordRaw = passwordInput.text
            local confirmRaw = confirmInput.text
            
            -- Convert to strings using safe helper
            local username = safeToString(usernameRaw)
            local password = safeToString(passwordRaw)
            local confirm = safeToString(confirmRaw)
            
            -- Validation
            if not username or username == "" then
                statusLabel:setText("Username cannot be empty")
                    :setForeground(colors.red)
                return
            end
            
            if type(username) ~= "string" or #username < 3 then
                statusLabel:setText("Username must be at least 3 characters")
                    :setForeground(colors.red)
                return
            end
            
            if not password or password == "" then
                statusLabel:setText("Password cannot be empty")
                    :setForeground(colors.red)
                return
            end
            
            if type(password) ~= "string" or #password < 4 then
                statusLabel:setText("Password must be at least 4 characters")
                    :setForeground(colors.red)
                return
            end
            
            if type(password) ~= "string" or type(confirm) ~= "string" or password ~= confirm then
                statusLabel:setText("Passwords do not match")
                    :setForeground(colors.red)
                return
            end
            
            -- Create account
            statusLabel:setText("Creating account...")
                :setForeground(colors.yellow)
            
            local success, result = Network.createAccount(username, password)
            
            if success then
                statusLabel:setText("Account created successfully! Redirecting to login...")
                    :setForeground(colors.green)
                -- Wait a moment then redirect to login using basalt.schedule
                basalt.schedule(function()
                    sleep(1.5)
                    -- Destroy this screen and go back to login
                    if screen and screen.destroy then
                        screen:destroy()
                    end
                    if onBackToLogin then
                        onBackToLogin()
                    end
                end)
            else
                -- Use safe conversion for error message
                local errorMsg = safeToString(result)
                if errorMsg == "" then
                    errorMsg = "Unknown error"
                end
                local finalErrorText = "Error: " .. errorMsg
                statusLabel:setText(finalErrorText)
                    :setForeground(colors.red)
            end
        end)
    
    -- Back button
    local backBtnX = layout.margin + layout.buttonWidth + 2
    local backBtn = screen:addButton({text = "Back", x = backBtnX, y = buttonY, width = layout.buttonWidth, height = layout.buttonHeight})
        :setBackground(colors.red)
        :setForeground(colors.white)
        :onClick(function()
            -- Destroy this screen and go back to login
            if screen and screen.destroy then
                screen:destroy()
            end
            if onBackToLogin then
                onBackToLogin()
            end
        end)
    
    return screen
end

-- ============================================================================
-- Login Screen Module
-- ============================================================================
local Login = {}

-- Helper function to draw CogMail logo (text only)
local function drawLogo(parent, x, y, foregroundColor)
    foregroundColor = foregroundColor or colors.orange
    -- Draw "CogMail" text only
    parent:addLabel({text = "CogMail", x = x, y = y, foreground = foregroundColor})
end

function Login.create(mainFrame, onSuccess, onBackToLogin)
    local layout = Utils.getResponsiveLayout()
    local screen = mainFrame:addFrame()
        :setSize("{parent.width}", "{parent.height}")
        :setPosition(1, 1)
        :setBackground(colors.black)
    
    -- Draw logo at top center
    local logoX = math.max(1, math.floor((layout.width - 7) / 2))
    local logoY = layout.margin
    drawLogo(screen, logoX, logoY, colors.orange)
    
    -- Calculate positions (adjusted for logo)
    local titleY = logoY + 2
    local usernameLabelY = titleY + layout.labelSpacing
    local usernameInputY = usernameLabelY + 1
    local passwordLabelY = usernameInputY + layout.labelSpacing
    local passwordInputY = passwordLabelY + 1
    local statusY = passwordInputY + layout.labelSpacing
    local buttonY = layout.buttonY
    
    -- Title (smaller, since we have logo)
    screen:addLabel({text = "Login", x = layout.margin, y = titleY, foreground = colors.lightGray})
    
    -- Username input
    screen:addLabel({text = "Username:", x = layout.margin, y = usernameLabelY, foreground = colors.lightGray})
    local usernameInput = screen:addInput({x = layout.margin, y = usernameInputY, width = layout.inputWidth, height = layout.inputHeight})
        :setBackground(colors.gray)
        :setForeground(colors.white)
    
    -- Password input
    screen:addLabel({text = "Password:", x = layout.margin, y = passwordLabelY, foreground = colors.lightGray})
    local passwordInput = screen:addInput({x = layout.margin, y = passwordInputY, width = layout.inputWidth, height = layout.inputHeight})
        :setBackground(colors.gray)
        :setForeground(colors.white)
        :setReplaceChar("*")
    
    -- Status label
    local statusLabel = screen:addLabel({text = "", x = layout.margin, y = statusY, width = layout.inputWidth, height = 1})
        :setForeground(colors.red)
    
    -- Login button
    local loginBtn = screen:addButton({text = "Login", x = layout.margin, y = buttonY, width = layout.buttonWidth, height = layout.buttonHeight})
        :setBackground(colors.green)
        :setForeground(colors.white)
        :onClick(function()
            local username = usernameInput.text or ""
            local password = passwordInput.text or ""
            
            if not username or username == "" then
                statusLabel:setText("Username cannot be empty")
                    :setForeground(colors.red)
                return
            end
            
            if not password or password == "" then
                statusLabel:setText("Password cannot be empty")
                    :setForeground(colors.red)
                return
            end
            
            statusLabel:setText("Logging in...")
                :setForeground(colors.yellow)
            
            local success, result = Network.login(username, password)
            
            if success then
                statusLabel:setText("Login successful!")
                    :setForeground(colors.green)
                if onSuccess then
                    onSuccess(result)
                end
            else
                local errorMsg = tostring(result or "Unknown error")
                statusLabel:setText("Error: " .. errorMsg)
                    :setForeground(colors.red)
            end
        end)
    
    -- Create account button
    local createBtnX = layout.margin + layout.buttonWidth + 2
    local createBtn = screen:addButton({text = "Create Account", x = createBtnX, y = buttonY, width = layout.buttonWidth, height = layout.buttonHeight})
        :setBackground(colors.blue)
        :setForeground(colors.white)
        :onClick(function()
            -- Destroy the current screen
            if screen and screen.destroy then
                screen:destroy()
            end
            -- Pass callback to go back to login after account creation
            AccountCreation.create(mainFrame, onSuccess, onBackToLogin or function()
                -- Default: recreate login screen if no callback provided
                Login.create(mainFrame, onSuccess, onBackToLogin)
            end)
        end)
    
    return screen
end

-- ============================================================================
-- Compose Screen Module
-- ============================================================================
local Compose = {}

function Compose.create(mainFrame, account, onSent)
    local layout = Utils.getResponsiveLayout()
    local screen = mainFrame:addFrame()
        :setSize("{parent.width}", "{parent.height}")
        :setPosition(1, 1)
        :setBackground(colors.black)
    
    -- Store references in a table to ensure they persist in closures
    local refs = {}
    
    -- Calculate positions
    local titleY = layout.margin
    local toLabelY = titleY + layout.labelSpacing
    local toInputY = toLabelY + 1
    local subjectLabelY = toInputY + layout.labelSpacing + 1
    local subjectInputY = subjectLabelY + 1
    local bodyLabelY = subjectInputY + layout.labelSpacing
    local bodyInputY = bodyLabelY + 1
    local bodyHeight = math.max(5, layout.height - bodyInputY - layout.buttonHeight - 4)
    local statusY = bodyInputY + bodyHeight + 1
    local buttonY = layout.buttonY
    
    -- Title
    screen:addLabel({text = "Compose Email", x = layout.margin, y = titleY, foreground = colors.white})
    
    -- To field - using ComboBox for account selection
    screen:addLabel({text = "To:", x = layout.margin, y = toLabelY, foreground = colors.lightGray})
    local toComboBox = screen:addComboBox({x = layout.margin, y = toInputY, width = layout.inputWidth, height = 1})
        :setBackground(colors.gray)
        :setForeground(colors.white)
        :setSelectedText("Select recipient...")
        :setAutoComplete(true)
    refs.toComboBox = toComboBox
    
    -- Load usernames asynchronously
    basalt.schedule(function()
        local success, usernames = Network.getAllUsernames()
        if success and usernames then
            -- Filter out current user's username
            local recipientList = {}
            for _, username in ipairs(usernames) do
                if username ~= account.username then
                    table.insert(recipientList, {text = username})
                end
            end
            if refs.toComboBox then
                refs.toComboBox:setItems(recipientList)
            end
        end
    end)
    
    -- Subject field
    screen:addLabel({text = "Subject:", x = layout.margin, y = subjectLabelY, foreground = colors.lightGray})
    local subjectInput = screen:addInput({x = layout.margin, y = subjectInputY, width = layout.inputWidth, height = layout.inputHeight})
        :setBackground(colors.gray)
        :setForeground(colors.white)
    refs.subjectInput = subjectInput
    
    -- Body field
    screen:addLabel({text = "Message:", x = layout.margin, y = bodyLabelY, foreground = colors.lightGray})
    local bodyInput = screen:addTextBox({x = layout.margin, y = bodyInputY, width = layout.inputWidth, height = bodyHeight})
        :setBackground(colors.gray)
        :setForeground(colors.white)
    refs.bodyInput = bodyInput
    
    -- Status label
    local statusLabel = screen:addLabel({text = "", x = layout.margin, y = statusY, width = layout.inputWidth, height = 1})
        :setForeground(colors.red)
    refs.statusLabel = statusLabel
    
    -- Send button
    local sendBtn = screen:addButton({text = "Send", x = layout.margin, y = buttonY, width = layout.buttonWidth, height = layout.buttonHeight})
        :setBackground(colors.green)
        :setForeground(colors.white)
    refs.sendBtn = sendBtn
    
    sendBtn:onClick(function()
            -- Get selected username from ComboBox
            local to = ""
            local selectedItem = refs.toComboBox:getSelectedItem()
            if selectedItem and selectedItem.text then
                to = selectedItem.text
            else
                -- Fallback to text property if user typed manually (editable mode)
                to = refs.toComboBox.text or ""
            end
            
            local subject = refs.subjectInput.text or ""
            local body = refs.bodyInput:getText() or ""
            
            if not to or to == "" then
                refs.statusLabel:setText("Please select a recipient")
                    :setForeground(colors.red)
                return
            end
            
            if not subject or subject == "" then
                refs.statusLabel:setText("Subject cannot be empty")
                    :setForeground(colors.red)
                return
            end
            
            if not body or body == "" then
                refs.statusLabel:setText("Message cannot be empty")
                    :setForeground(colors.red)
                return
            end
            
            refs.statusLabel:setText("Sending email...")
                :setForeground(colors.yellow)
            
            -- Disable send button during send to prevent multiple sends
            if refs.sendBtn then
                refs.sendBtn:setEnabled(false)
            end
            
            -- Make network call asynchronous to prevent UI blocking
            basalt.schedule(function()
                local success, result = Network.sendEmail(account.id, to, subject, body)
                
                -- Re-enable send button
                if refs.sendBtn then
                    refs.sendBtn:setEnabled(true)
                end
                
                if success then
                    refs.statusLabel:setText("Email sent successfully!")
                        :setForeground(colors.green)
                    
                    -- Clear form
                    refs.toComboBox:setText("")
                    refs.toComboBox:selectItem(0)  -- Clear selection
                    refs.subjectInput:setText("")
                    refs.bodyInput:setText("")
                    
                    -- Call callback immediately - user can see success message before navigating
                    if onSent then
                        onSent()
                    end
                else
                    local errorMsg = tostring(result or "Unknown error")
                    refs.statusLabel:setText("Error: " .. errorMsg)
                        :setForeground(colors.red)
                end
            end)
        end)
    
    -- Cancel button
    local cancelBtnX = layout.margin + layout.buttonWidth + 2
    local cancelBtn = screen:addButton({text = "Cancel", x = cancelBtnX, y = buttonY, width = layout.buttonWidth, height = layout.buttonHeight})
        :setBackground(colors.red)
        :setForeground(colors.white)
        :onClick(function()
            -- Destroy compose screen first
            if screen and screen.destroy then
                screen:destroy()
            end
            -- Then call callback to return to inbox
            if onSent then
                onSent()
            end
        end)
    
    return screen
end

-- ============================================================================
-- Inbox Screen Module
-- ============================================================================
local Inbox = {}

-- Helper function to draw CogMail text only (for inbox)
local function drawLogoText(parent, x, y, foregroundColor)
    foregroundColor = foregroundColor or colors.orange
    -- Draw "CogMail" text only
    parent:addLabel({text = "CogMail", x = x, y = y, foreground = foregroundColor})
end

function Inbox.create(mainFrame, account, onCompose, onLogout)
    local layout = Utils.getResponsiveLayout()
    local parentFrame = mainFrame
    local screen = mainFrame:addFrame()
        :setSize("{parent.width}", "{parent.height}")
        :setPosition(1, 1)
        :setBackground(colors.black)
    
    -- Header
    local headerHeight = math.max(3, math.floor(layout.height / 6))
    local header = screen:addFrame({x = 1, y = 1, width = "{parent.width}", height = headerHeight})
        :setBackground(colors.blue)
    
    -- Draw logo text in header (no cog icon)
    local logoX = layout.margin
    local logoY = math.floor(headerHeight / 2)
    drawLogoText(header, logoX, logoY, colors.orange)
    
    -- Username label next to logo
    header:addLabel({text = "Inbox - " .. account.username, x = logoX + 8, y = logoY, foreground = colors.white})
    
    -- Buttons in header
    local buttonWidth = math.max(7, math.floor(layout.width / 7))
    local buttonHeight = math.max(1, headerHeight - 1)
    local refreshBtnX = layout.width - (buttonWidth * 3) - 2
    local composeBtnX = layout.width - (buttonWidth * 2) - 1
    local logoutBtnX = layout.width - buttonWidth
    
    local refreshBtn = header:addButton({text = "Refresh", x = refreshBtnX, y = 1, width = buttonWidth, height = buttonHeight})
        :setBackground(colors.green)
        :setForeground(colors.white)
    
    local composeBtn = header:addButton({text = "Compose", x = composeBtnX, y = 1, width = buttonWidth, height = buttonHeight})
        :setBackground(colors.orange)
        :setForeground(colors.white)
        :onClick(function()
            if onCompose then
                onCompose()
            end
        end)
    
    local logoutBtn = header:addButton({text = "Logout", x = logoutBtnX, y = 1, width = buttonWidth, height = buttonHeight})
        :setBackground(colors.red)
        :setForeground(colors.white)
        :onClick(function()
            if screen and screen.destroy then
                screen:destroy()
            end
            if onLogout then
                onLogout()
            end
        end)
    
    -- Email list with pagination
    local listY = headerHeight + 1
    local emailItemHeight = 2  -- Fixed height per email item
    local paginationHeight = 2  -- Space for pagination controls
    local listHeight = layout.height - listY - paginationHeight
    local emailsPerPage = math.max(1, math.floor(listHeight / emailItemHeight))
    
    local listFrame = screen:addFrame({x = 1, y = listY, width = "{parent.width}", height = listHeight})
        :setBackground(colors.black)
    
    local statusLabel = listFrame:addLabel({text = "Loading inbox...", x = layout.margin, y = layout.margin, foreground = colors.yellow})
    
    -- Pagination controls
    local paginationY = listY + listHeight + 1
    local paginationFrame = screen:addFrame({x = 1, y = paginationY, width = "{parent.width}", height = paginationHeight})
        :setBackground(colors.black)
    
    local pageInfoLabel = paginationFrame:addLabel({text = "", x = layout.margin, y = 1, foreground = colors.lightGray})
    
    local prevBtn = paginationFrame:addButton({text = "Prev", x = layout.width - 20, y = 1, width = 8, height = 1})
        :setBackground(colors.blue)
        :setForeground(colors.white)
    
    local nextBtn = paginationFrame:addButton({text = "Next", x = layout.width - 11, y = 1, width = 8, height = 1})
        :setBackground(colors.blue)
        :setForeground(colors.white)
    
    -- Pagination state
    local currentPage = 1
    local allEmails = {}
    local emailItems = {}  -- Store email item frames for easy cleanup
    
    -- Forward declaration
    local loadInbox
    
    -- Function to clear email items
    local function clearEmailItems()
        for _, item in ipairs(emailItems) do
            if item and item.destroy then
                item:destroy()
            end
        end
        emailItems = {}
    end
    
    -- Function to display emails for current page
    local function displayEmails()
        clearEmailItems()
        
        if #allEmails == 0 then
            statusLabel:setText("No emails in inbox")
                :setForeground(colors.lightGray)
            pageInfoLabel:setText("")
            prevBtn:setVisible(false)
            nextBtn:setVisible(false)
            return
        end
        
        statusLabel:setText("")
        
        local totalPages = math.ceil(#allEmails / emailsPerPage)
        currentPage = math.max(1, math.min(currentPage, totalPages))
        
        -- Update pagination info
        pageInfoLabel:setText(string.format("Page %d/%d (%d emails)", currentPage, totalPages, #allEmails))
        
        -- Show/hide pagination buttons
        prevBtn:setVisible(totalPages > 1)
        nextBtn:setVisible(totalPages > 1)
        if currentPage == 1 then
            prevBtn:setEnabled(false)
        else
            prevBtn:setEnabled(true)
        end
        if currentPage >= totalPages then
            nextBtn:setEnabled(false)
        else
            nextBtn:setEnabled(true)
        end
        
        -- Calculate which emails to show
        local startIndex = (currentPage - 1) * emailsPerPage + 1
        local endIndex = math.min(startIndex + emailsPerPage - 1, #allEmails)
        
        -- Display emails for current page
        for i = startIndex, endIndex do
            local email = allEmails[i]
            local itemY = ((i - startIndex) * emailItemHeight) + 1
            
            local fromUsername = email.fromUsername or "Unknown"
            local dateStr = os.date("%Y-%m-%d %H:%M", email.timestamp)
            
            -- Truncate subject if too long
            local subjectText = email.subject or "(No Subject)"
            local maxSubjectLen = layout.width - layout.margin * 2 - 30  -- Leave space for from and date
            if #subjectText > maxSubjectLen then
                subjectText = subjectText:sub(1, maxSubjectLen - 3) .. "..."
            end
            
            -- Create email item frame
            local itemFrame = listFrame:addFrame({x = 1, y = itemY, width = "{parent.width}", height = emailItemHeight})
                :setBackground(email.read and colors.gray or colors.blue)
            
            -- New indicator
            if not email.read then
                itemFrame:addLabel({text = "●", x = layout.margin, y = 1, foreground = colors.yellow})
            end
            
            -- From username
            itemFrame:addLabel({text = fromUsername, x = layout.margin + 2, y = 1, foreground = colors.white})
            
            -- Subject
            itemFrame:addLabel({text = subjectText, x = layout.margin + 15, y = 1, foreground = email.read and colors.white or colors.yellow})
            
            -- Date (right aligned)
            local dateX = layout.width - #dateStr - layout.margin
            itemFrame:addLabel({text = dateStr, x = dateX, y = 1, foreground = colors.lightGray})
            
            -- Click handler - capture email and account in closure
            local emailId = email.id  -- Capture email ID
            local accountId = account.id  -- Capture account ID
            itemFrame:onClick(function()
                -- Make sure account is still valid
                if not account or not account.id then
                    statusLabel:setText("Error: Account session expired")
                        :setForeground(colors.red)
                    return
                end
                
                -- View email - hide inbox screen first
                screen:setVisible(false)
                
                -- Create email view with callback to return to inbox
                EmailView.create(parentFrame, emailId, accountId, function()
                    -- Show inbox again and refresh
                    screen:setVisible(true)
                    loadInbox() -- Refresh to update read status
                end)
            end)
            
            table.insert(emailItems, itemFrame)
        end
    end
    
    -- Pagination button handlers
    prevBtn:onClick(function()
        if currentPage > 1 then
            currentPage = currentPage - 1
            displayEmails()
        end
    end)
    
    nextBtn:onClick(function()
        local totalPages = math.ceil(#allEmails / emailsPerPage)
        if currentPage < totalPages then
            currentPage = currentPage + 1
            displayEmails()
        end
    end)
    
    -- Define loadInbox function (after displayEmails is defined)
    loadInbox = function()
        -- Update status immediately
        statusLabel:setText("Loading inbox...")
            :setForeground(colors.yellow)
        
        -- Disable refresh button during load to prevent multiple simultaneous requests
        refreshBtn:setEnabled(false)
        
        -- Make network call asynchronous to prevent UI blocking
        basalt.schedule(function()
            local success, inbox = Network.getInbox(account.id)
            
            -- Re-enable refresh button
            refreshBtn:setEnabled(true)
            
            if success and inbox then
                if type(inbox) == "table" then
                    allEmails = inbox
                    currentPage = 1  -- Reset to first page
                    displayEmails()
                else
                    -- inbox is not a table (unexpected response)
                    statusLabel:setText("Invalid response from server")
                        :setForeground(colors.red)
                    allEmails = {}
                    displayEmails()
                end
            else
                local errorMsg = tostring(inbox or "Unknown error")
                statusLabel:setText("Error: " .. errorMsg)
                    :setForeground(colors.red)
                allEmails = {}
                displayEmails()
            end
        end)
    end
    
    refreshBtn:onClick(function()
        loadInbox()
    end)
    
    -- Initial load
    loadInbox()
    
    -- Expose refresh function on screen object
    screen.refresh = loadInbox
    
    return screen
end

-- ============================================================================
-- Main Client Function
-- ============================================================================
function runClient()
    local basalt = require("basalt")
    
    -- Check if basalt is available
    if not basalt then
        error("Basalt library not found. Please install Basalt2.")
    end
    
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
end

return { runClient = runClient }

