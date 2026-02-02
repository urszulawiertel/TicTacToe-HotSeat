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
    private static let winningLines: [[Int]] = [
        [0, 1, 2], [3, 4, 5], [6, 7, 8],
        [0, 3, 6], [1, 4, 7], [2, 5, 8],
        [0, 4, 8], [2, 4, 6]
    ]

    func chooseMove(board: [TicTacToeEngine.Player?]) -> Int? {
        if let win = winningMoveIndex(for: .o, board: board) { return win }
        if let block = winningMoveIndex(for: .x, board: board) { return block }

        let empty = board.indices.filter { board[$0] == nil }
        return empty.randomElement()
    }

    private func winningMoveIndex(
        for player: TicTacToeEngine.Player,
        board: [TicTacToeEngine.Player?]
    ) -> Int? {
        for line in Self.winningLines {
            let values = line.map { board[$0] }
            let playerCount = values.filter { $0 == player }.count
            let emptyCount = values.filter { $0 == nil }.count

            if playerCount == 2 && emptyCount == 1 {
                return line.first(where: { board[$0] == nil })
            }
        }
        return nil
    }
}

