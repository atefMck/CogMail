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
- **Version Control**: Automatic version checking and update prompts

## Quick Start

### Server Installation

Run the installer:

```bash
wget run https://raw.githubusercontent.com/atefMck/CogMail/refs/heads/main/installServer.lua
```

### Client Installation

Run the installer:

```bash
wget run https://raw.githubusercontent.com/atefMck/CogMail/refs/heads/main/installClient.lua
```
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

## Usage

### Server

1. Start the server using the installer or run:
   ```lua
   local server = require("mailingServer")
   server.runServer()
   ```
2. The server listens on channel 100 for client requests
3. All accounts are stored in `accounts.dat` (passwords are hashed)
4. All emails are stored in `emails.dat` (encrypted)

### Client

1. Start the client using the installer or run:
   ```lua
   local client = require("mailingClient")
   client.runClient()
   ```
2. The client will automatically check for version compatibility with the server
3. Create an account or login with existing credentials
4. View your inbox with pagination
5. Compose and send emails to other users
6. View email details and delete emails

### Best Practices

1. **Change default keys**: Always change `email.encryption_key` and `email.password_salt` from defaults
2. **Use strong keys**: Use long, random strings for encryption keys
3. **Keep keys secure**: Don't share your encryption keys
4. **Regular backups**: Backup your `accounts.dat` and `emails.dat` files

## Startup Configuration

To run the server or client automatically on computer startup, the installer can create a `startup.lua` file automatically if you select the startup option during installation.

