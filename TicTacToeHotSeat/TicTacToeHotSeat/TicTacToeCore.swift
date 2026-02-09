//
//  TicTacToeCore.swift
//  TicTacToeHotSeat
//
//  Created by Ula on 06/02/2026.
//

import Foundation

final class TicTacToeCore {

    // MARK: - Types

    enum Player: String, Equatable {
        case x = "X"
        case o = "O"

        mutating func toggle() { self = (self == .x) ? .o : .x }
    }

    enum GameState: Equatable {
        case playing(current: Player)
        case win(Player, line: [Int])
        case draw

        var statusText: String {
            switch self {
            case .playing(let current): return L10n.statusCurrent(current.rawValue)
            case .win(let winner, _):   return L10n.statusWin(winner.rawValue)
            case .draw:                return L10n.statusDraw
            }
        }

        var isGameOver: Bool {
            switch self {
            case .playing: return false
            case .win, .draw: return true
            }
        }
    }

    enum MatchState: Equatable {
        case inProgress
        case finished(winner: Player)
    }

    enum Opponent: Equatable { case human, ai }
    enum AIDifficulty: Equatable { case random, smartBlockWin, minimax }

    // MARK: - Private

    private var config: GameConfig
    private var board: [Player?]
    private var state: GameState
    private var matchState: MatchState

    private var xScore: Int
    private var oScore: Int

    private var history: MoveHistory<Player>

    private var timerEnabled: Bool
    private var secondsLeft: Int

    private var pendingAIMove: DispatchWorkItem?
    private let clock: GameClock
    private let rules = GameRules()

    // MARK: - Init

    init(config: GameConfig = .default, clock: GameClock? = nil) {
        self.config = config
        self.board = Array(repeating: nil, count: 9)
        self.state = .playing(current: .x)
        self.matchState = .inProgress
        self.xScore = 0
        self.oScore = 0
        self.history = MoveHistory()

        let c = clock ?? CountdownClock(secondsLeft: config.moveTimeLimit, isEnabled: true)
        self.clock = c

        self.timerEnabled = c.isEnabled
        self.secondsLeft = c.secondsLeft
    }

    var snapshot: TicTacToeSnapshot {
        TicTacToeSnapshot(
            config: config,
            board: board,
            state: state,
            matchState: matchState,
            timerEnabled: timerEnabled,
            secondsLeft: secondsLeft,
            xScore: xScore,
            oScore: oScore,
            canUndo: canUndo
        )
    }

    // MARK: - Game actions

    func makeMove(at index: Int) {
        guard matchState == .inProgress else { return }
        guard (0..<board.count).contains(index) else { return }
        guard case .playing(let currentPlayer) = state else { return }
        guard board[index] == nil else { return }

        cancelPendingAIMove()

        board[index] = currentPlayer
        history.record(index: index, player: currentPlayer)

        if let line = rules.winningLine(for: currentPlayer, board: board) {
            incrementScore(for: currentPlayer)
            state = .win(currentPlayer, line: line)
            checkForMatchWinner()
            return
        }

        if board.allSatisfy({ $0 != nil }) {
            state = .draw
            return
        }

        var next = currentPlayer
        next.toggle()
        state = .playing(current: next)

        if isTimedTurn(next) {
            clock.reset(to: config.moveTimeLimit)
            secondsLeft = clock.secondsLeft
        }

        scheduleAIMoveIfNeeded()
    }

    func tick() {
        guard matchState == .inProgress else { return }
        guard timerEnabled else { return }
        guard case .playing(let currentPlayer) = state else { return }
        guard isTimedTurn(currentPlayer) else { return }

        clock.tick()
        secondsLeft = clock.secondsLeft

        if secondsLeft == 0 {
            cancelPendingAIMove()

            var next = currentPlayer
            next.toggle()
            state = .playing(current: next)

            if isTimedTurn(next) {
                clock.reset(to: config.moveTimeLimit)
                secondsLeft = clock.secondsLeft
            }

            scheduleAIMoveIfNeeded()
        }
    }

