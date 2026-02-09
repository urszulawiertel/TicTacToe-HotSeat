//
//  GameRules.swift
//  TicTacToeHotSeat
//
//  Created by Ula on 05/02/2026.
//

import Foundation

struct GameRules {

    private let winningLines: [[Int]] = [
        [0,1,2], [3,4,5], [6,7,8],
        [0,3,6], [1,4,7], [2,5,8],
        [0,4,8], [2,4,6]
    ]

    func isWinner(_ player: TicTacToeCore.Player, board: [TicTacToeCore.Player?]) -> Bool {
        winningLines.contains { line in
            board[line[0]] == player &&
            board[line[1]] == player &&
            board[line[2]] == player
        }
    }

    func winningLine(for player: TicTacToeCore.Player, board: [TicTacToeCore.Player?]) -> [Int]? {
        for line in winningLines {
            let a = board[line[0]],
                b = board[line[1]],
                c = board[line[2]]
            if a == player && b == player && c == player { return line }
        }
        return nil
    }

    func winningMoveIndex(for player: TicTacToeCore.Player, board: [TicTacToeCore.Player?]) -> Int? {
        for i in board.indices where board[i] == nil {
            var copy = board
            copy[i] = player
            if isWinner(player, board: copy) {
                return i
            }
        }
        return nil
    }
}

