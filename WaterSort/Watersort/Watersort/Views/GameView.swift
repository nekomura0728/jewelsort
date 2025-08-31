import SwiftUI

struct GameView: View {
    @ObservedObject private var progressStore: ProgressStore
    @StateObject private var gameCore: GameCore
    @StateObject private var animationManager = AnimationManager()
    @Environment(\.dismiss) private var dismiss
    @State private var showingWinAlert = false
    @State private var showingHint: (from: Int, to: Int)?
    @State private var dragSourceIndex: Int?
    @State private var dragDestinationIndex: Int?
    @State private var dragOffset: CGSize = .zero
    @State private var headerGlow = false
    @State private var buttonPulse = false
    @State private var showingRestartConfirm = false
    
    init(difficulty: Difficulty = .normal, seed: Int? = nil, progressStore: ProgressStore) {
        let resolvedSeed = seed ?? Int(Date().timeIntervalSince1970)
        // 難易度プリセット：ハード以降は色数と容量を増やす
        let config: LevelConfig
        switch difficulty {
        case .normal:
            config = LevelConfig(seed: resolvedSeed, colors: 5, capacity: 4, extraEmpty: 2, difficulty: .normal)
        case .hard:
            // 色+1、容量+1、空き1
            config = LevelConfig(seed: resolvedSeed, colors: 6, capacity: 5, extraEmpty: 1, difficulty: .hard)
        case .expert:
            // ハードと同じ容量で、色のみ増やす（レイアウトを保つ）
            config = LevelConfig(seed: resolvedSeed, colors: 7, capacity: 5, extraEmpty: 1, difficulty: .expert)
        }
        self.progressStore = progressStore
        self._gameCore = StateObject(wrappedValue: GameCore(config: config, progressStore: progressStore))
    }
    
    var body: some View {
        ZStack {
            // 宝石調の背景
            JewelBackground()
            
            VStack(spacing: 0) {
                // ヘッダー
                gameHeader
                
                // ゲームボード
                gameBoard
                
                // フッター
                gameFooter
            }
        }
        .coordinateSpace(name: "board")
        .navigationTitle("")
        .navigationBarHidden(true)
        .alert("🎉 Level Clear!", isPresented: $showingWinAlert) {
            Button("Next Level") {
                gameCore.nextLevel()
            }
            Button("Back to Home") { dismiss() }
        } message: {
            Text("Congrats!\nMoves: \(gameCore.gameState.currentMoves)\nTime: \(formatTime(gameCore.gameState.currentTime))")
        }
        .onChange(of: gameCore.gameState.isWon) { _, isWon in
            if isWon {
                showingWinAlert = true
                // 勝利時のアニメーション
                animationManager.animateVictory()
            }
        }
        .onAppear {
            // ヘッダーのグローアニメーション
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                headerGlow = true
            }
            // ボタンのパルスアニメーション
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                buttonPulse = true
            }
        }
    }
    
    private var gameHeader: some View {
        HStack(spacing: 8) {
            VStack(spacing: 2) {
                Text("Difficulty").font(.caption2).foregroundColor(.white.opacity(0.8))
                Text("\(gameCore.difficulty.displayName)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial))

            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.left.arrow.right").font(.caption2).foregroundColor(.white.opacity(0.85))
                    Text("\(gameCore.gameState.currentMoves)").font(.footnote).foregroundColor(.white)
                }
                .padding(.vertical, 6).padding(.horizontal, 8)
                .background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial))

                HStack(spacing: 4) {
                    Image(systemName: "clock").font(.caption2).foregroundColor(.white.opacity(0.85))
                    Text(formatTime(gameCore.gameState.currentTime)).font(.footnote).foregroundColor(.white)
                }
                .padding(.vertical, 6).padding(.horizontal, 8)
                .background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial))
            }

            Spacer(minLength: 6)

            HStack(spacing: 8) {
                SmallActionButton(icon: "lightbulb.fill", color: .orange, enabled: gameCore.canHint) {
                    if let hint = gameCore.getHint() { showingHint = hint }
                }
                Button(action: {
                    gameCore.undo()
                }) {
                    HStack(spacing: 6) {
                        Text("Undo")
                            .font(.footnote)
                            .fontWeight(.medium)
                        Image(systemName: "arrow.uturn.backward")
                            .font(.footnote)
                    }
                    .foregroundColor(.white)
                    .padding(8)
                    .background(FacetedPanel(color: gameCore.canUndo ? .blue : .gray))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(!gameCore.canUndo)
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial).shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3))
        .padding(.horizontal, 8)
        .padding(.top, 6)
    }
    
    private var gameBoard: some View {
        VStack(spacing: 20) {
            // ヒント表示
            if let hint = showingHint {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                    
                    Text("Hint: Case \(hint.from + 1) → Case \(hint.to + 1)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            showingHint = nil
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.orange)
                            .font(.title3)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.orange.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal)
                .transition(.scale.combined(with: .opacity))
            }
            
            // チューブグリッド
            TubeGridView(
                tubes: gameCore.gameState.tubes,
                capacity: gameCore.gameState.capacity,
                selectedTubeIndex: gameCore.selectedTubeIndex,
                dragSourceIndex: dragSourceIndex,
                dragDestinationIndex: dragDestinationIndex,
                onTubeTap: { index in
                    gameCore.selectTube(index)
                },
                onDragChanged: { index, value in
                    handleDragChanged(index: index, value: value)
                },
                onDragEnded: { index, value in
                    handleDragEnded(index: index, value: value)
                },
                animationManager: animationManager,
                onFramesUpdate: { frames in
                    tubeFrames = frames
                }
            )
            
            Spacer()
        }
        .padding(.top)
    }
    
    private var gameFooter: some View {
        HStack(spacing: 8) {
            IconFooterButton(icon: "house.fill", title: "Home", color: .blue) { dismiss() }
            IconFooterButton(icon: "arrow.clockwise", title: "Retry", color: .red) {
                showingRestartConfirm = true
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
        .confirmationDialog("やりなおしますか？", isPresented: $showingRestartConfirm, titleVisibility: .visible) {
            Button("やりなおす", role: .destructive) { gameCore.restart() }
            Button("キャンセル", role: .cancel) { }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Drag & Drop
    
    private func handleDragChanged(index: Int, value: DragGesture.Value) {
        if dragSourceIndex == nil {
            // ドラッグ開始
            dragSourceIndex = index
            dragOffset = value.translation
        } else {
            // ドラッグ中
            dragOffset = value.translation
            
            // ドラッグ先のチューブを特定
            let location = value.location
            if let destinationIndex = findTubeAtLocation(location) {
                dragDestinationIndex = destinationIndex
            } else {
                dragDestinationIndex = nil
            }
        }
    }
    
    private func handleDragEnded(index: Int, value: DragGesture.Value) {
        if let sourceIndex = dragSourceIndex,
           let destinationIndex = dragDestinationIndex,
           sourceIndex != destinationIndex {
            
            if gameCore.canPour(from: sourceIndex, to: destinationIndex) {
                // 液体の移動アニメーション
                let sourceColor = gameCore.gameState.tubes[sourceIndex].last ?? 0
                let color = tubeColors[sourceColor % tubeColors.count]
                animationManager.animateLiquidPour(from: sourceIndex, to: destinationIndex, color: color)
                
                gameCore.pour(from: sourceIndex, to: destinationIndex)
                
                // 成功時のアニメーション
                animationManager.animateTubeGlow(destinationIndex, color: .green, duration: 0.5)
            } else {
                // 無効な移動時のアニメーション
                animationManager.animateTubeShake(sourceIndex)
            }
        }
        
        // ドラッグ状態をリセット
        dragSourceIndex = nil
        dragDestinationIndex = nil
        dragOffset = .zero
    }
    
    @State private var tubeFrames: [Int: CGRect] = [:]
    private func findTubeAtLocation(_ location: CGPoint) -> Int? {
        return tubeFrames.first(where: { $0.value.contains(location) })?.key
    }
    
    // MARK: - Colors
    
    private let tubeColors: [Color] = [
        .red, .blue, .green, .yellow, .orange, .purple, .pink, .cyan,
        .brown, .mint, .indigo, .teal, .gray, .black
    ]
}

// MARK: - 補助ビュー

// 統計表示
struct StatDisplay: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let glow: Bool
    
    var body: some View {
        ZStack {
            FacetedPanel(color: color)
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 34, height: 34)
                        .scaleEffect(glow ? 1.05 : 1.0)
                    Image(systemName: icon)
                        .font(.footnote)
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.subheadline).fontWeight(.bold)
                        .foregroundColor(.white)
                    Text(label)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.85))
                }
                Spacer(minLength: 2)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// アクションボタン
struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            action()
        }) {
            ZStack {
                FacetedPanel(color: isEnabled ? color : .gray)
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.title3)
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .disabled(!isEnabled)
    }
}

// フッターボタン
struct FooterButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            action()
        }) {
            ZStack {
                FacetedPanel(color: color)
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.caption)
                    Text(title)
                        .font(.footnote)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
    }
}

// さらに小型のアイコン専用フッターボタン（高さを最小化）
struct IconFooterButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    @State private var pressed = false
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { pressed = false }
            }
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(FacetedPanel(color: color))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .scaleEffect(pressed ? 0.98 : 1.0)
        }
        .frame(maxWidth: .infinity)
    }
}

// ゲーム背景
struct GameBackground: View {
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        ZStack {
            // グラデーション背景
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.05),
                    Color.cyan.opacity(0.03),
                    Color.teal.opacity(0.05),
                    Color.blue.opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // 浮遊する小さな泡
            ForEach(0..<12, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.2), .cyan.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: CGFloat.random(in: 8...25))
                    .offset(
                        x: CGFloat.random(in: -150...150),
                        y: CGFloat.random(in: -600...600)
                    )
                    .opacity(0.4)
                    .scaleEffect(0.3 + 0.7 * sin(animationPhase * .pi + Double(index)))
                    .animation(
                        .easeInOut(duration: 4.0 + Double(index) * 0.3)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: animationPhase
                    )
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 6.0).repeatForever(autoreverses: false)) {
                animationPhase = 1
            }
        }
    }
}

// 小型アクションボタン（ヘッダー用）
struct SmallActionButton: View {
    let icon: String
    let color: Color
    let enabled: Bool
    let action: () -> Void
    @State private var pressed = false
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { pressed = false }
            }
            action()
        }) {
            Image(systemName: icon)
                .font(.footnote)
                .foregroundColor(.white)
                .padding(8)
                .background(FacetedPanel(color: enabled ? color : .gray))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .scaleEffect(pressed ? 0.95 : 1.0)
        }
        .disabled(!enabled)
    }
}

#Preview {
    NavigationView {
        GameView(difficulty: .normal, progressStore: ProgressStore())
    }
}
