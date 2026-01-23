//
//  ContentView.swift
//  SwiftUIPlayground
//
//  Created by Ula on 13/01/2026.
//

import SwiftUI

struct ContentView: View {
    private let defaultTimeLimit = 10

    @StateObject private var game: TicTacToeEngine
    @State private var selectedTimeLimit: Int
    @State private var activeAlert: ActiveAlert?
    @State private var isAIMode: Bool = false

    init() {
        let limit = defaultTimeLimit
        _selectedTimeLimit = State(initialValue: limit)
        _game = StateObject(wrappedValue: TicTacToeEngine(moveTimeLimit: limit))
    }

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private enum ActiveAlert: Identifiable {
        case gameOver
        case matchOver

        var id: String {
            switch self {
            case .gameOver: return "gameOver"
            case .matchOver: return "matchOver"
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 14) {

                HeaderView(
                    statusText: game.state.statusText,
                    targetScore: game.targetScore,
                    xScore: game.xScore,
                    oScore: game.oScore,
                    secondsLeft: game.secondsLeft,
                    timerEnabled: game.timerEnabled,
                    onToggleTimer: { game.toggleTimer() }
                )

                Picker("Move time", selection: $selectedTimeLimit) {
                    Text("5s").tag(5)
                    Text("10s").tag(10)
                    Text("15s").tag(15)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: selectedTimeLimit) { newValue in
                    game.setMoveTimeLimit(newValue)
                }
                .onChange(of: game.moveTimeLimit) { newValue in
                    selectedTimeLimit = newValue
                }

                Picker("Opponent", selection: $isAIMode) {
                    Text("2 Players").tag(false)
                    Text("VS AI").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: isAIMode) { newValue in
                    game.setOpponent(newValue ? .aiRandom : .human)
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0..<9, id: \.self) { index in
                        CellView(
                            symbol: game.board[index]?.rawValue,
                            isHighlighted: game.isHighlightedCell(index)
                        )
                        .opacity(game.state.isGameOver ? 0.6 : 1.0)
                        .onTapGesture {
                            game.makeMove(at: index)
                            game.makeAIMoveIfNeeded()
                        }
                    }
                }
                .padding(.horizontal)

                HStack(spacing: 12) {
                    Button("Reset") {
                        game.resetBoard()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("New Match") {
                        game.newMatch()
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("Tic-Tac-Toe")
            .onReceive(timer) { _ in
                game.tick()
                game.makeAIMoveIfNeeded()
            }
            .alert(item: $activeAlert) { alert in
                switch alert {
                case .gameOver:
                    return Alert(
                        title: Text("Game Over"),
                        message: Text(game.state.statusText),
                        primaryButton: .default(Text("Play Again")) {
                            game.resetBoard()
                        },
                        secondaryButton: .destructive(Text("New Match")) {
                            game.newMatch()
                        }
                    )

                case .matchOver:
                    let winnerText: String = {
                        if case .finished(let winner) = game.matchState {
                            return "\(winner.rawValue) wins the match!"
                        }
                        return "Match finished"
                    }()

                    return Alert(
                        title: Text("Match Over"),
                        message: Text(winnerText),
                        dismissButton: .default(Text("New Match")) {
                            game.newMatch()
                        }
                    )
                }
            }
            .onChange(of: game.state) { newState in
                guard game.matchState == .inProgress else { return }
                if newState.isGameOver {
                    activeAlert = .gameOver
                }
            }
            .onChange(of: game.matchState) { newValue in
                if case .finished = newValue {
                    activeAlert = .matchOver
                }
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
    let onToggleTimer: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(statusText)
                    .font(.headline)

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

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .stroke(lineWidth: isHighlighted ? 6 : 2)
                .frame(height: 90)

            Text(symbol ?? "")
                .font(.system(size: 42, weight: .bold, design: .rounded))
        }
        .contentShape(Rectangle())
    }
}
