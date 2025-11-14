-- Compose Email Screen
local Compose = {}
local Network = require("network")
local Utils = require("utils")
local basalt = require("basalt")

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

return Compose

