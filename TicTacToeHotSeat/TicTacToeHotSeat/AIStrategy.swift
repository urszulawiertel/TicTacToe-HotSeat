//
//  AIStrategy.swift
//  TicTacToeHotSeat
//
//  Created by Ula on 02/02/2026.
//

import Foundation

protocol AIStrategy {
    func chooseMove(board: [TicTacToeEngine.Player?]) -> Int?
}

// MARK: - Random

struct RandomAIStrategy: AIStrategy {
    func chooseMove(board: [TicTacToeEngine.Player?]) -> Int? {
        let empty = board.indices.filter { board[$0] == nil }
        return empty.randomElement()
    }
}

// MARK: - Smart (block win / take win)

struct SmartBlockWinStrategy: AIStrategy {
    private let rules: GameRules

    init(rules: GameRules = GameRules()) {
        self.rules = rules
    }

    func chooseMove(board: [TicTacToeEngine.Player?]) -> Int? {
        if let win = rules.winningMoveIndex(for: .o, board: board) { return win }
        if let block = rules.winningMoveIndex(for: .x, board: board) { return block }

        let empty = board.indices.filter { board[$0] == nil }
        return empty.randomElement()
    }
}

