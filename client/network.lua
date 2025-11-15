-- Network Communication Module
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

function Network.getServerVersion()
    local response, err = Network.sendRequest("get_version", {})
    
    if err then
        return false, tostring(err)
    end
    
    if not response then
        return false, "No response from server"
    end
    
    if response.success and response.version then
        return true, response.version
    else
        return false, response.message or "Failed to get server version"
    end
end

return Network

