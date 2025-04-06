# SteamCMD Generic Dedicated Server Docker Image

This repository provides a Docker setup to run dedicated game servers that are installed and updated via SteamCMD. It includes a generic entrypoint script that handles the installation and update process before launching the server.

An example `compose.yml` file is provided to demonstrate how to run a Killing Floor 2 server.

## Features

*   Based on the official `steamcmd/steamcmd:latest` image.
*   Automatically installs or updates the specified Steam App ID on container start.
*   Uses a persistent Docker volume (`/data`) for game server files to not bloat the image size.
*   Conditionally validates the installation (only validates if the server binary is missing) for potentially faster startup times on subsequent runs.
*   Configurable via arguments passed to the entrypoint (using `command` in `compose.yml`).
*   Includes an example `compose.yml` for Killing Floor 2.

## Prerequisites

*   [Docker](https://docs.docker.com/get-docker/)
*   [Docker Compose](https://docs.docker.com/compose/install/)

## Files

*   `Dockerfile`: Defines the Docker image, installs `curl`, and sets up the `entrypoint.sh` script.
*   `entrypoint.sh`: The script executed when the container starts. It handles the `steamcmd` update/install process and then executes the game server binary with provided arguments.
*   `compose.yml`: An example Docker Compose file demonstrating how to use the image to run a Killing Floor 2 server.

## Usage

1.  Create a `compose.yml` file for your desired game server, copy the example provided, and modify it as needed. Right now, I only have a Killing Floor 2 example, but you can use this for any game server that uses SteamCMD. Check the examples folder for the compose file.
    
    Pay attention to:
    *   `build`: If you want to clone this repo and modify the Dockerfile, the `build` context should point to the directory containing the `Dockerfile`. If the default works for you, then just point it at this repo like the example. 
    *   `container_name`: Choose a suitable name.
    *   `ports`: Map the necessary ports for your specific game server (Game Port, Query Port, Web Admin Port, etc.). The example shows ports for KF2.
    *   `command`: This is crucial. It provides arguments to the `entrypoint.sh` script:
        *   Argument 1: The **Steam App ID** of the dedicated server (e.g., `"232130"` for KF2).
        *   Argument 2: The **full path** to the server executable *inside the container* (usually within `/data`, e.g., `"/data/Binaries/Win64/KFGameSteamServer.bin.x86_64"` for KF2).
            * Can be empty for first start. After the initial installation, just look what the path is.
        *   Argument 3 onwards: All subsequent arguments required to launch the server (e.g., map name, query/game/web ports, passwords, server name, etc.). Refer to your game server's documentation for required launch parameters.

3.  **Run the Server:**
    Navigate to the directory containing your `compose.yml` file and run:
    ```bash
    docker compose up -d
    ```
    The first time you run this, `steamcmd` will download and validate the server files, which might take some time. Subsequent runs will check for updates but skip validation if the server binary exists, potentially starting faster. Installation is always forced to the `/data` directory.

    After the initial install, you may want to modify configs, install mods or maps, etc. You can do this in the `data` directory on the host machine, which is mapped to the container's `/data` directory. If your server stores its configurations outside of its installation folder, you can (and should) add another `volumes` mapping in `compose.yml` to point to the correct location. e.g.
    ```yaml
    volumes:
      - ./config:/etc/server-config
    ```

    Adding the mapping will make `/etc/server-config` available in the local `config` folder. You can then modify the server config files in the `config` folder on your host machine, and they will be available in the container.

4.  **Stop the Server:**
    ```bash
    docker compose down
    ```

## How it Works

*   The `Dockerfile` sets up the base image and copies the `entrypoint.sh` script.
*   The `ENTRYPOINT` instruction ensures `entrypoint.sh` is executed when the container starts.
*   The `command` array in `compose.yml` provides arguments to `entrypoint.sh`.
*   `entrypoint.sh` performs the following steps:
    1.  Receives the App ID, Server Binary Path, and Server Arguments.
    2.  Checks if the Server Binary exists at the specified path.
    3.  Runs `steamcmd +force_install_dir /data +login anonymous +app_update <APP_ID> [validate] +quit`.
        *   It *always* runs `app_update` to ensure the server is up-to-date.
        *   The `validate` flag is added *only* if the server binary was not found (step 2), forcing a file integrity check.
    4.  Executes the Server Binary Path with the provided Server Arguments using `exec`, replacing the script process with the game server process.

## Customization

*   **Different Game:** Modify the `command` arguments (App ID, binary path, server args) and `ports` in `compose.yml`.
*   **Data Storage:** Change the host-side path in the `volumes` mapping in `compose.yml`.
*   **Update Behavior:** The current `entrypoint.sh` *always* checks for updates via `app_update`. If you need to completely skip the update check (e.g., for faster using outdated versions), you need to run the Server directly by using the entrypoint, instead of using the command. There is an example in the compose.yml for Killing Floor 2.
