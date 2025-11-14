-- Email Detail View Screen
local EmailView = {}
local Network = require("network")
local Utils = require("utils")
local basalt = require("basalt")

function EmailView.create(mainFrame, emailId, accountId, onBack)
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

return EmailView
