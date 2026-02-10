//
//  L10n.swift
//  TicTacToeHotSeat
//
//  Created by Ula on 09/02/2026.
//

import Foundation

enum L10n {

    // MARK: - Navigation

    static var navTitle: String {
        NSLocalizedString("nav.title", comment: "")
    }

    // MARK: - Game state

    static func statusCurrent(_ player: String) -> String {
        String(format: NSLocalizedString("status.current", comment: ""), player)
    }

    static func statusWin(_ player: String) -> String {
        String(format: NSLocalizedString("status.win", comment: ""), player)
    }

    static var statusDraw: String {
        NSLocalizedString("status.draw", comment: "")
    }

    static var statusAIThinking: String {
        NSLocalizedString("status.aiThinking", comment: "")
    }

    // MARK: - Alerts

    static var gameOverTitle: String {
        NSLocalizedString("alert.gameOver.title", comment: "")
    }

    static var matchOverTitle: String {
        NSLocalizedString("alert.matchOver.title", comment: "")
    }

    static func matchOverMessage(_ player: String) -> String {
        String(format: NSLocalizedString("alert.matchOver.message", comment: ""), player)
    }

    static var matchOverFallback: String {
        NSLocalizedString("alert.matchOver.fallback", comment: "")
    }

    // MARK: - Buttons

    static var playAgain: String {
        NSLocalizedString("button.playAgain", comment: "")
    }

    static var newMatch: String {
        NSLocalizedString("button.newMatch", comment: "")
    }

    static var reset: String {
        NSLocalizedString("button.reset", comment: "")
    }

    // MARK: - Header

    static func firstTo(_ value: Int) -> String {
        String(format: NSLocalizedString("header.firstTo", comment: ""), "\(value)")
    }

    static func secondsLeft(_ value: Int) -> String {
        String(format: NSLocalizedString("header.secondsLeft", comment: ""), value)
    }

    static func xScore(_ value: Int) -> String {
        String(format: NSLocalizedString("header.xScore", comment: ""), value)
    }

    static func oScore(_ value: Int) -> String {
        String(format: NSLocalizedString("header.oScore", comment: ""), value)
    }

    // MARK: - Picker labels

    static var moveTime: String {
        NSLocalizedString("picker.moveTime", comment: "")
    }

    static var opponent: String {
        NSLocalizedString("picker.opponent", comment: "")
    }

    static var difficulty: String {
        NSLocalizedString("picker.difficulty", comment: "")
    }

    // MARK: - Opponent

    static var opponentHuman: String {
        NSLocalizedString("opponent.human", comment: "")
    }

    static var opponentAI: String {
        NSLocalizedString("opponent.ai", comment: "")
    }

    // MARK: - Difficulty

    static var difficultyRandom: String {
        NSLocalizedString("difficulty.random", comment: "")
    }

    static var difficultySmart: String {
        NSLocalizedString("difficulty.smart", comment: "")
    }

    static var difficultyMinimax: String {
        NSLocalizedString("difficulty.minimax", comment: "")
    }
}

