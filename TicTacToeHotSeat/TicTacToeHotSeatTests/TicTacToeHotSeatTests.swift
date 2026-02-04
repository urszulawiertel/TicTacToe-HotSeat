//
//  TicTacToeHotSeatTests.swift
//  TicTacToeHotSeatTests
//
//  Created by Ula on 13/01/2026.
//

import XCTest
@testable import TicTacToeHotSeat

final class TicTacToeGameTests: XCTestCase {

    // MARK: - Helpers

    private func makeGame(_ mutate: (inout GameConfig) -> Void = { _ in }) -> TicTacToeEngine {
        var c = GameConfig.default
        mutate(&c)

        return TicTacToeEngine(config: c)
    }

    private func advanceRunLoop(_ seconds: TimeInterval = 0.6) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    // MARK: - Core gameplay

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

    // MARK: - Timer

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

        XCTAssertEqual(game.config.moveTimeLimit, 5)
        XCTAssertEqual(game.secondsLeft, 5)
    }

    func testToggleTimerDisablesClockTicking() {
        let game = makeGame { $0.moveTimeLimit = 10 }
        game.toggleTimer() // disable

        let before = game.secondsLeft
        game.tick()
        XCTAssertEqual(game.secondsLeft, before)
    }

    // MARK: - AI (basic)

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
        game.tick()
        advanceRunLoop()

        let oCount = game.board.filter { $0 == .o }.count
        XCTAssertEqual(oCount, 0)
    }

    // MARK: - AI (delayed scheduling / cancellation)

    func testResetBoardCancelsPendingAIMove() {
        let game = makeGame {
            $0.opponent = .ai
            $0.aiMoveDelay = 0.2
        }

        game.makeMove(at: 0) // X -> schedule AI
        game.resetBoard() // cancel

        advanceRunLoop(0.25)
        XCTAssertEqual(game.board.filter { $0 == .o }.count, 0)
    }

    func testMakingAnotherMoveCancelsPendingAIMove() {
        // Testing that changing the config/mode doesn't leave tasks hanging.
        let game = makeGame {
            $0.opponent = .ai
            $0.aiMoveDelay = 0.2
        }

        game.makeMove(at: 0) // X schedules AI

        var c = game.config // before AI plays change game mode
        c.opponent = .human
        game.updateConfig(c)

        advanceRunLoop(0.25)
        XCTAssertEqual(game.board.filter { $0 == .o }.count, 0)
    }

    func testTimeoutTriggersAIMoveWhenTurnBecomesO() {
        let game = makeGame {
            $0.opponent = .ai
            $0.moveTimeLimit = 1
            $0.aiMoveDelay = 0.1
        }

        game.tick()
        XCTAssertEqual(game.board.filter { $0 == .o }.count, 0)

        advanceRunLoop(0.2)
        XCTAssertEqual(game.board.filter { $0 == .o }.count, 1)
    }

    // MARK: - AI (smartBlockWin)

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

        advanceRunLoop()

        XCTAssertEqual(game.board[5], .o)
    }

    // MARK: - AI (minimax)

    func testMinimaxReturnsNilWhenBoardAlreadyWon() {
        let strategy = MinimaxStrategy()

        let board: [TicTacToeEngine.Player?] = [
            .x, .x, .x,
            .o, .o, nil,
            nil, nil, nil
        ]

        let move = strategy.chooseMove(board: board)

        XCTAssertNil(move)
    }

    func testMinimaxReturnsNilOnDrawBoard() {
        let strategy = MinimaxStrategy()

        let board: [TicTacToeEngine.Player?] = [
            .x, .o, .x,
            .x, .o, .o,
            .o, .x, .x
        ]

        let move = strategy.chooseMove(board: board)

        XCTAssertNil(move)
    }

    func testMinimaxReturnsValidMoveOnEmptyBoard() {
        let strategy = MinimaxStrategy()

        let board: [TicTacToeEngine.Player?] = [
            .x, .o, .x,
            .x, .o, .o,
            .o, .x, nil
        ]

        let move = strategy.chooseMove(board: board)

        XCTAssertEqual(move, 8)
    }

    func testMinimaxPlaysWinningMoveWhenAvailable() {
        let strategy = MinimaxStrategy()
        let board: [TicTacToeEngine.Player?] = [
            .o, .o, nil,
            .x, .x, nil,
            nil, nil, nil
        ]

        let move = strategy.chooseMove(board: board)

        XCTAssertEqual(move, 2)
    }

    func testMinimaxBlocksXWinningMove() {
        let strategy = MinimaxStrategy()
        let board: [TicTacToeEngine.Player?] = [
            .x, .x, nil,
            .o, nil, nil,
            nil, nil, nil
        ]
    
        let move = strategy.chooseMove(board: board)

        XCTAssertEqual(move, 2)
    }

    // MARK: - Undo (AI-aware)

    func testUndoInHumanModeRevertsLastMove() {
        let game = makeGame {
            $0.opponent = .human
        }

        game.makeMove(at: 0)
        XCTAssertEqual(game.board[0], .x)

        XCTAssertTrue(game.canUndo)
        game.undoLastMove()

        XCTAssertNil(game.board[0])

        if case .playing(let current) = game.state {
            XCTAssertEqual(current, .x)
        } else {
            XCTFail("Expected playing state")
        }
    }

    func testUndoInAIModeRevertsPlayerAndAI() {
        let game = makeGame {
            $0.opponent = .ai
            $0.aiMoveDelay = 0
        }

        game.makeMove(at: 0)
        advanceRunLoop()

        XCTAssertEqual(game.board.filter { $0 == .x }.count, 1)
        XCTAssertEqual(game.board.filter { $0 == .o }.count, 1)

        XCTAssertTrue(game.canUndo)
        game.undoLastMove()

        XCTAssertEqual(game.board.filter { $0 == .x }.count, 0)
        XCTAssertEqual(game.board.filter { $0 == .o }.count, 0)

        if case .playing(let current) = game.state {
            XCTAssertEqual(current, .x)
        } else {
            XCTFail("Expected playing state")
        }
    }

    func testUndoResetsTimer() {
        let game = makeGame {
            $0.opponent = .human
            $0.moveTimeLimit = 10
        }

        game.tick()
        game.tick()
        XCTAssertEqual(game.secondsLeft, 8)

        game.makeMove(at: 0) // X
        XCTAssertEqual(game.secondsLeft, 10)

        game.tick()
        XCTAssertEqual(game.secondsLeft, 9)

        game.undoLastMove()
        XCTAssertEqual(game.secondsLeft, 10)
    }

    func testCannotUndoAfterWin() {
        let game = makeGame {
            $0.opponent = .human
            $0.moveTimeLimit = 10
        }

        // X wins top row
        game.makeMove(at: 0) // X
        game.makeMove(at: 3) // O
        game.makeMove(at: 1) // X
        game.makeMove(at: 4) // O
        game.makeMove(at: 2) // X wins

        XCTAssertFalse(game.canUndo)
        game.undoLastMove()

        if case .win(let winner, _) = game.state {
            XCTAssertEqual(winner, .x)
        } else {
            XCTFail("Expected win state")
        }
    }

    func testUndoCancelsPendingAIMove() {
        let game = makeGame {
            $0.opponent = .ai
            $0.aiMoveDelay = 0.2
        }

        game.makeMove(at: 0) // X schedules AI
        game.undoLastMove()  // should cancel pending too

        advanceRunLoop(0.25)
        XCTAssertEqual(game.board.filter { $0 == .o }.count, 0)
        XCTAssertEqual(game.board.filter { $0 == .x }.count, 0)
    }
}
