//
//  ContentView.swift
//  SwiftUIPlayground
//
//  Created by Ula on 13/01/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var game = TicTacToeEngine(moveTimeLimit: 10)

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

                HStack(spacing: 32) {
                    Text("Time: \(game.secondsLeft)s")
                        .font(.subheadline)

                    Button(game.timerEnabled ? "Pause Timer" : "Resume Timer") {
                        game.toggleTimer()
                    }
                    .buttonStyle(.bordered)
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
