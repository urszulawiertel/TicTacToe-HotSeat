//
//  ContentView.swift
//  SwiftUIPlayground
//
//  Created by Ula on 13/01/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var game = TicTacToeEngine()
    @State private var selectedTimeLimit: Int
    @State private var activeAlert: ActiveAlert?

    private let defaultTimeLimit = 10

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
            VStack(spacing: 16) {

                Text(game.state.statusText)
                    .font(.headline)

                Text("Best of \(game.targetScore)")
                    .font(.caption)

                HStack(spacing: 24) {
                    Text("X: \(game.xScore)")
                    Text("O: \(game.oScore)")
                }
                .font(.subheadline)

                HStack(spacing: 12) {
                    Text("Time: \(game.secondsLeft)s")
                        .font(.subheadline.monospacedDigit())
                        .frame(width: 90, alignment: .leading)

                    Button {
                        game.toggleTimer()
                    } label: {
                        Label("Timer", systemImage: game.timerEnabled ? "pause.fill" : "play.fill")
                    }
                    .frame(width: 120)
                    .buttonStyle(.bordered)
                }

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

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0..<9, id: \.self) { index in
                        CellView(symbol: game.board[index]?.rawValue, isHighlighted: game.isHighlightedCell(index))
                            .opacity(game.state.isGameOver ? 0.6 : 1.0)
                            .onTapGesture {
                                game.makeMove(at: index)
                            }
                    }
                }
                .padding(.horizontal)

                HStack(spacing: 12) {
                    Button("Reset") {
                        game.resetBoard()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Reset Score") {
                        game.resetScore()
                    }
                    .buttonStyle(.bordered)
                }

                .onReceive(timer) { _ in
                    game.tick()
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
                            secondaryButton: .destructive(Text("Reset Score")) {
                                game.resetScore()
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

                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("Tic-Tac-Toe")

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
