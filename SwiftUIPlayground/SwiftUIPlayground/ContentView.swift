//
//  ContentView.swift
//  SwiftUIPlayground
//
//  Created by Ula on 13/01/2026.
//

import SwiftUI

enum Player: String {
    case x = "X"
    case o = "O"

    mutating func toggle() {
        self = (self == .x) ? .o : .x
    }
}

struct ContentView: View {
    @State private var board: [Player?] = Array(repeating: nil, count: 9)
    @State private var currentPlayer: Player = .x

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Current: \(currentPlayer.rawValue)")
                    .font(.headline)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0..<9, id: \.self) { index in
                        CellView(symbol: board[index]?.rawValue)
                            .onTapGesture {
                                handleTap(at: index)
                            }
                    }
                }
                .padding(.horizontal)

                Button("Reset") {
                    reset()
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("Tic-Tac-Toe")
        }
    }

    private func handleTap(at index: Int) {
        guard board[index] == nil else { return }

        board[index] = currentPlayer
        currentPlayer.toggle()
    }

    private func reset() {
        board = Array(repeating: nil, count: 9)
        currentPlayer = .x
    }
}

struct CellView: View {
    let symbol: String?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .stroke(lineWidth: 2)
                .frame(height: 90)

            Text(symbol ?? "")
                .font(.system(size: 42, weight: .bold, design: .rounded))
        }
        .contentShape(Rectangle())
    }
}
