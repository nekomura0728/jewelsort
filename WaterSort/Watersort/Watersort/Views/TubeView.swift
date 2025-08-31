import SwiftUI

struct TubeView: View {
    let tubeIndex: Int
    let tube: [Int]
    let capacity: Int
    let isSelected: Bool
    let isDragSource: Bool
    let isDragDestination: Bool
    let onTap: () -> Void
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragEnded: (DragGesture.Value) -> Void
    @ObservedObject var animationManager: AnimationManager
    
    // 使用カラーは GameColors から取得（視認性の一貫性）
    
    // レイアウト（容量に応じて自動スケール）
    private var segmentHeight: CGFloat {
        switch capacity {
        case 6...: return 44
        case 5:    return 52
        default:   return 66
        }
    }
    private var cupCornerRadius: CGFloat { max(10, segmentHeight * 0.25) }
    private var tubeWidth: CGFloat {
        switch capacity {
        case 6...: return 66
        case 5:    return 74
        default:   return 84
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // コップの中身（液体セグメント）
            VStack(spacing: -2) {
                ForEach(0..<capacity, id: \.self) { index in
                    let colorIndex = capacity - 1 - index
                    segmentView(colorIndex: colorIndex, slotIndex: index)
                }
            }
            .frame(width: tubeWidth)
            .clipShape(cupShape)
            .overlay(cupRim)
            .background(cupBackground)
        }
        .onTapGesture {
            onTap()
        }
        .gesture(
            DragGesture(coordinateSpace: .named("board"))
                .onChanged(onDragChanged)
                .onEnded(onDragEnded)
        )
        .scaleEffect(scaleEffect)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isDragSource)
        .animation(.easeInOut(duration: 0.2), value: isDragDestination)
    }

    // MARK: - Helpers to simplify type-checking
    @ViewBuilder
    private func segmentView(colorIndex: Int, slotIndex: Int) -> some View {
        if colorIndex < tube.count {
            let color = GameColors.getColor(for: tube[colorIndex] % 14)
            GemSegment(color: color, height: segmentHeight)
            .scaleEffect(animationManager.tubeAnimationStates[tubeIndex]?.selectedScale ?? 1.0)
            .shakeEffect(isShaking: animationManager.tubeAnimationStates[tubeIndex]?.isShaking ?? false)
            .glowEffect(
                color: animationManager.tubeAnimationStates[tubeIndex]?.glowColor ?? .clear,
                intensity: animationManager.tubeAnimationStates[tubeIndex]?.isGlowing == true ? 0.3 : 0.0
            )
        } else {
            EmptySlotView(height: segmentHeight)
        }
    }

    private var cupShape: some InsettableShape { RoundedRectangle(cornerRadius: cupCornerRadius) }

    private var cupRim: some View {
        cupShape
            .stroke(Color.white.opacity(0.5), lineWidth: 2)
            .blendMode(.overlay)
    }

    private var cupBackground: some View {
        // 宝石ケース風の背景（やや明るめのビロード調に調整）
        cupShape
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.23, green: 0.22, blue: 0.30),
                        Color(red: 0.15, green: 0.16, blue: 0.22)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                cupShape
                    .stroke(Color.white.opacity(0.08), lineWidth: 1.5)
                    .blendMode(.overlay)
            )
            .overlay(
                cupShape.stroke(Color.black.opacity(0.18), lineWidth: 1)
            )
    }
    
    private var borderColor: Color {
        if isDragDestination {
            return .green
        } else if isDragSource {
            return .blue
        } else if isSelected {
            return .blue
        } else {
            return .gray
        }
    }
    
    private var borderWidth: CGFloat {
        if isDragDestination || isDragSource {
            return 4
        } else if isSelected {
            return 3
        } else {
            return 2
        }
    }
    
    private var scaleEffect: CGFloat {
        if isDragSource || isDragDestination {
            return 1.15
        } else if isSelected {
            return 1.1
        } else {
            return 1.0
        }
    }
}

// MARK: - Gem Segment (宝石セグメント)
struct GemSegment: View {
    let color: Color
    let height: CGFloat
    
