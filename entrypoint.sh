#!/bin/bash
set -e
set -x

# Default values
USE_WINE=0
APP_ID=""
SERVER_BINARY_PATH=""
SERVER_ARGS=()
INSTALL_DIR="/data"
BETA_BRANCH=""

# Help function
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] --app-id APP_ID --binary PATH [-- SERVER_ARGS...]

Required arguments:
    --app-id APP_ID          Steam application ID to install/update
    --binary PATH            Path to the server binary executable

Optional arguments:
    --wine                   Run the server using Wine
    --install-dir DIR        Installation directory (default: /data)
    --beta BRANCH            Install and run a specific beta branch
    -h, --help              Show this help message

Server arguments:
    --                      Everything after -- is passed to the server binary

Examples:
    $(basename "$0") --app-id 123456 --binary /data/server.exe
    $(basename "$0") --wine --app-id 123456 --binary /data/server.exe -- -port 27015
    $(basename "$0") --app-id 376030 --binary /data/server.exe --beta experimental -- -port 27015

Note: When using --beta, the branch name is automatically passed to the server as -branchname
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --wine)
            USE_WINE=1
            shift
            ;;
        --app-id)
            if [[ -z "$2" ]] || [[ "$2" == -* ]]; then
                echo "Error: --app-id requires a value" >&2
                exit 1
            fi
            APP_ID="$2"
            shift 2
            ;;
        --binary)
            if [[ -z "$2" ]] || [[ "$2" == -* ]]; then
                echo "Error: --binary requires a value" >&2
                exit 1
            fi
            SERVER_BINARY_PATH="$2"
            shift 2
            ;;
        --install-dir)
            if [[ -z "$2" ]] || [[ "$2" == -* ]]; then
                echo "Error: --install-dir requires a value" >&2
                exit 1
            fi
            INSTALL_DIR="$2"
            shift 2
            ;;
        --beta)
            if [[ -z "$2" ]] || [[ "$2" == -* ]]; then
                echo "Error: --beta requires a branch name" >&2
                exit 1
            fi
            BETA_BRANCH="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        --)
            shift
            SERVER_ARGS=("$@")
            break
            ;;
        -*)
            echo "Error: Unknown option: $1" >&2
            echo "Use --help for usage information" >&2
            exit 1
            ;;
        *)
            echo "Error: Unexpected argument: $1" >&2
            echo "Use --help for usage information" >&2
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$APP_ID" ]]; then
    echo "Error: --app-id is required" >&2
    echo "Use --help for usage information" >&2
    exit 1
fi

if [[ -z "$SERVER_BINARY_PATH" ]]; then
    echo "Error: --binary is required" >&2
    echo "Use --help for usage information" >&2
    exit 1
fi

# Validate APP_ID is numeric
if ! [[ "$APP_ID" =~ ^[0-9]+$ ]]; then
    echo "Error: APP_ID must be numeric" >&2
    exit 1
fi

# Update/validate logic
NEEDS_VALIDATE=""
if [ ! -f "${SERVER_BINARY_PATH}" ]; then
    echo "Server binary not found at ${SERVER_BINARY_PATH}. Assuming first run or corrupted install. Validation required."
    NEEDS_VALIDATE="validate"
else
    echo "Server binary found. Skipping validation for faster startup."
fi

# Build steamcmd command with optional beta branch
BETA_FLAG=""
if [[ -n "$BETA_BRANCH" ]]; then
    BETA_FLAG="-beta ${BETA_BRANCH}"
    echo "Using beta branch: ${BETA_BRANCH}"
fi

echo "Updating App ID: ${APP_ID} ${NEEDS_VALIDATE} ${BETA_FLAG}"
sudo steamcmd +force_install_dir "${INSTALL_DIR}" \
    +login anonymous \
    +app_update "${APP_ID}" ${BETA_FLAG} ${NEEDS_VALIDATE} \
    +exit
echo "Update process complete."

echo "Ensure the ${INSTALL_DIR} directory is owned by the ubuntu user"
sudo chown -R ubuntu:ubuntu "${INSTALL_DIR}"

# Launch the server - use exec to replace this process with the server
# This ensures proper stdin/stdout/signal handling
if [[ "$USE_WINE" == "1" ]]; then
    echo "Starting Xvfb"
    Xvfb :0 -screen 0 1024x768x16 &
    export DISPLAY=:0
    echo "Starting server with Wine: $SERVER_BINARY_PATH ${SERVER_ARGS[*]}"
    exec gosu ubuntu wine "$SERVER_BINARY_PATH" "${SERVER_ARGS[@]}"
else
    echo "Executing: $SERVER_BINARY_PATH ${SERVER_ARGS[*]}"
    exec gosu ubuntu "$SERVER_BINARY_PATH" "${SERVER_ARGS[@]}"
fi