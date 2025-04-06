FROM steamcmd/steamcmd:latest

# KF2 Server needs curl
RUN apt-get update && \
  apt-get install -y --no-install-recommends curl && \
  rm -rf /var/lib/apt/lists/*

# create entrypoint script
RUN touch /entrypoint.sh && \
  chmod +x /entrypoint.sh && \
  cat <<'EOF' > /entrypoint.sh
#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

APP_ID="$1"
shift # Remove the App ID from the list *now*
SERVER_BINARY_PATH="$1" # Assume the server binary path is the next argument
SERVER_COMMAND=("$@") # Store the full server command (binary + args)

INSTALL_DIR="/data" # Or derive from SERVER_BINARY_PATH if needed, but /data is likely correct based on force_install_dir

# Determine if validation is needed
NEEDS_VALIDATE=""
if [ ! -f "${SERVER_BINARY_PATH}" ]; then
  echo "Server binary not found at ${SERVER_BINARY_PATH}. Assuming first run or corrupted install. Validation required."
  NEEDS_VALIDATE="validate"
else
  echo "Server binary found. Skipping validation for faster startup."
fi

# Update the server (conditionally validating)
echo "Updating App ID: ${APP_ID} ${NEEDS_VALIDATE}"
steamcmd +force_install_dir "${INSTALL_DIR}" \
  +login anonymous \
  +app_update "${APP_ID}" ${NEEDS_VALIDATE} \
  +exit
echo "Update process complete."

# Execute the server command
echo "Executing server: ${SERVER_COMMAND[@]}"
exec "${SERVER_COMMAND[@]}"
EOF



ENTRYPOINT ["/entrypoint.sh"]