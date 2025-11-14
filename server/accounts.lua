-- Account Management Module
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

return Accounts

