//
//  MinimaxStrategy.swift
//  TicTacToeHotSeat
//
//  Created by Ula on 04/02/2026.
//

import Foundation

struct MinimaxStrategy: AIStrategy {

    private let ai: TicTacToeEngine.Player = .o
    private let human: TicTacToeEngine.Player = .x

    private static let winningLines: [[Int]] = [
        [0, 1, 2], [3, 4, 5], [6, 7, 8],
        [0, 3, 6], [1, 4, 7], [2, 5, 8],
        [0, 4, 8], [2, 4, 6]
    ]

    private enum TerminalScore: Int {
        case aiWin = 1
        case draw = 0
        case humanWin = -1
    }

    func chooseMove(board: [TicTacToeEngine.Player?]) -> Int? {
        if terminalScore(for: board) != nil { return nil }

        let empties = board.indices.filter { board[$0] == nil }
        guard !empties.isEmpty else { return nil }

        var bestMove: Int?
        var bestScore = Int.min

        for i in empties {
            var b = board
            b[i] = .o
            let score = minimax(board: b, isMaximizing: false)
            if score > bestScore {
                bestScore = score
                bestMove = i
            }
        }

        return bestMove
    }
}

// MARK: - Helpers

private extension MinimaxStrategy {

    private func emptyIndices(_ board: [TicTacToeEngine.Player?]) -> [Int] {
        board.indices.filter { board[$0] == nil }
    }

    private func evaluateTerminal(_ board: [TicTacToeEngine.Player?]) -> TerminalScore? {
        if isWinner(ai, board: board) { return .aiWin }
        if isWinner(human, board: board) { return .humanWin }
        if emptyIndices(board).isEmpty { return .draw }
        return nil
    }

    private func isWinner(_ player: TicTacToeEngine.Player, board: [TicTacToeEngine.Player?]) -> Bool {
        for line in Self.winningLines {
            let a = board[line[0]]
            let b = board[line[1]]
            let c = board[line[2]]
            if a == player && b == player && c == player {
                return true
            }
        }
        return false
    }

    private func terminalScore(for board: [TicTacToeEngine.Player?]) -> Int? {
        if isWinner(.o, board: board) { return 10 }
        if isWinner(.x, board: board) { return -10 }
        if board.allSatisfy({ $0 != nil }) { return 0 }
        return nil
    }

    private func minimax(board: [TicTacToeEngine.Player?], isMaximizing: Bool) -> Int {
        if let score = terminalScore(for: board) { return score }

        let empties = board.indices.filter { board[$0] == nil }

        if isMaximizing {
            var best = Int.min
            for i in empties {
                var b = board
                b[i] = .o
                best = max(best, minimax(board: b, isMaximizing: false))
            }
            return best
        } else {
            var best = Int.max
            for i in empties {
                var b = board
                b[i] = .x
                best = min(best, minimax(board: b, isMaximizing: true))
            }
            return best
        }
    }
}

