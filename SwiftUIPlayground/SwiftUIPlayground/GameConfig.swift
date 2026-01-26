//
//  GameConfig.swift
//  SwiftUIPlayground
//
//  Created by Ula on 26/01/2026.
//

import Foundation

struct GameConfig: Equatable {
    var moveTimeLimit: Int = 10
    var targetScore: Int = 3

    var opponent: TicTacToeEngine.Opponent = .human
    var aiDifficulty: TicTacToeEngine.AIDifficulty = .random

    /// Controlled delay before AI makes its move (seconds).
    var aiMoveDelay: TimeInterval = 0.45

    static let `default` = GameConfig()
}
