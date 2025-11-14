-- Email Management Module
local Emails = {}
local Encryption = require("encryption")

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
    local Accounts = require("accounts")
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

return Emails