    var body: some View {
        let rectHeight = height
        let rectWidth: CGFloat = height // 正方形を維持
        ZStack {
            // Faceted gem via Canvas
            Canvas { context, size in
                let w = rectWidth
                let h = rectHeight
                let inset: CGFloat = 6
                let cx = w * 0.5

                // Color variants
                let base = color
                let light = base.mixed(with: .white, t: 0.30)
                let midLight = base.mixed(with: .white, t: 0.20)
                let midDark = base.mixed(with: .black, t: 0.18)
                let dark = base.mixed(with: .black, t: 0.28)

                func path(_ points: [CGPoint]) -> Path {
                    var p = Path()
                    guard let first = points.first else { return p }
                    p.move(to: first)
                    for pt in points.dropFirst() { p.addLine(to: pt) }
                    p.closeSubpath()
                    return p
                }

                // Facets definitions (6面 + 中央)
                let cxInset: CGFloat = w * 0.18
                let yTop: CGFloat = h * 0.34
                let yBottom: CGFloat = h * 0.66
                let top = path([
                    CGPoint(x: inset, y: inset),
                    CGPoint(x: w - inset, y: inset),
                    CGPoint(x: cx + cxInset, y: yTop),
                    CGPoint(x: cx - cxInset, y: yTop)
                ])
                let bottom = path([
                    CGPoint(x: cx - cxInset, y: yBottom),
                    CGPoint(x: cx + cxInset, y: yBottom),
                    CGPoint(x: w - inset, y: h - inset),
                    CGPoint(x: inset, y: h - inset)
                ])
                let left = path([
                    CGPoint(x: inset, y: inset),
                    CGPoint(x: cx - cxInset, y: yTop),
                    CGPoint(x: cx - cxInset, y: yBottom),
                    CGPoint(x: inset, y: h - inset)
                ])
                let right = path([
                    CGPoint(x: w - inset, y: inset),
                    CGPoint(x: cx + cxInset, y: yTop),
                    CGPoint(x: cx + cxInset, y: yBottom),
                    CGPoint(x: w - inset, y: h - inset)
                ])
                let center = path([
                    CGPoint(x: cx - cxInset, y: yTop),
                    CGPoint(x: cx + cxInset, y: yTop),
                    CGPoint(x: cx + cxInset, y: yBottom),
                    CGPoint(x: cx - cxInset, y: yBottom)
                ])
                let tl = path([
                    CGPoint(x: inset, y: inset),
                    CGPoint(x: cx - cxInset, y: yTop),
                    CGPoint(x: cx - w * 0.25, y: h * 0.26)
                ])
                let tr = path([
                    CGPoint(x: w - inset, y: inset),
                    CGPoint(x: cx + cxInset, y: yTop),
                    CGPoint(x: cx + w * 0.25, y: h * 0.26)
                ])

                // Fill order for nicer overlaps
                context.fill(left, with: .linearGradient(Gradient(colors: [dark, base]), startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: w * 0.5, y: h * 0.7)))
                context.fill(right, with: .linearGradient(Gradient(colors: [midLight, light]), startPoint: CGPoint(x: w * 0.5, y: h * 0.3), endPoint: CGPoint(x: w, y: h)))
                context.fill(top, with: .linearGradient(Gradient(colors: [light, base]), startPoint: CGPoint(x: cx, y: 0), endPoint: CGPoint(x: cx, y: h * 0.38)))
                context.fill(bottom, with: .linearGradient(Gradient(colors: [dark, midDark]), startPoint: CGPoint(x: cx, y: h * 0.62), endPoint: CGPoint(x: cx, y: h)))
                context.fill(center, with: .linearGradient(Gradient(colors: [light, midDark]), startPoint: CGPoint(x: cx - 4, y: h * 0.38), endPoint: CGPoint(x: cx + 4, y: h * 0.62)))
                context.fill(tl, with: .color(light.opacity(0.75)))
                context.fill(tr, with: .color(light.opacity(0.75)))

                // Specular glint
                var glint = Path()
                glint.move(to: CGPoint(x: cx - w * 0.22, y: h * 0.18))
                glint.addLine(to: CGPoint(x: cx - w * 0.05, y: h * 0.22))
                context.stroke(glint, with: .color(Color.white.opacity(0.6)), lineWidth: 1.6)

                // Secondary glint
                var glint2 = Path()
                glint2.move(to: CGPoint(x: cx + w * 0.08, y: h * 0.30))
                glint2.addLine(to: CGPoint(x: cx + w * 0.20, y: h * 0.27))
                context.stroke(glint2, with: .color(Color.white.opacity(0.45)), lineWidth: 1.2)
            }
            .frame(width: rectWidth, height: rectHeight)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            // Outer subtle highlight
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.22), lineWidth: 1.2)
                .frame(width: rectWidth, height: rectHeight)
                .blendMode(.screen)
        }
    }
}

