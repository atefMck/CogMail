-- Email Server Main File
local Accounts = require("accounts")
local Emails = require("emails")
local Protocol = require("protocol")

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

