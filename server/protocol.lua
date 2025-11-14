-- Protocol Handler Module
local Protocol = {}
local Accounts = require("accounts")
local Emails = require("emails")

function Protocol.handleCreateAccount(replyChannel, modem, data)
    local username = data.username
    local password = data.password
    
    local success, result = Accounts.create(username, password)
    
    local response = {
        type = "create_account_response",
        success = success,
        message = success and "Account created successfully" or result,
        account = success and {id = result.id, username = result.username} or nil
    }
    
    modem.transmit(replyChannel, 100, response)
end

function Protocol.handleLogin(replyChannel, modem, data)
    local username = data.username
    local password = data.password
    
    local success, result = Accounts.verify(username, password)
    
    local response = {
        type = "login_response",
        success = success,
        message = success and "Login successful" or result,
        account = success and {id = result.id, username = result.username} or nil
    }
    
    modem.transmit(replyChannel, 100, response)
end

function Protocol.handleGetAccountInfo(replyChannel, modem, data)
    local accountId = data.accountId
    
    local account = Accounts.findById(accountId)
    
    local response = {
        type = "account_info_response",
        success = account ~= nil,
        account = account and {id = account.id, username = account.username} or nil,
        message = account and "Account found" or "Account not found"
    }
    
    modem.transmit(replyChannel, 100, response)
end

function Protocol.handleGetAllUsernames(replyChannel, modem, data)
    local usernames = Accounts.getAllUsernames()
    
    local response = {
        type = "all_usernames_response",
        success = true,
        usernames = usernames
    }
    
    modem.transmit(replyChannel, 100, response)
end

function Protocol.handleSendEmail(replyChannel, modem, data)
    local fromId = data.fromId
    local toUsername = data.toUsername
    local subject = data.subject
    local body = data.body
    
    local success, result = Emails.create(fromId, toUsername, subject, body)
    
    local response = {
        type = "send_email_response",
        success = success,
        message = success and "Email sent successfully" or result,
        email = success and {id = result.id} or nil
    }
    
    modem.transmit(replyChannel, 100, response)
end

function Protocol.handleGetInbox(replyChannel, modem, data)
    local accountId = data.accountId
    
    local inbox = Emails.getInbox(accountId)
    
    -- Remove sensitive data before sending
    local safeInbox = {}
    for _, email in ipairs(inbox) do
        table.insert(safeInbox, {
            id = email.id,
            fromId = email.fromId,
            fromUsername = email.fromUsername or "Unknown",
            subject = email.subject,
            timestamp = email.timestamp,
            read = email.read
        })
    end
    
    local response = {
        type = "inbox_response",
        success = true,
        inbox = safeInbox
    }
    
    modem.transmit(replyChannel, 100, response)
end

function Protocol.handleGetEmail(replyChannel, modem, data)
    local emailId = data.emailId
    local accountId = data.accountId
    
    local email = Emails.getById(emailId, accountId)
    
    if email then
        -- Mark as read if viewing inbox email
        if email.toId == accountId then
            Emails.markAsRead(emailId, accountId)
        end
        
        local response = {
            type = "email_response",
            success = true,
            email = {
                id = email.id,
                fromId = email.fromId,
                fromUsername = email.fromUsername or "Unknown",
                toId = email.toId,
                toUsername = email.toUsername,
                subject = email.subject,
                body = email.body,
                timestamp = email.timestamp,
                read = email.read
            }
        }
        modem.transmit(replyChannel, 100, response)
    else
        local response = {
            type = "email_response",
            success = false,
            message = "Email not found"
        }
        modem.transmit(replyChannel, 100, response)
    end
end

function Protocol.handleDeleteEmail(replyChannel, modem, data)
    local emailId = data.emailId
    local accountId = data.accountId
    
    local success = Emails.delete(emailId, accountId)
    
    local response = {
        type = "delete_email_response",
        success = success,
        message = success and "Email deleted successfully" or "Failed to delete email"
    }
    
    modem.transmit(replyChannel, 100, response)
end

function Protocol.processMessage(channel, replyChannel, message, distance, modem)
    if type(message) ~= "table" then
        return
    end
    
    local msgType = message.type
    
    if msgType == "create_account" then
        Protocol.handleCreateAccount(replyChannel, modem, message)
    elseif msgType == "login" then
        Protocol.handleLogin(replyChannel, modem, message)
    elseif msgType == "get_account_info" then
        Protocol.handleGetAccountInfo(replyChannel, modem, message)
    elseif msgType == "get_all_usernames" then
        Protocol.handleGetAllUsernames(replyChannel, modem, message)
    elseif msgType == "send_email" then
        Protocol.handleSendEmail(replyChannel, modem, message)
    elseif msgType == "get_inbox" then
        Protocol.handleGetInbox(replyChannel, modem, message)
    elseif msgType == "get_email" then
        Protocol.handleGetEmail(replyChannel, modem, message)
    elseif msgType == "delete_email" then
        Protocol.handleDeleteEmail(replyChannel, modem, message)
    else
        local response = {
            type = "error",
            message = "Unknown message type: " .. tostring(msgType)
        }
        modem.transmit(replyChannel, 100, response)
    end
end

return Protocol

