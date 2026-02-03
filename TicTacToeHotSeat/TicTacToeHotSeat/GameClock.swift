//
//  GameClock.swift
//  TicTacToeHotSeat
//
//  Created by Ula on 03/02/2026.
//

import Foundation

protocol GameClock: AnyObject {
    var secondsLeft: Int { get }
    var isEnabled: Bool { get set }

    func tick()
    func reset(to seconds: Int)
}
