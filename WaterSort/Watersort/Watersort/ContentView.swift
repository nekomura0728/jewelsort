//
//  ContentView.swift
//  Watersort
//
//  Created by 前村　真之介 on 2025/08/28.
//

import SwiftUI

// MARK: - Progress Store Import
// ProgressStore is defined in GameModels.swift

// MARK: - Jewel Background (velvet-like)
struct JewelBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.09, blue: 0.14),
                    Color(red: 0.06, green: 0.07, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            // soft radial lights
            Canvas { context, size in
                func circle(_ center: CGPoint, _ radius: CGFloat, _ color: Color) {
                    let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius*2, height: radius*2)
                    context.fill(Path(ellipseIn: rect), with: .radialGradient(Gradient(colors: [color.opacity(0.35), .clear]), center: center, startRadius: 0, endRadius: radius))
                }
                circle(CGPoint(x: size.width*0.2, y: size.height*0.3), min(size.width, size.height)*0.35, .purple)
                circle(CGPoint(x: size.width*0.8, y: size.height*0.7), min(size.width, size.height)*0.4, .blue)
                circle(CGPoint(x: size.width*0.5, y: size.height*0.15), min(size.width, size.height)*0.25, .cyan)
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Water Wave Background (for GameView)
struct WaterWaveBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.10), Color.cyan.opacity(0.08), Color.teal.opacity(0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let t = timeline.date.timeIntervalSinceReferenceDate

                    func wavePath(amplitude: CGFloat, wavelength: CGFloat, speed: Double, phase: Double, baseline: CGFloat) -> Path {
                        var path = Path()
                        let step: CGFloat = 2
                        path.move(to: CGPoint(x: 0, y: size.height))
                        path.addLine(to: CGPoint(x: 0, y: baseline))
                        var x: CGFloat = 0
                        while x <= size.width {
                            let angle = (Double(x) / Double(wavelength)) * 2.0 * Double.pi + (t * speed + phase)
                            let y = baseline + amplitude * CGFloat(sin(angle))
                            path.addLine(to: CGPoint(x: x, y: y))
                            x += step
                        }
                        path.addLine(to: CGPoint(x: size.width, y: size.height))
                        path.closeSubpath()
                        return path
                    }

                    let h = size.height
                    let w = size.width
                    let base = h * 0.75

                    let wave1 = wavePath(amplitude: h * 0.03, wavelength: max(w * 0.6, 200), speed: 0.6, phase: 0.0, baseline: base)
                    let wave2 = wavePath(amplitude: h * 0.04, wavelength: max(w * 0.5, 160), speed: 0.8, phase: .pi / 2, baseline: base + 8)
                    let wave3 = wavePath(amplitude: h * 0.02, wavelength: max(w * 0.7, 240), speed: 0.4, phase: .pi, baseline: base + 16)

                    context.fill(wave3, with: .linearGradient(Gradient(colors: [Color.blue.opacity(0.12), Color.cyan.opacity(0.10)]), startPoint: CGPoint(x: 0, y: base+16), endPoint: CGPoint(x: 0, y: h)))
                    context.fill(wave2, with: .linearGradient(Gradient(colors: [Color.cyan.opacity(0.12), Color.teal.opacity(0.10)]), startPoint: CGPoint(x: 0, y: base+8), endPoint: CGPoint(x: 0, y: h)))
                    context.fill(wave1, with: .linearGradient(Gradient(colors: [Color.blue.opacity(0.18), Color.cyan.opacity(0.14)]), startPoint: CGPoint(x: 0, y: base), endPoint: CGPoint(x: 0, y: h)))
                }
                .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let value: String
    let label: String
    let color: Color
    let icon: String
    
    var body: some View {
        ZStack {
            FacetedPanel(color: color)
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(8)
        }
        .frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: color.opacity(0.25), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Hero Card (image-friendly)
struct HeroCard: View {
    let imageName: String? // e.g., "home_hero"
    
    var body: some View {
        ZStack {
            if let name = imageName, let ui = UIImage(named: name) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .overlay(
                        LinearGradient(colors: [.black.opacity(0.0), .black.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                    )
                    .clipped()
            } else {
                LinearGradient(
                    colors: [.blue.opacity(0.8), .cyan.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    Image(systemName: "drop.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.9))
                )
            }
        }
        .frame(height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)
    }
}
// MARK: - Enhanced Menu Button
struct EnhancedMenuButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let delay: Double
    
    // 内部でタップを処理しない（NavigationLink に委ねる）
    
    var body: some View {
        FacetedMenuContent(icon: icon, title: title, subtitle: subtitle, color: color)
            .contentShape(Rectangle())
            .modifier(PressableTile())
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Faceted Menu Button internals
struct FacetedMenuContent: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        ZStack {
            FacetedPanel(color: color)
            HStack(spacing: 18) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 1)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.35), lineWidth: 1.2)
        )
        .shadow(color: color.opacity(0.35), radius: 12, x: 0, y: 6)
    }
}

