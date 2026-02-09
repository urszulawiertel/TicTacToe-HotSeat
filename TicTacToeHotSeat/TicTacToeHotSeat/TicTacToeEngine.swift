//
//  TicTacToeEngine.swift
//  TicTacToeHotSeat
//
//  Created by Ula on 19/01/2026.
//

import Foundation

final class TicTacToeEngine: ObservableObject {

    @Published private(set) var snapshot: TicTacToeSnapshot
    private let core: TicTacToeCore

    init(config: GameConfig = .default) {
        self.core = TicTacToeCore(config: config)
        self.snapshot = core.snapshot
    }

    private func publish() {
        snapshot = core.snapshot
    }

    // MARK: - API for UI

    func makeMove(at index: Int) { core.makeMove(at: index); publish() }
    func tick() { core.tick(); publish() }
    func newMatch() { core.newMatch(); publish() }
    func resetBoard() { core.resetBoard(); publish() }
    func undoLastMove() { core.undoLastMove(); publish() }
    func toggleTimer() { core.toggleTimer(); publish() }
    func updateConfig(_ newConfig: GameConfig) { core.updateConfig(newConfig); publish() }

    func isHighlightedCell(_ index: Int) -> Bool {
        core.isHighlightedCell(index)
    }
}
