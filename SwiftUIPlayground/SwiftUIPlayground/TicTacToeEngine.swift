//
//  TicTacToeEngine.swift
//  SwiftUIPlayground
//
//  Created by Ula on 19/01/2026.
//

import Foundation

final class TicTacToeEngine: ObservableObject {

    // MARK: - Types

    enum Player: String, Equatable {
        case x = "X"
        case o = "O"

        mutating func toggle() {
            self = (self == .x) ? .o : .x
        }
    }

    enum GameState: Equatable {
        case playing(current: Player)
        case win(Player, line: [Int])
        case draw

        var statusText: String {
            switch self {
            case .playing(let current):
                return "Current: \(current.rawValue)"
            case .win(let winner, _):
                return "\(winner.rawValue) wins!"
            case .draw:
                return "Draw!"
            }
        }

        var isGameOver: Bool {
            switch self {
            case .playing:
                return false
            case .win, .draw:
                return true
            }
        }
    }

    enum MatchState: Equatable {
        case inProgress
        case finished(winner: Player)
    }

    enum Opponent: Equatable {
        case human
        case ai
    }

    enum AIDifficulty: Equatable {
        case random
        case smartBlockWin
    }

    // MARK: - Public state (UI reads this)

    @Published private(set) var board: [Player?] = Array(repeating: nil, count: 9)
    @Published private(set) var state: GameState = .playing(current: .x)

    @Published private(set) var matchState: MatchState = .inProgress

    @Published private(set) var opponent: Opponent = .human
    @Published private(set) var aiDifficulty: AIDifficulty = .random

    @Published private(set) var timerEnabled: Bool = true
    @Published private(set) var secondsLeft: Int
    @Published private(set) var moveTimeLimit: Int

    @Published private(set) var xScore: Int = 0
    @Published private(set) var oScore: Int = 0
    @Published private(set) var targetScore: Int = 3

    // MARK: - Constants
    private var pendingAIMove: DispatchWorkItem?
    private let aiMoveDelay: TimeInterval = 0.6

    private static let winningLines: [[Int]] = [
        [0, 1, 2],
        [3, 4, 5],
        [6, 7, 8],
        [0, 3, 6],
        [1, 4, 7],
        [2, 5, 8],
        [0, 4, 8],
        [2, 4, 6]
    ]

    // MARK: - Init

    init(moveTimeLimit: Int = 10) {
        self.moveTimeLimit = moveTimeLimit
        self.secondsLeft = moveTimeLimit
    }

    // MARK: - Game actions

    func makeMove(at index: Int) {
        cancelPendingAIMove()
        // Match must be active
        guard matchState == .inProgress else { return }

        // Index must be valid
        guard (0..<board.count).contains(index) else { return }

        // Game must be playable
        guard case .playing(let currentPlayer) = state else { return }

        // Cell must be empty
        guard board[index] == nil else { return }

        board[index] = currentPlayer

        // Win?
        if let line = winningLine(for: currentPlayer) {
            incrementScore(for: currentPlayer)
            state = .win(currentPlayer, line: line)
            checkForMatchWinner()
            cancelPendingAIMove()
            return
        }

        // Draw?
        if board.allSatisfy({ $0 != nil }) {
            state = .draw
            cancelPendingAIMove()
            return
        }

        // Next turn
        var next = currentPlayer
        next.toggle()
        state = .playing(current: next)

        // Successful move resets timer
        secondsLeft = moveTimeLimit
        scheduleAIMoveIfNeeded()
    }

    func tick() {
        guard matchState == .inProgress else { return }
        guard timerEnabled else { return }
        guard case .playing(let currentPlayer) = state else { return }

        if secondsLeft > 0 {
            secondsLeft -= 1
        }

        if secondsLeft == 0 {
            var next = currentPlayer
            next.toggle()
            state = .playing(current: next)
            secondsLeft = moveTimeLimit
            scheduleAIMoveIfNeeded()
        }
    }

    // MARK: - AI scheduling

    private func cancelPendingAIMove() {
        pendingAIMove?.cancel()
        pendingAIMove = nil
    }

    private func shouldAIMoveNow() -> Bool {
        guard opponent == .ai else { return false }
        guard matchState == .inProgress else { return false }
        guard timerEnabled else { return false }
        guard case .playing(let current) = state else { return false }
        return current == .o
    }

    private func scheduleAIMoveIfNeeded() {
        cancelPendingAIMove()
        guard shouldAIMoveNow() else { return }

        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            // Re-check after delay
            guard self.shouldAIMoveNow() else { return }
            guard let index = self.aiMoveIndex() else { return }
            self.makeMove(at: index)
        }

        pendingAIMove = work
        DispatchQueue.main.asyncAfter(deadline: .now() + aiMoveDelay, execute: work)
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
        secondsLeft = moveTimeLimit
    }

    func resetScore() {
        newMatch()
    }

    func toggleTimer() {
        cancelPendingAIMove()
        timerEnabled.toggle()
    }

    func setMoveTimeLimit(_ newValue: Int) {
        cancelPendingAIMove()
        moveTimeLimit = newValue
        resetBoard()
    }

    func setTargetScore(_ value: Int) {
        cancelPendingAIMove()
        targetScore = value
        resetScore()
    }

    func setOpponent(_ newValue: Opponent) {
        cancelPendingAIMove()
        opponent = newValue
        newMatch()
    }

    func setAIDifficulty(_ newValue: AIDifficulty) {
        cancelPendingAIMove()
        aiDifficulty = newValue
        newMatch()
    }

    // MARK: - UI helpers

    func isHighlightedCell(_ index: Int) -> Bool {
        guard case .win(_, let line) = state else { return false }
        return line.contains(index)
    }

    // MARK: - Private helpers

    private func checkForMatchWinner() {
        if xScore >= targetScore {
            matchState = .finished(winner: .x)
        } else if oScore >= targetScore {
            matchState = .finished(winner: .o)
        }
    }

    private func winningLine(for player: Player) -> [Int]? {
        for line in Self.winningLines {
            let a = board[line[0]]
            let b = board[line[1]]
            let c = board[line[2]]

            if a == player && b == player && c == player {
                return line
            }
        }
        return nil
    }

    private func incrementScore(for player: Player) {
        if player == .x { xScore += 1 }
        else { oScore += 1 }
    }

    private func winningMoveIndex(for player: Player) -> Int? {
        for line in Self.winningLines {
            let values = line.map { board[$0] }

            let playerCount = values.filter { $0 == player }.count
            let emptyCount = values.filter { $0 == nil }.count

            if playerCount == 2 && emptyCount == 1 {
                // find empty field in winning line
                for idx in line where board[idx] == nil {
                    return idx
                }
            }
        }
        return nil
    }

    private func randomEmptyIndex() -> Int? {
        let empty = board.indices.filter { board[$0] == nil }
        return empty.randomElement()
    }

    private func aiMoveIndex() -> Int? {
        switch aiDifficulty {
        case .random:
            return randomEmptyIndex()
        case .smartBlockWin:
            if let win = winningMoveIndex(for: .o) { return win }
            if let block = winningMoveIndex(for: .x) { return block }
            return randomEmptyIndex()
        }
    }
}
