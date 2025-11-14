-- Encryption/Decryption Module
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

return Encryption

