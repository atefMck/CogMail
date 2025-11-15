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

The installer will:
- Download the server from the repository
- Prompt you to configure encryption key and password salt
- Set up settings automatically
- Optionally create a startup file

**Quick Install (No GUI):**

```bash
wget run https://raw.githubusercontent.com/atefMck/CogMail/refs/heads/main/installServer.lua -q
```

### Client Installation

Run the installer:

```bash
wget run https://raw.githubusercontent.com/atefMck/CogMail/refs/heads/main/installClient.lua
```

The installer will:
- Download the client from the repository
- Download Basalt2 automatically if needed
- Optionally set up automatic startup

**Quick Install (No GUI):**

```bash
wget run https://raw.githubusercontent.com/atefMck/CogMail/refs/heads/main/installClient.lua -q
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

To run the server or client automatically on computer startup, the installer can create a `startup.lua` file automatically if you select the startup option during installation.

## Troubleshooting

### Server Issues

- **"No modem attached"**: Make sure a modem is attached to the server computer
- **Settings not saving**: Check file permissions and disk space
- **Can't decrypt emails**: Verify the encryption key matches the one used when emails were created

### Client Issues

- **"Basalt library not found"**: The installer will download Basalt2 automatically, or install it manually if needed
- **Connection timeout**: Check that the server is running and modems are connected
- **Can't login**: Verify username and password are correct
- **Version mismatch**: The client will prompt you to update if versions don't match

## License

MIT License

Copyright (c) 2024 CogMail Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