    func newMatch() {
        cancelPendingAIMove()
        xScore = 0
        oScore = 0
        matchState = .inProgress
        resetBoard()
    }

    func resetBoard() {
        cancelPendingAIMove()
        timerEnabled = true
        clock.isEnabled = true
        board = Array(repeating: nil, count: 9)
        state = .playing(current: .x)
        clock.reset(to: config.moveTimeLimit)
        secondsLeft = clock.secondsLeft
        history.reset()
    }

    var canUndo: Bool {
        matchState == .inProgress &&
        !state.isGameOver &&
        !history.isEmpty
    }

    func undoLastMove() {
        guard canUndo else { return }

        cancelPendingAIMove()

        switch config.opponent {
        case .human:
            undoOne()

        // If AI has already played: undo the O and X.
        // If AI didn't make it: just undo X.
        case .ai:
            if history.last?.player == .o {
                _ = undoOne()
            }
            _ = undoOne()
        }

        clock.reset(to: config.moveTimeLimit)
        secondsLeft = clock.secondsLeft
    }

    func toggleTimer() {
        timerEnabled.toggle()
        clock.isEnabled = timerEnabled
    }

    // MARK: - Config (single entry point)

    func updateConfig(_ newConfig: GameConfig) {
        let old = config
        guard newConfig != old else { return }

        cancelPendingAIMove()
        config = newConfig

        let requiresNewMatch =
            newConfig.opponent != old.opponent ||
            newConfig.aiDifficulty != old.aiDifficulty ||
            newConfig.targetScore != old.targetScore

        if requiresNewMatch {
            newMatch()
        } else {
            resetBoard()
        }
    }

    // MARK: - UI helpers

    func isHighlightedCell(_ index: Int) -> Bool {
        guard case .win(_, let line) = state else { return false }
        return line.contains(index)
    }

    // MARK: - Private helpers

    @discardableResult
    private func undoOne() -> MoveHistory<Player>.Move? {
        guard let move = history.popLast() else { return nil }

        board[move.index] = nil
        state = .playing(current: move.player)

        return move
    }

    private var aiStrategy: AIStrategy {
        switch config.aiDifficulty {
        case .random:
            return RandomAIStrategy()
        case .smartBlockWin:
            return SmartBlockWinStrategy()
        case .minimax:
            return MinimaxStrategy()
        }
    }

    private func scheduleAIMoveIfNeeded() {
        guard pendingAIMove == nil else { return }
        guard timerEnabled else { return }
        guard config.opponent == .ai else { return }
        guard matchState == .inProgress else { return }
        guard case .playing(let current) = state else { return }
        guard current == .o else { return }

        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.pendingAIMove = nil
            guard let index = self.aiStrategy.chooseMove(board: self.board) else { return }
            self.makeMove(at: index)
        }

        pendingAIMove = work
        DispatchQueue.main.asyncAfter(deadline: .now() + config.aiMoveDelay, execute: work)
    }

    private func cancelPendingAIMove() {
        pendingAIMove?.cancel()
        pendingAIMove = nil
    }

    private func isTimedTurn(_ player: Player) -> Bool {
        if config.opponent == .human { return true }
        return player == .x
    }

    private func checkForMatchWinner() {
        if xScore >= config.targetScore {
            matchState = .finished(winner: .x)
        } else if oScore >= config.targetScore {
            matchState = .finished(winner: .o)
        }
    }

    private func incrementScore(for player: Player) {
        if player == .x { xScore += 1 } else { oScore += 1 }
    }
}

struct TicTacToeSnapshot: Equatable {
    let config: GameConfig
    let board: [TicTacToeCore.Player?]
    let state: TicTacToeCore.GameState
    let matchState: TicTacToeCore.MatchState
    let timerEnabled: Bool
    let secondsLeft: Int
    let xScore: Int
    let oScore: Int
    let canUndo: Bool
}
