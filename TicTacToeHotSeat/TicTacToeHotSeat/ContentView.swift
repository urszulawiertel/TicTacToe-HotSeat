//
//  ContentView.swift
//  TicTacToeHotSeat
//
//  Created by Ula on 13/01/2026.
//

import SwiftUI

struct ContentView: View {
    typealias Player = TicTacToeCore.Player
    typealias GameState = TicTacToeCore.GameState
    typealias MatchState = TicTacToeCore.MatchState
    typealias Opponent = TicTacToeCore.Opponent
    typealias AIDifficulty = TicTacToeCore.AIDifficulty

    @StateObject private var game = TicTacToeEngine(config: .default)
    @State private var uiConfig: GameConfig = .default
    @State private var activeAlert: ActiveAlert?

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private enum ActiveAlert: Identifiable {
        case gameOver
        case matchOver
        var id: String { self == .gameOver ? "gameOver" : "matchOver" }
    }

    private var currentGhostSymbol: String? {
        guard game.snapshot.matchState == .inProgress else { return nil }
        guard case .playing(let current) = game.snapshot.state else { return nil }

        if game.snapshot.config.opponent == .ai {
            return current == .x ? current.rawValue : nil
        } else {
            return current.rawValue
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 14) {

                HeaderView(
                    statusText: game.snapshot.state.statusText,
                    targetScore: game.snapshot.config.targetScore,
                    xScore: game.snapshot.xScore,
                    oScore: game.snapshot.oScore,
                    secondsLeft: game.snapshot.secondsLeft,
                    timerEnabled: game.snapshot.timerEnabled,
                    canUndo: game.snapshot.canUndo,
                    onToggleTimer: { game.toggleTimer() },
                    onUndo: { game.undoLastMove() }
                )

                Picker("Move time", selection: $uiConfig.moveTimeLimit) {
                    Text("5s").tag(5)
                    Text("10s").tag(10)
                    Text("15s").tag(15)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Picker("Opponent", selection: $uiConfig.opponent) {
                    Text("2 Players").tag(Opponent.human)
                    Text("VS AI").tag(Opponent.ai)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if uiConfig.opponent == .ai {
                    Picker("Difficulty", selection: $uiConfig.aiDifficulty) {
                        Text("Random").tag(AIDifficulty.random)
                        Text("Smart").tag(AIDifficulty.smartBlockWin)
                        Text("Minimax").tag(AIDifficulty.minimax)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0..<9, id: \.self) { index in
                        CellView(
                            symbol: game.snapshot.board[index]?.rawValue,
                            isHighlighted: game.isHighlightedCell(index),
                            ghostSymbol: currentGhostSymbol,
                            onTap: { game.makeMove(at: index) }
                        )
                        .opacity(game.snapshot.state.isGameOver ? 0.6 : 1.0)
                    }
                }
                .padding(.horizontal)

                HStack(spacing: 12) {
                    Button("Reset") { game.resetBoard() }
                        .buttonStyle(.borderedProminent)

                    Button("New Match") { game.newMatch() }
                        .buttonStyle(.bordered)
                }

                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("Tic-Tac-Toe")
            .onReceive(timer) { _ in game.tick() }

            // sync: UI -> engine
            .onChange(of: uiConfig) { newValue in
                game.updateConfig(newValue)
            }

            // sync: engine -> UI
            .onChange(of: game.snapshot.config) { newValue in
                uiConfig = newValue
            }

            .alert(item: $activeAlert) { alert in
                switch alert {
                case .gameOver:
                    return Alert(
                        title: Text("Game Over"),
                        message: Text(game.snapshot.state.statusText),
                        primaryButton: .default(Text("Play Again")) { game.resetBoard() },
                        secondaryButton: .destructive(Text("New Match")) { game.newMatch() }
                    )
                case .matchOver:
                    let winnerText: String = {
                        if case .finished(let winner) = game.snapshot.matchState {
                            return "\(winner.rawValue) wins the match!"
                        }
                        return "Match finished"
                    }()
                    return Alert(
                        title: Text("Match Over"),
                        message: Text(winnerText),
                        dismissButton: .default(Text("New Match")) { game.newMatch() }
                    )
                }
            }
            .onChange(of: game.snapshot.state) { newState in
                guard game.snapshot.matchState == .inProgress else { return }
                if newState.isGameOver { activeAlert = .gameOver }
            }
            .onChange(of: game.snapshot.matchState) { newValue in
                if case .finished = newValue { activeAlert = .matchOver }
            }
        }
    }
}

private struct HeaderView: View {
    let statusText: String
    let targetScore: Int
    let xScore: Int
    let oScore: Int
    let secondsLeft: Int
    let timerEnabled: Bool
    let canUndo: Bool
    let onToggleTimer: () -> Void
    let onUndo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(statusText).font(.headline)
                Spacer()
                Text("First to \(targetScore)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                HStack(spacing: 16) {
                    Text("X: \(xScore)")
                    Text("O: \(oScore)")
                }
                .font(.subheadline)

                Spacer()

                HStack(spacing: 10) {
                    Text("\(secondsLeft)s")
                        .font(.subheadline.monospacedDigit())
                        .frame(width: 40, alignment: .trailing)

                    Button(action: onToggleTimer) {
                        Image(systemName: timerEnabled ? "pause.fill" : "play.fill")
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(.bordered)

                    Button(action: onUndo) {
                        Image(systemName: "arrow.uturn.backward")
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!canUndo)
                }
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }
}

struct CellView: View {
    let symbol: String?
    let isHighlighted: Bool
    let ghostSymbol: String?
    let onTap: () -> Void

    @State private var showGhost = false
    @State private var ghostWorkItem: DispatchWorkItem?

    private let previewDelay: TimeInterval = 0.2
    private var canPreview: Bool {
        symbol == nil && ghostSymbol != nil
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .stroke(lineWidth: isHighlighted ? 6 : 2)
                .frame(height: 90)

            // Real move
            Text(symbol ?? "")
                .font(.system(size: 42, weight: .bold, design: .rounded))

            // Ghost preview
            if showGhost, let ghostSymbol, symbol == nil {
                Text(ghostSymbol)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .opacity(0.25)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard canPreview else { return }
                    // schedule ghost only once per touch
                    guard ghostWorkItem == nil else { return }

                    let work = DispatchWorkItem {
                        withAnimation(.easeInOut(duration: 0.12)) { showGhost = true }
                    }
                    ghostWorkItem = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + previewDelay, execute: work)
                }
                .onEnded { _ in
                    ghostWorkItem?.cancel()
                    ghostWorkItem = nil
                    
                    if showGhost {
                        // long press ended => hide ghost, NO move
                        withAnimation(.easeInOut(duration: 0.12)) { showGhost = false }
                    } else {
                        // quick press => treat as tap
                        onTap()
                    }
                }
        )
    }
}
