//
//  MoveHistory.swift
//  TicTacToeHotSeat
//
//  Created by Ula on 02/02/2026.
//

import Foundation

struct MoveHistory<P: Equatable> {

    struct Move: Equatable {
        let index: Int
        let player: P
    }

    private(set) var moves: [Move] = []

    var isEmpty: Bool { moves.isEmpty }
    var last: Move? { moves.last }

    mutating func record(index: Int, player: P) {
        moves.append(Move(index: index, player: player))
    }

    mutating func popLast() -> Move? {
        moves.popLast()
    }

    mutating func reset() {
        moves.removeAll()
    }
}
