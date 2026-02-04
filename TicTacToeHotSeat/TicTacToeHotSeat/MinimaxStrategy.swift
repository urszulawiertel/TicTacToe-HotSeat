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
        if evaluateTerminal(board) != nil { return nil }
        return emptyIndices(board).first
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
}

