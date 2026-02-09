//
//  CellView.swift
//  TicTacToeHotSeat
//
//  Created by Ula on 09/02/2026.
//

import SwiftUI

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

