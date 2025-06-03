# 🍳 Eggplant Shell Server 🍆

A tiny, adorable HTTP echo server written entirely in POSIX shell! 🐚✨

This little server listens on a port and echoes back information about the requests it receives. It's a fun exploration of what you can do with basic shell scripting and tools like `nc` and FIFOs.

Perfect for:
*   Learning about basic HTTP mechanics.
*   Understanding shell scripting with pipes and processes.
*   Having a lightweight server for quick local testing.
*   Admiring the resilience of POSIX tools!

---

## ✨ Features

*   **POSIX Shell Pure:** Crafted with standard shell commands.
*   **HTTP Echo:** Responds to GET and POST requests, showing you what it received.
*   **FIFO Powered:** Uses named pipes for communication between `nc` and the handler script (for `nc` versions without `-e` or `-c`).
*   **Customizable Port:** Run it on any port you like!
*   **Cute Output:** Well, we try! 😉

---

## 🚀 Quick Start

1.  **Clone the repository (or download the files):**
    ```bash
    git clone https://github.com/ruvasqm/posix-server.git
    cd posix-server
    ```

2.  **Make the scripts executable:**
    ```bash
    chmod +x server_fifo.sh http_handler_fifo.sh
    ```

3.  **Run the server:**
    ```bash
    ./server_fifo.sh
    ```
    By default, it listens on port `8080`. To use a different port:
    ```bash
    ./server_fifo.sh 8888
    ```

4.  **Send it a request!**
    Open another terminal and try:
    ```bash
    # Send a GET request
    curl http://localhost:8080/hello

    # Send a POST request with data
    curl -X POST -d "some_data=lovely_eggplant&message=hi_server" http://localhost:8080/submit
    ```

---

## 🎬 See it in Action!

Our little eggplant server hard at work:

<p align="center">
  <img src="./eggplant.svg" alt="Animated demo of the Eggplant Shell Server" width="600"/>
</p>

*(This animation shows the server starting, receiving a `curl` request, and the server's log output.)*

---

## 🛠️ How it Works (The Guts!)

This server uses a common pattern for older `nc` (netcat) versions that don't support executing a command per connection directly (`-e` or `-c` flags).

1.  **`server_fifo.sh` (The Conductor):**
    *   Sets up a **FIFO** (named pipe), e.g., `/tmp/my_http_fifo_$$`.
    *   Starts `nc` in listen mode.
        *   `nc`'s **output** (data received from the client) is redirected **into** the FIFO.
        *   `nc`'s **input** (data to send back to the client) comes **from** a pipeline that includes our handler.
    *   A pipeline is constructed:
        ```
        ./http_handler_fifo.sh < /tmp/my_http_fifo_$$ | nc -lp $PORT > /tmp/my_http_fifo_$$
        ```
        (Simplified, actual command may vary slightly based on `nc` version)

2.  **`http_handler_fifo.sh` (The Brains):**
    *   Reads the raw HTTP request from its standard input (which is connected to the FIFO, fed by `nc`).
    *   Parses the HTTP headers (looking for `Content-Length` for POST requests).
    *   Reads the request body if `Content-Length` indicates one.
    *   Constructs a simple HTTP response (status line, headers, and a body echoing what it received).
    *   Prints this HTTP response to its standard output.

3.  **The Loop:**
    *   The output of `http_handler_fifo.sh` is piped into `nc`'s standard input, which `nc` sends back to the client.
    *   The `server_fifo.sh` script usually wraps this whole `nc` setup in a `while true` loop, so after one connection is handled (and `nc` exits), it restarts `nc` to listen for the next connection.

It's a clever dance of processes and pipes! 💃🕺

---

## 🔧 Requirements

*   A POSIX-compliant shell (e.g., `bash`, `dash`, `ksh`).
*   `nc` (netcat) - The traditional version that doesn't require `-e` or `-c` is what this setup is designed for.
*   Standard POSIX utilities: `tr`, `awk`, `head`, `wc`, `printf`, `mkfifo`, `rm`.

Most Linux and macOS systems will have these readily available.

---

## 🤔 Known Quirks & Future Ideas

*   **Error Handling:** It's a toy server, so error handling is minimal.
*   **Concurrency:** Handles one connection at a time. For more, you'd need `ncat -k -e ...` or `socat`, or a more complex forking model.
*   **HTTP Compliance:** It's very basic! Doesn't handle chunked encoding, keep-alive (explicitly uses `Connection: close`), or many other HTTP features.
*   **Security:** **Absolutely NOT for production!** This is an educational tool.
*   **Idea:** Add a simple "router" to serve different static responses based on the path?
*   **Idea:** Make the eggplant in the SVG dance more when it gets a request! 💜

---

## ❤️ Contributing

Spotted a bug or have a cute idea? Feel free to open an issue or submit a pull request! Let's keep it fun and POSIX-y.

---

Made with Shell and a bit of 🍆 magic.
