# Battleship

Real-time online multiplayer battleship TUI game for the AP Computer Science Principles 2021 Performance Task written in Dart. Most of the code is uncommented but somewhat self-documenting.

## Table of Contents
- [Battleship](#battleship)
  - [Table of Contents](#table-of-contents)
  - [Architecture](#architecture)
  - [Requirements](#requirements)
  - [Building and running](#building-and-running)
    - [Directly](#directly)
    - [Concatenation](#concatenation)
      - [Watch mode](#watch-mode)
      - [Google Docs mode](#google-docs-mode)
    - [Compilation](#compilation)
  - [Usage](#usage)

## Architecture

This project contains both the game client and the centralized game server. The server is responsible for keeping track of the game state and coordinating the clients for each game.

Clients communicate with the server using HTTPS (for general API stuff) and WebSockets (for gameplay).

Game data (boards, ships, cells, etc.) are serialized to strings when sent over the network.

## Requirements

- Dart >=2.17.0

## Building and running

### Directly

Run the `battleship.dart` file in the `bin` directory.

```sh
dart run bin/battleship.dart
```

### Concatenation

Concatenate `bin/battleship.dart` and all of its dependencies into a single file.

```sh
make concat
```

The result will be at `build/main.dart`.

#### Watch mode

Re-concatenate the files every time a file changes.

```sh
make watch
```

#### Google Docs mode

Concatenating in Google Docs mode will place an extra space at the beginning of each line for easy copy-paste.

```sh
make gdocs
```

### Compilation

Compile the game into an executable.

```sh
make dist
```

The executable will be at `build/battleship`.

## Usage

**`battleship`**

- Prints a help message.

**`battleship [--ascii] client [server_address]`**

- Run the battleship game client, connecting to the server at the given origin (`hostname:port`; yes, port is required), or `localhost:8080` if no origin is given.
- If `--ascii` is specified, the game will use ASCII art instead of Unicode characters, which might not be supported by all terminals or fonts.

**`battleship server [address]`**

- Start a battleship game server, listening on the given hostname and port, or `localhost:8080` if no address is given.
