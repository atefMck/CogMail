-- Account Creation Screen
local AccountCreation = {}
local Network = require("network")
local basalt = require("basalt")
local Utils = require("utils")

-- Helper function to draw CogMail logo (text only)
local function drawLogo(parent, x, y, foregroundColor)
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
    drawLogo(screen, logoX, logoY, colors.orange)
    
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

return AccountCreation

