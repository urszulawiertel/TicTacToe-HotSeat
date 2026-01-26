//
//  TicTacToeEngine+Config.swift
//  SwiftUIPlayground
//
//  Created by Ula on 26/01/2026.
//

extension TicTacToeEngine {
    func setMoveTimeLimit(_ value: Int) {
        var c = config
        c.moveTimeLimit = value
        updateConfig(c)
    }

    func setTargetScore(_ value: Int) {
        var c = config
        c.targetScore = value
        updateConfig(c)
    }

    func setOpponent(_ value: Opponent) {
        var c = config
        c.opponent = value
        updateConfig(c)
    }

    func setAIDifficulty(_ value: AIDifficulty) {
        var c = config
        c.aiDifficulty = value
        updateConfig(c)
    }
}
