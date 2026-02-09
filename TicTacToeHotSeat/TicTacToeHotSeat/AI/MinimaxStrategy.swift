//
//  MinimaxStrategy.swift
//  TicTacToeHotSeat
//
//  Created by Ula on 04/02/2026.
//

import Foundation

struct MinimaxStrategy: AIStrategy {

    private let ai: TicTacToeCore.Player = .o
    private let human: TicTacToeCore.Player = .x
    private let rules: GameRules

    init(rules: GameRules = GameRules()) {
        self.rules = rules
    }

    func chooseMove(board: [TicTacToeCore.Player?]) -> Int? {
        guard terminalScore(board, depth: 0) == nil else { return nil }

        let empties = emptyIndices(board)
        guard !empties.isEmpty else { return nil }

        var bestMove: Int?
        var bestScore = Int.min

        for i in empties {
            var b = board
            b[i] = ai
            let score = minimax(board: b, isMaximizing: false, depth: 0)
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

    func emptyIndices(_ board: [TicTacToeCore.Player?]) -> [Int] {
        board.indices.filter { board[$0] == nil }
    }

    func terminalScore(_ board: [TicTacToeCore.Player?], depth: Int) -> Int? {
        if rules.isWinner(ai, board: board) { return 10 - depth }
        if rules.isWinner(human, board: board) { return depth - 10 }
        if emptyIndices(board).isEmpty { return 0 }
        return nil
    }

    func minimax(board: [TicTacToeCore.Player?], isMaximizing: Bool, depth: Int) -> Int {
        if let score = terminalScore(board, depth: depth) { return score }

        let empties = emptyIndices(board)

        if isMaximizing {
            var best = Int.min
            for i in empties {
                var b = board
                b[i] = ai
                best = max(best, minimax(board: b, isMaximizing: false, depth: depth + 1))
            }
            return best
        } else {
            var best = Int.max
            for i in empties {
                var b = board
                b[i] = human
                best = min(best, minimax(board: b, isMaximizing: true, depth: depth + 1))
            }
            return best
        }
    }
}

