-- Bundled Email Server
-- This file contains all server modules bundled together

-- ============================================================================
-- Encryption Module
-- ============================================================================
local Encryption = {}

-- Define and load encryption key from settings
settings.define("email.encryption_key", {
    description = "Encryption key for email server data",
    default = "email_server_key_2024",
    type = "string"
})
settings.load()

function Encryption.encrypt(data, key)
    key = key or settings.get("email.encryption_key")
    if type(data) ~= "string" then
        data = textutils.serialize(data)
    end
    local encrypted = {}
    local keyLen = #key
    for i = 1, #data do
        local byte = string.byte(data, i)
        local keyByte = string.byte(key, ((i - 1) % keyLen) + 1)
        encrypted[i] = string.char((byte + keyByte) % 256)
    end
    return table.concat(encrypted)
end

function Encryption.decrypt(encrypted, key)
    key = key or settings.get("email.encryption_key")
    local decrypted = {}
    local keyLen = #key
    for i = 1, #encrypted do
        local byte = string.byte(encrypted, i)
        local keyByte = string.byte(key, ((i - 1) % keyLen) + 1)
        decrypted[i] = string.char((byte - keyByte) % 256)
    end
    local data = table.concat(decrypted)
    return textutils.unserialize(data) or data
end

-- ============================================================================
-- Accounts Module
-- ============================================================================
local Accounts = {}
local ACCOUNTS_FILE = "accounts.dat"
local accounts = {}
local nextAccountId = 1

-- Define and load password salt from settings
settings.define("email.password_salt", {
    description = "Salt key for password hashing",
    default = "email_server_salt_2024",
    type = "string"
})
settings.load()

