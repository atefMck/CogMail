# Email Server System

A complete encrypted email system for ComputerCraft with GUI interface using Basalt2.

## Structure

```
emailServer/
├── server/           # Server-side code
│   ├── main.lua     # Server entry point
│   ├── encryption.lua # Encryption/decryption module
│   ├── accounts.lua  # Account management
│   ├── emails.lua    # Email storage and management
│   └── protocol.lua  # Message protocol handlers
├── client/           # Client-side code
│   ├── main.lua      # Client entry point
│   ├── network.lua   # Network communication module
│   └── screens/      # GUI screens
│       ├── login.lua
│       ├── account_creation.lua
│       ├── inbox.lua
│       └── compose.lua
└── README.md
```

## Setup

### Server Setup

1. Place the `server` folder on a computer with a modem
2. Run `server/main.lua`
3. The server will listen on channel 100

### Client Setup

1. Install Basalt2 library (place `basalt.lua` in the root or adjust the require path)
2. Place the `client` folder on a computer with a modem
3. Run `client/main.lua`

## Features

- **Encrypted Storage**: All account and email data is encrypted on disk
- **Account Management**: Create accounts with username and password
- **Email System**: Send, receive, and manage emails
- **GUI Interface**: Beautiful Basalt2-based interface
- **Persistent Data**: All data persists between server restarts

## Usage

### Server
- Start the server: `server/main.lua`
- The server automatically loads existing accounts and emails
- All data is encrypted and saved to `server/accounts.dat` and `server/emails.dat`

### Client
- Start the client: `client/main.lua`
- Create an account or login
- View inbox, compose emails, and manage your messages

## Security Note

Change the `ENCRYPTION_KEY` in `server/encryption.lua` to a secure, unique value before using in production.

