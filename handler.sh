#!/bin/sh
# http_handler_fifo.sh

echo "--- HANDLER: Script started. ---" >&2

REQUEST_HEADERS=""

# Read headers line by line from stdin
while IFS= read -r line; do
  cleaned_line=$(printf "%s" "$line" | tr -d '\r')

  # Store the cleaned line (no \r) followed by a single actual newline
  REQUEST_HEADERS="${REQUEST_HEADERS}${cleaned_line}\n"

  if [ -z "$cleaned_line" ]; then
    echo "--- HANDLER: End of headers detected. ---" >&2
    break
  fi
done

# Extract Content-Length. Why are we using echo? POSIX, that is why
content_length_val=$(echo "$REQUEST_HEADERS" | awk -v IGNORECASE=1 'match($0, /^Content-Length:[[:space:]]*([0-9]+)/, m) {print m[1]; exit}')

REQUEST_BODY=""
if [ -n "$content_length_val" ]; then
  if [ "$content_length_val" -gt 0 ]; then
    echo "--- HANDLER: Reading $content_length_val byte body. ---" >&2
    REQUEST_BODY=$(head -c "$content_length_val")
  else
    echo "--- HANDLER: Content-Length is $content_length_val, no body to read. ---" >&2
  fi
else
  echo "--- HANDLER: No Content-Length header found or value not extracted. ---" >&2
fi

# Prepare Response Body
if [ -n "$REQUEST_BODY" ]; then
  RESPONSE_BODY="Right back at you: ${REQUEST_BODY}"
else
  RESPONSE_BODY="Received your GET request (no body).\r\n" # Added \r\n for consistency
fi

CONTENT_LENGTH=$(printf "%s" "$RESPONSE_BODY" | wc -c)

# Send HTTP Response
printf "HTTP/1.1 200 OK\r\n"
printf "Content-Type: text/plain; charset=utf-8\r\n"
printf "Content-Length: %s\r\n" "$CONTENT_LENGTH"
printf "Connection: close\r\n"
printf "\r\n"                # Empty line separates headers from body
printf '%s' "$RESPONSE_BODY" # Use %s to prevent issues if RESPONSE_BODY starts with '-'

echo "--- HANDLER: Response sent. Script finishing. ---" >&2
