#!/bin/sh

PORT=${1:-8080}
# FIFO path - using $$ for a somewhat unique name if multiple run, good practice
FIFO_PATH="/tmp/my_http_fifo_$$"
HANDLER_SCRIPT="./handler.sh" # Assuming it's in the current directory

# Ensure FIFO is cleaned up on script exit (Ctrl+C, normal exit, etc.)
trap 'echo "Exiting, removing FIFO $FIFO_PATH"; rm -f "$FIFO_PATH"; exit' INT TERM EXIT

# Create the FIFO
if [ -e "$FIFO_PATH" ]; then
  echo "Warning: FIFO $FIFO_PATH already exists. Removing." >&2
  rm -f "$FIFO_PATH"
fi

if mkfifo "$FIFO_PATH"; then
  echo "Created FIFO: $FIFO_PATH" >&2
else
  echo "Error: Could not create FIFO $FIFO_PATH. Exiting." >&2
  exit 1
fi

# Make sure handler script is executable
if [ ! -x "$HANDLER_SCRIPT" ]; then
  echo "Error: Handler script $HANDLER_SCRIPT is not executable or not found." >&2
  echo "Please run: chmod +x $HANDLER_SCRIPT" >&2
  # rm -f "$FIFO_PATH" # Clean up FIFO before exiting due to this error
  exit 1
fi

echo "FIFO-based HTTP Echo Server listening on port $PORT..."
echo "Using FIFO: $FIFO_PATH"
echo "Handler script: $HANDLER_SCRIPT"
echo "Access with: curl http://localhost:$PORT/some/path -d 'Hello from curl'"

# Determine your nc executable
NC_EXEC=$(command -v nc)
if [ -z "$NC_EXEC" ]; then
  echo "Error: nc command not found. Exiting." >&2
  exit 1
fi

while true; do
  echo "--- SERVER_FIFO_LOOP: Waiting for connection on port $PORT... ---" >&2
  echo "--- SERVER_FIFO_LOOP: Executing: cat \"$FIFO_PATH\" | \"$HANDLER_SCRIPT\" | \"$NC_EXEC\" -lp \"$PORT\" > \"$FIFO_PATH\" ---" >&2
  # TODO: someone please help me shush this line. This is POSIX
  cat "$FIFO_PATH" | "$HANDLER_SCRIPT" | "$NC_EXEC" -lp "$PORT" >"$FIFO_PATH"
  echo "--- SERVER_FIFO_LOOP: nc process finished or connection closed. Restarting loop. ---" >&2
  # Small delay to prevent a very tight loop if nc fails immediately (e.g., port in use)
  sleep 0.1
done
