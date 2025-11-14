-- Inbox Screen
local Inbox = {}
local Network = require("network")
local Utils = require("utils")
local EmailView = require("screens/email_view")
local basalt = require("basalt")

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

return Inbox

