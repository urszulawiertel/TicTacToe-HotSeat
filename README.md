# TicTacToe Hot-Seat (SwiftUI)

A simple Tic-Tac-Toe (3x3) iOS app built with SwiftUI.

## Features
- 3x3 board with X / O turns
- Win & draw detection
- Highlight winning line
- First-to-N match mode (e.g. first to 3)
- Game over + match over alerts (Play Again / New Match)
- Score tracking (X / O)
- Move timer (hot-seat) with time selection (5s / 10s / 15s) + pause/resume
- VS AI mode (random opponent)
- Game engine separated from UI (`TicTacToeEngine`)
- Unit tests for core game logic (`XCTest`)

## Tech stack
- Swift
- SwiftUI
- ObservableObject (`@StateObject`, `@Published`)
- XCTest

## How to run
1. Open the project in Xcode
2. Select an iOS Simulator
3. Run (`Cmd + R`)

## Tests
Run unit tests:
- `Cmd + U`