struct FacetedPanel: View {
    let color: Color
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [
                        color.opacity(0.9),
                        color,
                        color.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.3),
                                .clear,
                                .black.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: color.opacity(0.45), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Press Feedback for Menu Tiles
private struct PressableTile: ViewModifier {
    @GestureState private var isPressed: Bool = false
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isPressed ? Color.white.opacity(0.5) : Color.clear, lineWidth: 2)
            )
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.01)
                    .updating($isPressed) { value, state, _ in
                        state = value
                    }
            )
    }
}

// Color mixing helper removed; consolidated in Models/ColorModels.swift

struct ContentView: View {
    @StateObject private var tutorialManager = TutorialManager.shared
    
    var body: some View {
        NavigationStack {
            HomeView()
        }
        .overlay(
            Group {
                if tutorialManager.isShowingTutorial {
                    TutorialView()
                        .transition(.opacity)
                }
            }
            // チュートリアル操作を有効化
            .allowsHitTesting(true)
        )
    }
}

struct HomeView: View {
    @EnvironmentObject private var progressStore: ProgressStore
    @StateObject private var storeKitManager = StoreKitManager()
    @State private var animationPhase: CGFloat = 0
    @State private var showingPaywall = false
    @State private var paywallError: String?
    @State private var pendingDifficulty: Difficulty? = nil
    private var difficultiesUnlocked: Bool { progressStore.isPurchased || progressStore.settings.debugUnlockDifficulties }
    
