//
//  HeaderView.swift
//  TicTacToeHotSeat
//
//  Created by Ula on 09/02/2026.
//

import SwiftUI

struct HeaderView: View {
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
                Text(L10n.firstTo(targetScore))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                HStack(spacing: 16) {
                    Text(L10n.xScore(xScore))
                    Text(L10n.oScore(oScore))
                }
                .font(.subheadline)

                Spacer()

                HStack(spacing: 10) {
                    Text(L10n.secondsLeft(secondsLeft))
                        .font(.subheadline.monospacedDigit())
                        .frame(width: 40, alignment: .trailing)

                    Button(action: onToggleTimer) {
                        Image(systemName: timerEnabled ? SFSymbol.pause : SFSymbol.play)
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(.bordered)

                    Button(action: onUndo) {
                        Image(systemName: SFSymbol.undo)
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
