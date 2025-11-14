# CogMail - Email Server System

A complete email system for ComputerCraft with GUI interface using Basalt2. Features secure password hashing, encrypted email storage, and a beautiful user interface.

## Features

- **Secure Password Hashing**: Passwords are hashed using salted hashing (not stored in plaintext)
- **Encrypted Email Storage**: All email data is encrypted on disk
- **Account Management**: Create accounts with username and password validation
- **Email System**: Send, receive, view, and delete emails
- **GUI Interface**: Beautiful Basalt2-based interface with responsive layout
- **Persistent Data**: All data persists between server restarts
- **Configurable Security**: Encryption keys and salts configurable via settings
- **Easy Installation**: Automated installer with GUI

## Structure

```
emailServer/
├── server/              # Server-side code
│   ├── main.lua        # Server entry point
│   ├── encryption.lua  # Encryption/decryption module (for emails)
│   ├── accounts.lua    # Account management with password hashing
│   ├── emails.lua      # Email storage and management
│   └── protocol.lua    # Message protocol handlers
├── client/             # Client-side code
│   ├── main.lua        # Client entry point
│   ├── network.lua     # Network communication module
│   ├── utils.lua       # Utility functions
│   └── screens/        # GUI screens
│       ├── login.lua
│       ├── account_creation.lua
│       ├── inbox.lua
│       ├── compose.lua
│       └── email_view.lua
├── build/              # Bundled files
│   ├── mailingServer.lua  # Complete server in one file
│   └── mailingClient.lua  # Complete client in one file
├── installServer.lua   # Server installer
└── README.md
```

## Quick Start

### Server Installation

**Option 1: Using the Installer (Recommended)**

```bash
wget run https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/installServer.lua
```

The installer will:
- Download the server from the repository
- Prompt you to configure encryption key and password salt
- Set up settings automatically
- Optionally create a startup file

**Option 2: Manual Installation**

1. Copy `build/mailingServer.lua` to your server computer
2. Configure settings:
   ```lua
   settings.define("email.encryption_key", {
       description = "Encryption key for email server data",
       default = "email_server_key_2024",
       type = "string"
   })
   
   settings.define("email.password_salt", {
       description = "Salt key for password hashing",
       default = "email_server_salt_2024",
       type = "string"
   })
   
   settings.set("email.encryption_key", "your_custom_key")
   settings.set("email.password_salt", "your_custom_salt")
   settings.save()
   ```
3. Run the server:
   ```lua
   local server = require("mailingServer")
   server.runServer()
   ```

**Option 3: Quick Install (No GUI)**

```bash
wget run https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/installServer.lua -q
```

### Client Installation

1. Install Basalt2 library (required for GUI)
2. Copy `build/mailingClient.lua` to your client computer
3. Run the client:
   ```lua
   local client = require("mailingClient")
   client.runClient()
   ```

## Configuration

### Settings

The server uses ComputerCraft's settings module for configuration. You can change settings using:

```lua
settings.set("email.encryption_key", "your_custom_encryption_key")
settings.set("email.password_salt", "your_custom_password_salt")
settings.save()
```

Or using the `set` program:
```
set email.encryption_key your_custom_key
set email.password_salt your_custom_salt
```

### Security Settings

- **Encryption Key** (`email.encryption_key`): Used to encrypt email data files
- **Password Salt** (`email.password_salt`): Used as salt for password hashing

**Important**: Change these from defaults before using in production!

## Usage

### Server

1. Start the server (see installation above)
2. The server listens on channel 100 for client requests
3. All accounts are stored in `accounts.dat` (plain serialized, passwords are hashed)
4. All emails are stored in `emails.dat` (encrypted)

### Client

1. Start the client (see installation above)
2. Create an account or login with existing credentials
3. View your inbox with pagination
4. Compose and send emails to other users
5. View email details and delete emails

## Security

### Password Security

- Passwords are **hashed** (not encrypted) using a salted hash algorithm
- Each password is hashed with the username as salt
- Original passwords cannot be recovered from hashes
- Account files are stored as plain serialized data (passwords are already hashed)

### Email Security

- Email data files are **encrypted** using the encryption key
- The encryption key is configurable via settings
- Email files cannot be read without the correct encryption key

### Best Practices

1. **Change default keys**: Always change `email.encryption_key` and `email.password_salt` from defaults
2. **Use strong keys**: Use long, random strings for encryption keys
3. **Keep keys secure**: Don't share your encryption keys
4. **Regular backups**: Backup your `accounts.dat` and `emails.dat` files

## Startup Configuration

To run the server automatically on computer startup, create a `startup.lua` file:

```lua
local server = require("mailingServer")
server.runServer()
```

The installer can create this file automatically if you select the startup option.

## Development

### Building Bundled Files

The bundled files in `build/` contain all dependencies in a single file:
- `mailingServer.lua`: Complete server with all modules
- `mailingClient.lua`: Complete client with all modules

These files expose `runServer()` and `runClient()` functions respectively.

### Module Structure

- **Server Modules**: Encryption, Accounts, Emails, Protocol
- **Client Modules**: Network, Utils, and Screen modules (Login, AccountCreation, Inbox, Compose, EmailView)

## Troubleshooting

### Server Issues

- **"No modem attached"**: Make sure a modem is attached to the server computer
- **Settings not saving**: Check file permissions and disk space
- **Can't decrypt emails**: Verify the encryption key matches the one used when emails were created

### Client Issues

- **"Basalt library not found"**: Install Basalt2 library
- **Connection timeout**: Check that the server is running and modems are connected
- **Can't login**: Verify username and password are correct

## License

[Add your license here]

## Contributing

[Add contribution guidelines here]
