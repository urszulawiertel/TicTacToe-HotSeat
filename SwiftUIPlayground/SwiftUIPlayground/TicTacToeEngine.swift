//
//  TicTacToeEngine.swift
//  SwiftUIPlayground
//
//  Created by Ula on 19/01/2026.
//

import Foundation

final class TicTacToeEngine: ObservableObject {

    enum Player: String {
        case x = "X"
        case o = "O"

        mutating func toggle() {
            self = (self == .x) ? .o : .x
        }
    }

    enum GameState: Equatable {
        case playing(current: Player)
        case win(Player, line: [Int])
        case draw

        var statusText: String {
            switch self {
            case .playing(let current):
                return "Current: \(current.rawValue)"
            case .win(let winner, _):
                return "\(winner.rawValue) wins!"
            case .draw:
                return "Draw!"
            }
        }

        var isGameOver: Bool {
            switch self {
            case .playing:
                return false
            case .win, .draw:
                return true
            }
        }
    }

    enum MatchState: Equatable {
        case inProgress
        case finished(winner: Player)
    }

    // MARK: - Public state (UI reads this)
    @Published private(set) var board: [Player?] = Array(repeating: nil, count: 9)
    @Published private(set) var state: GameState = .playing(current: .x)
    @Published private(set) var matchState: MatchState = .inProgress
    @Published private(set) var timerEnabled: Bool = true
    @Published private(set) var secondsLeft: Int
    @Published private(set) var moveTimeLimit: Int

    @Published private(set) var xScore: Int = 0
    @Published private(set) var oScore: Int = 0
    @Published private(set) var targetScore: Int = 3

    private let winningLines: [[Int]] = [
        [0, 1, 2],
        [3, 4, 5],
        [6, 7, 8],
        [0, 3, 6],
        [1, 4, 7],
        [2, 5, 8],
        [0, 4, 8],
        [2, 4, 6]
    ]


    init(moveTimeLimit: Int = 10) {
        self.moveTimeLimit = moveTimeLimit
        self.secondsLeft = moveTimeLimit
    }

    // MARK: - Game actions

    func makeMove(at index: Int) {
        guard matchState == .inProgress else { return }
        // 1) Don't play like game over
        guard case .playing(let currentPlayer) = state else { return }

        // 2) Don't overwrite the occupied field
        guard board[index] == nil else { return }

        // 3) Move
        board[index] = currentPlayer

        // 4) Check win / draw
        if let line = winningLine(currentPlayer) {
            incrementScore(for: currentPlayer)
            state = .win(currentPlayer, line: line)

            checkForMatchWinner()
            return
        }

        if board.allSatisfy({ $0 != nil }) {
            state = .draw
            return
        }

        // 5) Change player
        var next = currentPlayer
        next.toggle()
        state = .playing(current: next)
        secondsLeft = moveTimeLimit
    }

    func tick() {
        guard timerEnabled else { return }
        guard case .playing(let currentPlayer) = state else { return }

        if secondsLeft > 0 {
            secondsLeft -= 1
        }

        if secondsLeft == 0 {
            var next = currentPlayer
            next.toggle()
            state = .playing(current: next)
            secondsLeft = moveTimeLimit
        }
    }

    func newMatch() {
        xScore = 0
        oScore = 0
        matchState = .inProgress
        resetBoard()
    }

    func resetBoard() {
        timerEnabled = true
        board = Array(repeating: nil, count: 9)
        state = .playing(current: .x)
        secondsLeft = moveTimeLimit
    }

    func resetScore() {
        xScore = 0
        oScore = 0
        resetBoard()
    }

    func toggleTimer() {
        timerEnabled.toggle()
    }

    func setMoveTimeLimit(_ newValue: Int) {
        moveTimeLimit = newValue
        resetBoard()
    }

    func setTargetScore(_ value: Int) {
        targetScore = value
        resetScore()
    }

    // MARK: - Helpers


    func isHighlightedCell(_ index: Int) -> Bool {
        guard case .win(_, let line) = state else { return false }
        return line.contains(index)

    }

    private func checkForMatchWinner() {
        if xScore >= targetScore {
            matchState = .finished(winner: .x)
        } else if oScore >= targetScore {
            matchState = .finished(winner: .o)
        }
    }

    private func winningLine(_ player: Player) -> [Int]? {
        for line in winningLines {
            let a = board[line[0]]
            let b = board[line[1]]
            let c = board[line[2]]

            if a == player && b == player && c == player {
                return line
            }
        }
        return nil
    }
    
    private func incrementScore(for player: Player) {
        if player == .x { xScore += 1 }
        else { oScore += 1 }
    }
}
