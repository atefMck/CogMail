-- Login Screen
local Login = {}
local Network = require("network")
local Utils = require("utils")

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
            local AccountCreation = require("screens/account_creation")
            -- Pass callback to go back to login after account creation
            AccountCreation.create(mainFrame, onSuccess, onBackToLogin or function()
                -- Default: recreate login screen if no callback provided
                local Login = require("screens/login")
                Login.create(mainFrame, onSuccess, onBackToLogin)
            end)
        end)
    
    return screen
end

return Login

