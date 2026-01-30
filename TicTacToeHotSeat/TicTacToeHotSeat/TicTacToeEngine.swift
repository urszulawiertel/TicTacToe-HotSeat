//
//  TicTacToeEngine.swift
//  TicTacToeHotSeat
//
//  Created by Ula on 19/01/2026.
//

import Foundation

final class TicTacToeEngine: ObservableObject {

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
            case .playing(let current): return "Current: \(current.rawValue)"
            case .win(let winner, _):   return "\(winner.rawValue) wins!"
            case .draw:                return "Draw!"
            }
        }

        var isGameOver: Bool {
            switch self {
            case .playing: return false
            case .win, .draw: return true
            }
        }
    }

    struct Move: Equatable {
        let index: Int
        let player: Player
    }

    enum MatchState: Equatable {
        case inProgress
        case finished(winner: Player)
    }

    enum Opponent: Equatable { case human, ai }
    enum AIDifficulty: Equatable { case random, smartBlockWin }

    // MARK: - Public state (UI reads this)

    @Published private(set) var config: GameConfig
    @Published private(set) var board: [Player?] = Array(repeating: nil, count: 9)
    @Published private(set) var state: GameState = .playing(current: .x)
    @Published private(set) var matchState: MatchState = .inProgress

    @Published private(set) var timerEnabled: Bool = true
    @Published private(set) var secondsLeft: Int

    @Published private(set) var xScore: Int = 0
    @Published private(set) var oScore: Int = 0

    // MARK: - Private

    private var pendingAIMove: DispatchWorkItem?

    private static let winningLines: [[Int]] = [
        [0, 1, 2], [3, 4, 5], [6, 7, 8],
        [0, 3, 6], [1, 4, 7], [2, 5, 8],
        [0, 4, 8], [2, 4, 6]
    ]

    // MARK: - Init

    init(config: GameConfig = .default) {
        self.config = config
        self.secondsLeft = config.moveTimeLimit
    }

    // MARK: - Game actions

    func makeMove(at index: Int) {
        guard matchState == .inProgress else { return }
        guard (0..<board.count).contains(index) else { return }
        guard case .playing(let currentPlayer) = state else { return }
        guard board[index] == nil else { return }

        cancelPendingAIMove()

        board[index] = currentPlayer
        moveHistory.append(Move(index: index, player: currentPlayer))

        if let line = winningLine(for: currentPlayer) {
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
        secondsLeft = config.moveTimeLimit

        scheduleAIMoveIfNeeded()
    }

    func tick() {
        guard matchState == .inProgress else { return }
        guard timerEnabled else { return }
        guard case .playing(let currentPlayer) = state else { return }

        if secondsLeft > 0 { secondsLeft -= 1 }

        if secondsLeft == 0 {
            cancelPendingAIMove()

            var next = currentPlayer
            next.toggle()
            state = .playing(current: next)
            secondsLeft = config.moveTimeLimit

            scheduleAIMoveIfNeeded()
        }
    }

    func makeAIMoveIfNeeded() {
        scheduleAIMoveIfNeeded()
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
        board = Array(repeating: nil, count: 9)
        state = .playing(current: .x)
        secondsLeft = config.moveTimeLimit
        moveHistory.removeAll()
    }

    var canUndo: Bool {
        guard matchState == .inProgress else { return false }
        guard case .playing = state else { return false }
        let required = (config.opponent == .ai) ? 2 : 1
        return moveHistory.count >= required
    }

    func undoLastMove() {
        guard canUndo else { return }
        cancelPendingAIMove()

        let countToUndo = (config.opponent == .ai) ? 2 : 1
        for _ in 0..<countToUndo {
            guard let last = moveHistory.popLast() else { break }
            board[last.index] = nil
        }

        let nextPlayer: Player = {
            if let lastRemaining = moveHistory.last {
                var player = lastRemaining.player
                player.toggle()
                return player
            } else {
                return .x
            }
        }()

        state = .playing(current: nextPlayer)
        secondsLeft = config.moveTimeLimit
    }


    func toggleTimer() { timerEnabled.toggle() }

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

    var moveTimeLimit: Int { config.moveTimeLimit }
    var targetScore: Int { config.targetScore }
    var opponent: Opponent { config.opponent }
    var aiDifficulty: AIDifficulty { config.aiDifficulty }
    var aiMoveDelay: TimeInterval { config.aiMoveDelay }


    // MARK: - Private helpers

    private var moveHistory: [Move] = []

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
            guard let index = self.aiMoveIndex() else { return }
            self.makeMove(at: index)
        }

        pendingAIMove = work
        DispatchQueue.main.asyncAfter(deadline: .now() + config.aiMoveDelay, execute: work)
    }

    private func cancelPendingAIMove() {
        pendingAIMove?.cancel()
        pendingAIMove = nil
    }

    private func checkForMatchWinner() {
        if xScore >= config.targetScore {
            matchState = .finished(winner: .x)
        } else if oScore >= config.targetScore {
            matchState = .finished(winner: .o)
        }
    }

    private func winningLine(for player: Player) -> [Int]? {
        for line in Self.winningLines {
            let a = board[line[0]], b = board[line[1]], c = board[line[2]]
            if a == player && b == player && c == player { return line }
        }
        return nil
    }

    private func incrementScore(for player: Player) {
        if player == .x { xScore += 1 } else { oScore += 1 }
    }

    private func winningMoveIndex(for player: Player) -> Int? {
        for line in Self.winningLines {
            let values = line.map { board[$0] }
            let playerCount = values.filter { $0 == player }.count
            let emptyCount = values.filter { $0 == nil }.count
            if playerCount == 2 && emptyCount == 1 {
                return line.first(where: { board[$0] == nil })
            }
        }
        return nil
    }

    private func randomEmptyIndex() -> Int? {
        let empty = board.indices.filter { board[$0] == nil }
        return empty.randomElement()
    }

    private func aiMoveIndex() -> Int? {
        switch config.aiDifficulty {
        case .random:
            return randomEmptyIndex()
        case .smartBlockWin:
            if let win = winningMoveIndex(for: .o) { return win }
            if let block = winningMoveIndex(for: .x) { return block }
            return randomEmptyIndex()
        }
    }
}