// 動く波面（上縁のみ）
struct LiquidSurfaceWave: View {
    var amplitude: CGFloat = 2.0
    var speed: Double = 1.2
    var wavelength: CGFloat? = nil // nil の場合は幅から自動算出
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let resolvedWavelength = wavelength ?? max(40, w * 0.9)
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    var path = Path()
                    let step: CGFloat = 2
                    var x: CGFloat = 0
                    func y(_ x: CGFloat) -> CGFloat {
                        let angle = (Double(x) / Double(resolvedWavelength)) * 2.0 * Double.pi + t * speed
                        return amplitude * 0.6 + amplitude * CGFloat(sin(angle))
                    }
                    path.move(to: CGPoint(x: 0, y: y(0)))
                    while x <= size.width {
                        path.addLine(to: CGPoint(x: x, y: y(x)))
                        x += step
                    }

                    // 明るいハイライト線
                    context.stroke(path, with: .color(Color.white.opacity(0.6)), lineWidth: 1.2)
                    // 影（下側に薄く）
                    let stroked = path.strokedPath(.init(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
                    let shadowPath = stroked.applying(.init(translationX: 0, y: 1))
                    context.stroke(shadowPath, with: .color(Color.black.opacity(0.08)), lineWidth: 1.0)
                }
            }
        }
        .clipped()
    }
}

struct TubeGridView: View {
    let tubes: [[Int]]
    let capacity: Int
    let selectedTubeIndex: Int?
    let dragSourceIndex: Int?
    let dragDestinationIndex: Int?
    let onTubeTap: (Int) -> Void
    let onDragChanged: (Int, DragGesture.Value) -> Void
    let onDragEnded: (Int, DragGesture.Value) -> Void
    @ObservedObject var animationManager: AnimationManager
    let onFramesUpdate: ([Int: CGRect]) -> Void
    
    private let columns = [
        GridItem(.adaptive(minimum: 70), spacing: 14)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(0..<tubes.count, id: \.self) { index in
                VStack(spacing: 6) {
                    TubeView(
                        tubeIndex: index,
                        tube: tubes[index],
                        capacity: capacity,
                        isSelected: selectedTubeIndex == index,
                        isDragSource: dragSourceIndex == index,
                        isDragDestination: dragDestinationIndex == index,
                        onTap: {
                            onTubeTap(index)
                        },
                        onDragChanged: { value in
                            onDragChanged(index, value)
                        },
                        onDragEnded: { value in
                            onDragEnded(index, value)
                        },
                        animationManager: animationManager
                    )
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .preference(key: TubeFramesKey.self, value: [index: geo.frame(in: .named("board"))])
                        }
                    )

                    Text("Case \(index + 1)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .onPreferenceChange(TubeFramesKey.self) { frames in
            onFramesUpdate(frames)
        }
    }
}

// MARK: - PreferenceKey for tube frames
struct TubeFramesKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - Empty Slot View
struct EmptySlotView: View {
    let height: CGFloat
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.clear)
            .frame(height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

// Color mixing helper removed; consolidated in Models/ColorModels.swift

#Preview {
    VStack(spacing: 20) {
        TubeView(
            tubeIndex: 0,
            tube: [0, 1, 2, 3],
            capacity: 4,
            isSelected: false,
            isDragSource: false,
            isDragDestination: false,
            onTap: {
                print("Tapped")
            },
            onDragChanged: { _ in
                print("Drag changed")
            },
            onDragEnded: { _ in
                print("Drag ended")
            },
            animationManager: AnimationManager()
        )
        
        TubeView(
            tubeIndex: 1,
            tube: [0, 1, 2, 3],
            capacity: 4,
            isSelected: true,
            isDragSource: false,
            isDragDestination: false,
            onTap: {
                print("Tapped")
            },
            onDragChanged: { _ in
                print("Drag changed")
            },
            onDragEnded: { _ in
                print("Drag ended")
            },
            animationManager: AnimationManager()
        )
        
        TubeView(
            tubeIndex: 2,
            tube: [1, 2],
            capacity: 4,
            isSelected: false,
            isDragSource: false,
            isDragDestination: false,
            onTap: {
                print("Tapped")
            },
            onDragChanged: { _ in
                print("Drag changed")
            },
            onDragEnded: { _ in
                print("Drag ended")
            },
            animationManager: AnimationManager()
        )
    }
    .padding()
}
