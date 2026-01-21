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

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {

                Text(game.state.statusText)
                    .font(.headline)

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

                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("Tic-Tac-Toe")
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