-- Password hashing function
-- Uses a simple but effective hash algorithm suitable for ComputerCraft
local function hashPassword(password, salt)
    salt = salt or settings.get("email.password_salt")
    local hash = password .. salt
    
    -- Multiple rounds of transformation for better security
    for round = 1, 5 do
        local newHash = ""
        for i = 1, #hash do
            local byte = string.byte(hash, i)
            -- Mix bytes with salt and round number
            local mixed = ((byte + string.byte(salt, ((i - 1) % #salt) + 1) + round) % 256)
            newHash = newHash .. string.char(mixed)
        end
        hash = newHash
    end
    
    -- Convert to hex-like string representation
    local hexHash = ""
    for i = 1, math.min(#hash, 32) do  -- Limit to 32 chars for storage
        local byte = string.byte(hash, i)
        hexHash = hexHash .. string.format("%02x", byte)
    end
    
    return hexHash
end

function Accounts.load()
    if fs.exists(ACCOUNTS_FILE) then
        local file = fs.open(ACCOUNTS_FILE, "r")
        if file then
            local fileData = file.readAll()
            file.close()
            if fileData and #fileData > 0 then
                local success, data = pcall(textutils.unserialize, fileData)
                if success and data then
                    accounts = data.accounts or {}
                    nextAccountId = data.nextId or 1
                    print("Loaded " .. #accounts .. " accounts from file")
                else
                    print("Error: Failed to load accounts file")
                    accounts = {}
                end
            end
        end
    else
        print("No accounts file found, starting fresh")
        accounts = {}
    end
end

function Accounts.save()
    local data = {
        accounts = accounts,
        nextId = nextAccountId
    }
    local serializedData = textutils.serialize(data)
    local file = fs.open(ACCOUNTS_FILE, "w")
    if file then
        file.write(serializedData)
        file.close()
        print("Accounts saved successfully")
        return true
    else
        print("Error: Failed to save accounts")
        return false
    end
end

function Accounts.findByUsername(username)
    for i, account in ipairs(accounts) do
        if account.username == username then
            return account, i
        end
    end
    return nil, nil
end

function Accounts.findById(id)
    for i, account in ipairs(accounts) do
        if account.id == id then
            return account, i
        end
    end
    return nil, nil
end

function Accounts.getAllUsernames()
    local usernames = {}
    for _, account in ipairs(accounts) do
        table.insert(usernames, account.username)
    end
    return usernames
end

function Accounts.create(username, password)
    -- Validate username
    if not username or username == "" then
        return false, "Username cannot be empty"
    end
    
    if #username < 3 then
        return false, "Username must be at least 3 characters"
    end
    
    if #username > 20 then
        return false, "Username must be at most 20 characters"
    end
    
    -- Check if username already exists
    if Accounts.findByUsername(username) then
        return false, "Username already exists"
    end
    
    -- Validate password
    if not password or password == "" then
        return false, "Password cannot be empty"
    end
    
    if #password < 4 then
        return false, "Password must be at least 4 characters"
    end
    
    -- Create new account with hashed password
    local account = {
        id = nextAccountId,
        username = username,
        password = hashPassword(password, username) -- Hash password with username as salt
    }
    
    table.insert(accounts, account)
    nextAccountId = nextAccountId + 1
    
    -- Save to file
    if Accounts.save() then
        print("Account created: " .. username .. " (ID: " .. account.id .. ")")
        return true, account
    else
        -- Rollback on save failure
        table.remove(accounts)
        nextAccountId = nextAccountId - 1
        return false, "Failed to save account"
    end
end

function Accounts.verify(username, password)
    local account = Accounts.findByUsername(username)
    if account then
        -- Hash the provided password and compare with stored hash
        local hashedPassword = hashPassword(password, username)
        if account.password == hashedPassword then
            return true, account
        end
    end
    return false, "Invalid username or password"
end

function Accounts.getAll()
    return accounts
end

-- ============================================================================
-- Emails Module
-- ============================================================================
local Emails = {}
local EMAILS_FILE = "emails.dat"
local emails = {}
local nextEmailId = 1

function Emails.load()
    if fs.exists(EMAILS_FILE) then
        local file = fs.open(EMAILS_FILE, "r")
        if file then
            local encryptedData = file.readAll()
            file.close()
            if encryptedData and #encryptedData > 0 then
                local success, data = pcall(Encryption.decrypt, encryptedData)
                if success and data then
                    emails = data.emails or {}
                    nextEmailId = data.nextId or 1
                    print("Loaded " .. #emails .. " emails from file")
                else
                    print("Error: Failed to decrypt emails file")
                    emails = {}
                end
            end
        end
    else
        print("No emails file found, starting fresh")
        emails = {}
    end
end

function Emails.save()
    local data = {
        emails = emails,
        nextId = nextEmailId
    }
    local encryptedData = Encryption.encrypt(data)
    local file = fs.open(EMAILS_FILE, "w")
    if file then
        file.write(encryptedData)
        file.close()
        print("Emails saved successfully")
        return true
    else
        print("Error: Failed to save emails")
        return false
    end
end

function Emails.create(fromId, toUsername, subject, body)
    local toAccount = Accounts.findByUsername(toUsername)
    local fromAccount = Accounts.findById(fromId)
    
    if not toAccount then
        return false, "Recipient username not found"
    end
    
    local email = {
        id = nextEmailId,
        fromId = fromId,
        fromUsername = fromAccount and fromAccount.username or "Unknown",
        toId = toAccount.id,
        toUsername = toUsername,
        subject = subject or "",
        body = body or "",
        timestamp = os.time(),
        read = false
    }
    
    table.insert(emails, email)
    nextEmailId = nextEmailId + 1
    
    if Emails.save() then
        print("Email sent from ID " .. fromId .. " to " .. toUsername)
        return true, email
    else
        -- Rollback on save failure
        table.remove(emails)
        nextEmailId = nextEmailId - 1
        return false, "Failed to save email"
    end
end

function Emails.getInbox(accountId)
    local inbox = {}
    for _, email in ipairs(emails) do
        if email.toId == accountId then
            table.insert(inbox, email)
        end
    end
    -- Sort by timestamp, newest first
    table.sort(inbox, function(a, b) return a.timestamp > b.timestamp end)
    return inbox
end

function Emails.getSent(accountId)
    local sent = {}
    for _, email in ipairs(emails) do
        if email.fromId == accountId then
            table.insert(sent, email)
        end
    end
    -- Sort by timestamp, newest first
    table.sort(sent, function(a, b) return a.timestamp > b.timestamp end)
    return sent
end

function Emails.getById(emailId, accountId)
    for _, email in ipairs(emails) do
        if email.id == emailId and (email.toId == accountId or email.fromId == accountId) then
            return email
        end
    end
    return nil
end

function Emails.markAsRead(emailId, accountId)
    local email = Emails.getById(emailId, accountId)
    if email and email.toId == accountId then
        email.read = true
        Emails.save()
        return true
    end
    return false
end

function Emails.delete(emailId, accountId)
    for i, email in ipairs(emails) do
        if email.id == emailId and (email.toId == accountId or email.fromId == accountId) then
            table.remove(emails, i)
            Emails.save()
            return true
        end
    end
    return false
end

-- ============================================================================
-- Protocol Module
-- ============================================================================
local Protocol = {}

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

-- ============================================================================
-- Main Server Function
-- ============================================================================
function runServer()
    local modem = peripheral.find("modem") or error("No modem attached", 0)
    local SERVER_CHANNEL = 100
    local CLIENT_CHANNEL = 200
    
    -- Initialize Server
    print("=== Email Server Starting ===")
    print("Computer ID: " .. os.getComputerID())
    print("Opening channels " .. SERVER_CHANNEL .. " (server) and " .. CLIENT_CHANNEL .. " (client)")
    
    modem.open(SERVER_CHANNEL)
    modem.open(CLIENT_CHANNEL)
    Accounts.load()
    Emails.load()
    
    print("Server ready. Listening on channel " .. SERVER_CHANNEL)
    print("Commands:")
    print("  - create_account: Create a new account")
    print("  - login: Login to an existing account")
    print("  - send_email: Send an email")
    print("  - get_inbox: Get inbox emails")
    print("  - get_email: Get a specific email")
    print("  - get_all_usernames: Get list of all usernames")
    print("  - delete_email: Delete an email")
    print("")
    
    -- Event Loop
    while true do
        local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
        
        if channel == SERVER_CHANNEL then
            print("Received message on channel " .. channel .. " from reply channel " .. replyChannel)
            Protocol.processMessage(channel, replyChannel, message, distance, modem)
        end
    end
end

return { runServer = runServer }