    var body: some View {
        ZStack {
            // 宝石調の背景
            JewelBackground()
            
            ScrollView {
            VStack(spacing: 20) {
                // ヘッダー
                VStack(spacing: 12) {
                    Text("JewelSort")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(
                            LinearGradient(colors: [.blue, .cyan, .teal], startPoint: .leading, endPoint: .trailing)
                        )
                        .shadow(color: .blue.opacity(0.2), radius: 4, x: 0, y: 1)
                    
                    Text("Sort the gems and solve the puzzle!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
                        )
                }
                
                // 統計情報カード（宝石っぽくしない、シンプルなデザイン）
                HStack(spacing: 16) {
                    VStack(spacing: 6) {
                        Text("\(progressStore.currentStreak)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Streak")
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                    
                    VStack(spacing: 6) {
                        Text("\(progressStore.bestBySeed.count)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Clears")
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                }
                .padding(.horizontal, 12)
                
                // 難易度選択（Hard/Expert は購入者のみ）
                VStack(spacing: 16) {
                    // Normal
                    NavigationLink(destination: GameView(difficulty: .normal, progressStore: progressStore)) {
                        EnhancedMenuButton(
                            icon: "play.circle.fill",
                            title: "Normal",
                            subtitle: "Colors 5 / Capacity 4 / Empty 2",
                            color: .blue,
                            delay: 0.0
                        )
                    }

                    // Hard
                    if difficultiesUnlocked {
                        NavigationLink(destination: GameView(difficulty: .hard, progressStore: progressStore)) {
                            EnhancedMenuButton(
                                icon: "flame.fill",
                                title: "Hard",
                                subtitle: "Colors 6 / Capacity 5 / Empty 1",
                                color: .orange,
                                delay: 0.1
                            )
                        }
                    } else {
                        Button {
                            pendingDifficulty = .hard
                            showingPaywall = true
                        } label: {
                            FacetedMenuContent(
                                icon: "lock.fill",
                                title: "Hard (Locked)",
                                subtitle: "Unlock with purchase: Colors 6 / Capacity 5",
                                color: .gray
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Expert
                    if difficultiesUnlocked {
                        NavigationLink(destination: GameView(difficulty: .expert, progressStore: progressStore)) {
                            EnhancedMenuButton(
                                icon: "bolt.fill",
                                title: "Expert",
                                subtitle: "Colors 7 / Capacity 5 / Empty 1",
                                color: .red,
                                delay: 0.2
                            )
                        }
                    } else {
                        Button {
                            pendingDifficulty = .expert
                            showingPaywall = true
                        } label: {
                            FacetedMenuContent(
                                icon: "lock.fill",
                                title: "Expert (Locked)",
                                subtitle: "Unlock with purchase: Colors 7 / Capacity 6",
                                color: .gray
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                
                Spacer()
                
                // フッター（設定）: 他のメニューと同じ幅・スタイルに統一
                VStack(spacing: 16) {
                    NavigationLink(destination: SettingsView()) {
                        EnhancedMenuButton(
                            icon: "gearshape.fill",
                            title: "Settings",
                            subtitle: "Change app settings",
                            color: .gray,
                            delay: 0.0
                        )
                    }
                }
                .padding(.horizontal, 12)
            }
            .padding(.top, 50)
            .padding(.vertical, 20)
            .padding(.bottom, 24)
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        // メニューの上下アニメーションは無効化（静止）
        .sheet(isPresented: $showingPaywall) {
            PaywallSheet(
                isPresented: $showingPaywall,
                progressStore: progressStore,
                storeKitManager: storeKitManager,
                pendingDifficulty: $pendingDifficulty
            )
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - Paywall Sheet
struct PaywallSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject var progressStore: ProgressStore
    @ObservedObject var storeKitManager: StoreKitManager
    @Binding var pendingDifficulty: Difficulty?
    @State private var purchasing = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "lock.circle.fill").font(.system(size: 48)).foregroundColor(.blue)
                Text("Unlock Hard/Expert")
                    .font(.title2).fontWeight(.bold)
                Text("Access more challenging puzzles.")
                    .foregroundColor(.secondary)
                
                if let err = errorMessage {
                    Text(err).foregroundColor(.red)
                }
                
                // Purchase button with locale-based price label
                let isJapanese = Locale.preferredLanguages.first?.hasPrefix("ja") == true
                let priceLabel = isJapanese ? "¥300で購入" : "Buy for $1.99"
                Button {
                    Task { await purchase() }
                } label: {
                    Text(storeKitManager.products.first(where: { $0.id == "pro.unlock" })?.displayPrice ?? priceLabel)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(purchasing)
                
                Button("Restore Purchases") {
                    Task { await restore() }
                }
                .foregroundColor(.blue)
                
                // Legal links
                HStack(spacing: 16) {
                    let termsURL = URL(string: "https://nekomura0728.github.io/jewelsort/terms")!
                    let privacyURL = URL(string: "https://nekomura0728.github.io/jewelsort/privacy")!
                    let termsText = isJapanese ? "利用規約" : "Terms of Service"
                    let privacyText = isJapanese ? "プライバシーポリシー" : "Privacy Policy"
                    Link(termsText, destination: termsURL)
                    Text("·").foregroundColor(.secondary)
                    Link(privacyText, destination: privacyURL)
                }
                .font(.footnote)
                .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Close") { isPresented = false } } }
            .onAppear { Task { await storeKitManager.loadProducts() } }
        }
    }
    
    private func purchaseCompleted() {
        progressStore.isPurchased = storeKitManager.isPurchased
        progressStore.saveProgress()
        isPresented = false
    }
    
    private func navigateIfNeeded() {
        // NavigationLink はボタン単位にあるため、閉じるだけで再タップで遷移可能
    }
    
    private func purchase() async {
        purchasing = true
        defer { purchasing = false }
        guard let product = storeKitManager.products.first(where: { $0.id == "pro.unlock" }) else {
            errorMessage = "Product not found"
            return
        }
        do {
            _ = try await storeKitManager.purchase(product)
            purchaseCompleted()
            navigateIfNeeded()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func restore() async {
        do {
            try await storeKitManager.restorePurchases()
            purchaseCompleted()
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
    }
}
