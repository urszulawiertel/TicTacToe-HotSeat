//
//  CountdownClock.swift
//  TicTacToeHotSeat
//
//  Created by Ula on 03/02/2026.
//

import Foundation

final class CountdownClock: GameClock {
    private(set) var secondsLeft: Int
    var isEnabled: Bool

    init(secondsLeft: Int, isEnabled: Bool = true) {
        self.secondsLeft = secondsLeft
        self.isEnabled = isEnabled
    }

    func tick() {
        guard isEnabled else { return }
        guard secondsLeft > 0 else { return }
        secondsLeft -= 1
    }

    func reset(to seconds: Int) {
        secondsLeft = seconds
    }
}
