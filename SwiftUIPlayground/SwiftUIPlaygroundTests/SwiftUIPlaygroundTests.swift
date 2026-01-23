//
//  SwiftUIPlaygroundTests.swift
//  SwiftUIPlaygroundTests
//
//  Created by Ula on 13/01/2026.
//

import XCTest
@testable import SwiftUIPlayground

final class TicTacToeGameTests: XCTestCase {

    func testFirstMoveIsX() {
        let game = TicTacToeEngine()
        game.makeMove(at: 0)
        XCTAssertEqual(game.board[0], .x)
    }

    func testSecondMoveIsO() {
        let game = TicTacToeEngine()
        game.makeMove(at: 0)
        game.makeMove(at: 1)
        XCTAssertEqual(game.board[1], .o)
    }

    func testCannotOverwriteCell() {
        let game = TicTacToeEngine()
        game.makeMove(at: 0)
        game.makeMove(at: 0)
        XCTAssertEqual(game.board[0], .x)
    }

    func testWinTopRow() {
        let game = TicTacToeEngine()
        game.makeMove(at: 0)
        game.makeMove(at: 3)
        game.makeMove(at: 1)
        game.makeMove(at: 4)
        game.makeMove(at: 2)

        if case .win(let winner, let line) = game.state {
            XCTAssertEqual(winner, .x)
            XCTAssertEqual(line, [0, 1, 2])
        } else {
            XCTFail("Expected win state")
        }
    }

    func testScoreIncrementsOnWin() {
        let game = TicTacToeEngine()
        game.makeMove(at: 0)
        game.makeMove(at: 3)
        game.makeMove(at: 1)
        game.makeMove(at: 4)
        game.makeMove(at: 2)
        XCTAssertEqual(game.xScore, 1)
        XCTAssertEqual(game.oScore, 0)
    }

    func testTimerDecrementsWhilePlaying() {
        let game = TicTacToeEngine(moveTimeLimit: 10)
        XCTAssertEqual(game.secondsLeft, 10)

        game.tick()
        XCTAssertEqual(game.secondsLeft, 9)
    }

    func testTimerSwitchesPlayerOnTimeout() {
        let game = TicTacToeEngine(moveTimeLimit: 2)

        game.tick() // 1
        XCTAssertEqual(game.secondsLeft, 1)

        game.tick() // 0 => switch + reset
        XCTAssertEqual(game.secondsLeft, 2)

        if case .playing(let current) = game.state {
            XCTAssertEqual(current, .o)
        } else {
            XCTFail("Expected playing state")
        }
    }

    func testSuccessfulMoveResetsTimer() {
        let game = TicTacToeEngine(moveTimeLimit: 10)

        game.tick() // 9
        game.tick() // 8
        XCTAssertEqual(game.secondsLeft, 8)

        game.makeMove(at: 0)
        XCTAssertEqual(game.secondsLeft, 10)
    }

    func testTimerDoesNotRunAfterWin() {
        let game = TicTacToeEngine(moveTimeLimit: 10)

        game.makeMove(at: 0)
        game.makeMove(at: 3)
        game.makeMove(at: 1)
        game.makeMove(at: 4)
        game.makeMove(at: 2) // X wins

        let before = game.secondsLeft
        game.tick()
        XCTAssertEqual(game.secondsLeft, before)
    }

    func testChangingMoveTimeLimitResetsTimer() {
        let game = TicTacToeEngine(moveTimeLimit: 10)
        game.tick()
        XCTAssertEqual(game.secondsLeft, 9)

        game.setMoveTimeLimit(5)
        XCTAssertEqual(game.moveTimeLimit, 5)
        XCTAssertEqual(game.secondsLeft, 5)
    }

    func testMatchFinishesWhenXReachesTargetScore() {
        let game = TicTacToeEngine(moveTimeLimit: 10)
        game.setTargetScore(1)

        game.makeMove(at: 0)
        game.makeMove(at: 3)
        game.makeMove(at: 1)
        game.makeMove(at: 4)
        game.makeMove(at: 2) // X wins round -> match should finish

        if case .finished(let winner) = game.matchState {
            XCTAssertEqual(winner, .x)
        } else {
            XCTFail("Expected match finished")
        }
    }

    func testCannotMoveAfterMatchFinished() {
        let game = TicTacToeEngine(moveTimeLimit: 10)
        game.setTargetScore(1)

        game.makeMove(at: 0)
        game.makeMove(at: 3)
        game.makeMove(at: 1)
        game.makeMove(at: 4)
        game.makeMove(at: 2)

        game.makeMove(at: 5) // should be ignored
        XCTAssertNil(game.board[5])
    }

    func testAIMakesMoveForO() {
        let game = TicTacToeEngine(moveTimeLimit: 10)
        game.setOpponent(.aiRandom)

        game.makeMove(at: 0) // X
        game.makeAIMoveIfNeeded()

        // should be one move O on the board
        let oCount = game.board.filter { $0 == .o }.count
        XCTAssertEqual(oCount, 1)
    }

    func testAIDoesNotMoveOnXTurn() {
        let game = TicTacToeEngine(moveTimeLimit: 10)
        game.setOpponent(.aiRandom)

        // start = X turn
        game.makeAIMoveIfNeeded()

        let oCount = game.board.filter { $0 == .o }.count
        XCTAssertEqual(oCount, 0)
    }

}
