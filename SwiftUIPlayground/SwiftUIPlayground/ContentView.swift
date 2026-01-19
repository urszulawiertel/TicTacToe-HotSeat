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

struct ContentView: View {
    @State private var board: [Player?] = Array(repeating: nil, count: 9)
    @State private var state: GameState = .playing(current: .x)

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private let winningLines: [[Int]] = [
        [0, 1, 2],
        [3, 4, 5],
        [6, 7, 8],
        [0, 3, 6],
        [1, 4, 7],
        [2, 5, 8],
        [0, 4, 8],
        [2, 4, 6]
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {

                Text(state.statusText)
                    .font(.headline)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0..<9, id: \.self) { index in
                        CellView(symbol: board[index]?.rawValue, isHighlighted: isHighlightedCell(index))
                            .opacity(state.isGameOver ? 0.6 : 1.0)
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
        // 1) Don't play like game over
        guard case .playing(let currentPlayer) = state else { return }

        // 2) Don't overwrite the occupied field
        guard board[index] == nil else { return }

        // 3) Move
        board[index] = currentPlayer

        // 4) Check win / draw
        if let line = winningLine(currentPlayer) {
            state = .win(currentPlayer, line: line)
            return
        }

        if board.allSatisfy({ $0 != nil }) {
            state = .draw
            return
        }

        // 5) Change player
        var next = currentPlayer
        next.toggle()
        state = .playing(current: next)
    }

    private func winningLine(_ player: Player) -> [Int]? {
        for line in winningLines {
            let a = board[line[0]]
            let b = board[line[1]]
            let c = board[line[2]]

            if a == player && b == player && c == player {
                return line
            }
        }
        return nil
    }

    private func isHighlightedCell(_ index: Int) -> Bool {
        guard case .win(_, let line) = state else { return false }
        return line.contains(index)

    }

    private func reset() {
        board = Array(repeating: nil, count: 9)
        state = .playing(current: .x)
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
