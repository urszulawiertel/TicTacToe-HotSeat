//
//  SwiftUIPlaygroundTests.swift
//  SwiftUIPlaygroundTests
//
//  Created by Ula on 13/01/2026.
//

import XCTest
@testable import SwiftUIPlayground

final class TicTacToeGameTests: XCTestCase {

    // MARK: - Helpers

    private func makeGame(_ mutate: (inout GameConfig) -> Void = { _ in }) -> TicTacToeEngine {
        var c = GameConfig.default
        mutate(&c)

        return TicTacToeEngine(config: c)
    }

    private func advanceRunLoop(_ seconds: TimeInterval = 0.01) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    // MARK: - Tests

    func testFirstMoveIsX() {
        let game = makeGame()
        game.makeMove(at: 0)
        XCTAssertEqual(game.board[0], .x)
    }

    func testSecondMoveIsO() {
        let game = makeGame()
        game.makeMove(at: 0)
        game.makeMove(at: 1)
        XCTAssertEqual(game.board[1], .o)
    }

    func testCannotOverwriteCell() {
        let game = makeGame()
        game.makeMove(at: 0)
        game.makeMove(at: 0)
        XCTAssertEqual(game.board[0], .x)
    }

    func testWinTopRow() {
        let game = makeGame()
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
        let game = makeGame()
        game.makeMove(at: 0)
        game.makeMove(at: 3)
        game.makeMove(at: 1)
        game.makeMove(at: 4)
        game.makeMove(at: 2)

        XCTAssertEqual(game.xScore, 1)
        XCTAssertEqual(game.oScore, 0)
    }

    func testTimerDecrementsWhilePlaying() {
        let game = makeGame { $0.moveTimeLimit = 10 }
        XCTAssertEqual(game.secondsLeft, 10)

        game.tick()
        XCTAssertEqual(game.secondsLeft, 9)
    }

    func testTimerSwitchesPlayerOnTimeout() {
        let game = makeGame { $0.moveTimeLimit = 2 }

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
        let game = makeGame { $0.moveTimeLimit = 10 }

        game.tick() // 9
        game.tick() // 8
        XCTAssertEqual(game.secondsLeft, 8)

        game.makeMove(at: 0)
        XCTAssertEqual(game.secondsLeft, 10)
    }

    func testTimerDoesNotRunAfterWin() {
        let game = makeGame { $0.moveTimeLimit = 10 }

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
        let game = makeGame { $0.moveTimeLimit = 10 }
        game.tick()
        XCTAssertEqual(game.secondsLeft, 9)

        var c = GameConfig.default
        c.moveTimeLimit = 5
        game.updateConfig(c)

        XCTAssertEqual(game.moveTimeLimit, 5)
        XCTAssertEqual(game.secondsLeft, 5)
    }

    func testMatchFinishesWhenXReachesTargetScore() {
        let game = makeGame {
            $0.moveTimeLimit = 10
            $0.targetScore = 1
        }

        game.makeMove(at: 0)
        game.makeMove(at: 3)
        game.makeMove(at: 1)
        game.makeMove(at: 4)
        game.makeMove(at: 2)

        if case .finished(let winner) = game.matchState {
            XCTAssertEqual(winner, .x)
        } else {
            XCTFail("Expected match finished")
        }
    }

    func testCannotMoveAfterMatchFinished() {
        let game = makeGame {
            $0.moveTimeLimit = 10
            $0.targetScore = 1
        }

        game.makeMove(at: 0)
        game.makeMove(at: 3)
        game.makeMove(at: 1)
        game.makeMove(at: 4)
        game.makeMove(at: 2)

        game.makeMove(at: 5) // should be ignored
        XCTAssertNil(game.board[5])
    }

    func testAIMakesMoveForO() {
        let game = makeGame {
            $0.moveTimeLimit = 10
            $0.opponent = .ai
            $0.aiMoveDelay = 0
        }

        game.makeMove(at: 0) // X
        advanceRunLoop()

        let oCount = game.board.filter { $0 == .o }.count
        XCTAssertEqual(oCount, 1)
    }


    func testAIDoesNotMoveOnXTurn() {
        let game = makeGame {
            $0.opponent = .ai
            $0.aiMoveDelay = 0
        }

        // Start = X turn
        game.makeAIMoveIfNeeded()
        advanceRunLoop()

        let oCount = game.board.filter { $0 == .o }.count
        XCTAssertEqual(oCount, 0)
    }

    func testSmartAIBlocksXWinningMove() {
        let game = makeGame {
            $0.moveTimeLimit = 10
            $0.opponent = .ai
            $0.aiDifficulty = .smartBlockWin
            $0.aiMoveDelay = 0
        }

        game.makeMove(at: 0)  // X
        advanceRunLoop()      // O auto
        game.makeMove(at: 1)  // X
        advanceRunLoop()      // O should block

        XCTAssertEqual(game.board[2], .o)
    }

    func testSmartAIPlaysWinningMoveWhenAvailable() {
        let game = makeGame {
            $0.moveTimeLimit = 10
            $0.opponent = .ai
            $0.aiDifficulty = .smartBlockWin
            $0.aiMoveDelay = 0
        }

        game.makeMove(at: 0) // X
        game.makeMove(at: 3) // O
        game.makeMove(at: 1) // X
        game.makeMove(at: 4) // O
        game.makeMove(at: 8) // X

        game.makeAIMoveIfNeeded()
        advanceRunLoop()

        XCTAssertEqual(game.board[5], .o)
    }
}
