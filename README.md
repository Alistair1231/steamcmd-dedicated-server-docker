# SteamCMD Dedicated Server Docker

A flexible Docker image for running Steam-based dedicated game servers using SteamCMD.

## Features

- Run any Steam dedicated server by specifying the App ID
- Automatic updates on container start
- Wine support for Windows-only servers
- Beta branch support
- Proper signal handling for graceful shutdowns
- Runs game server as non-root

## Usage

```yaml
services:
  gameserver:
    build:
      context: https://github.com/Alistair1231/steamcmd-dedicated-server-docker
      dockerfile: Dockerfile
    volumes:
      - ./steamcache:/root/.local/share/Steam
      - ./server-data:/data
    ports:
      - "27015:27015/udp"
    command: |
      --app-id 123456
      --binary /data/server_binary
      -- 
      -port 27015
```

## Arguments

**Required:**
- `--app-id APP_ID` - Steam application ID
- `--binary PATH` - Path to server binary

**Optional:**
- `--wine` - Use Wine (requires `Dockerfile.wine`)
- `--install-dir DIR` - Installation directory (default: `/data`)
- `--beta BRANCH` - Use specific beta branch
- `--` - Pass remaining arguments to server binary

## Example Configurations

See `compose.yml` for complete examples including:
- **Necesse** (App ID: 1169370) - Java-based server
- **Satisfactory** (App ID: 1690800) - Linux native server
- **Killing Floor 2** (App ID: 232130) - Windows server with Wine

## Volumes

```yaml
volumes:
  - ./steamcache:/root/.local/share/Steam  # SteamCMD cache
  - ./server-data:/data                     # Server files
  - ./server-config:/home/ubuntu/.config    # Game configs
```

## Troubleshooting

**Server won't start:** Verify App ID and binary path  
**Permission errors:** Ensure volumes are writable by UID 1000  
**Wine issues:** Use `Dockerfile.wine` with `--wine` flag
