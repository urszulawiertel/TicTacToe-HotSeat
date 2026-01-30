# TicTacToe Hot-Seat (SwiftUI)

Tic-Tac-Toe iOS app built with SwiftUI, featuring match mode, AI opponent, move timer, undo system and deterministic async testing.

## Features

### Core Gameplay
- 3×3 board
- Win & draw detection
- Winning line highlight
- First-to-N match mode (configurable target score)
- Score tracking (X / O)
- Game over & match over flows

### ⏱ Move Timer
- Configurable move time (5s / 10s / 15s)
- Pause / resume
- Timeout auto-switches player
- Timer resets on valid move
- Fully covered by unit tests

### 🤖 AI Mode
- VS AI mode
- Random AI
- Smart AI (blocks opponent win / plays winning move)
- Delayed AI move (configurable)
- Proper cancellation of pending AI tasks

### ↩ Undo (AI-aware)
- Undo last move
- In VS AI mode: reverts both player and AI move
- Cancels scheduled AI work
- Resets timer state correctly

### ✨ UX Enhancements
- Ghost move preview (press & hold)
- Disabled board when not playable
- Clean match state transitions
- Single source of truth configuration (GameConfig)

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
Unit tests cover:
- Move validation
- Win detection
- Match completion
- Timer behavior
- AI logic (random + smart)
- Delayed AI scheduling
- Cancellation of pending AI
- Undo (human + AI mode)
Run unit tests:
- `Cmd + U`

