import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var progressStore: ProgressStore
    @StateObject private var storeKitManager = StoreKitManager()
    @Environment(\.dismiss) private var dismiss
    @State private var showingPurchaseAlert = false
    @State private var purchaseError: String?
    
    var body: some View {
        NavigationView {
            List {
                Section("Game Settings") {
                    HStack {
                        Text("Default Difficulty")
                        Spacer()
                        Picker("難易度", selection: $progressStore.settings.defaultDifficulty) {
                            ForEach(allowedDifficulties, id: \.self) { difficulty in
                                Text(difficulty.displayName).tag(difficulty)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    HStack {
                        Text("Animation Speed")
                        Spacer()
                        Picker("速度", selection: $progressStore.settings.animationSpeed) {
                            ForEach(GameSettings.AnimationSpeed.allCases, id: \.self) { speed in
                                Text(speed.displayName).tag(speed)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }

#if DEBUG
                developerSection
#endif
                
                // 未実装項目は削除（アクセシビリティ/サウンド）
                
                Section("Stats") {
                    HStack {
                        Text("Current Streak")
                        Spacer()
                        Text("\(progressStore.currentStreak)")
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("Levels Cleared")
                        Spacer()
                        Text("\(progressStore.bestBySeed.count)")
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                
                // プレミアム案内はペイウォールに集約（設定からは削除）
                
                // Tutorial removed from UX; hide restart entry
                
                Section("Other") {
                    HStack {
                        Text("Premium")
                        Spacer()
                        Text(progressStore.isPurchased ? "Unlocked" : "Not Purchased")
                            .foregroundColor(progressStore.isPurchased ? .green : .secondary)
                    }
                    
                    Button("Restore Purchases") {
                        Task {
                            await restorePurchases()
                        }
                    }
                    .foregroundColor(.blue)
                    
                    Button("Reset Data") {
                        // TODO: データリセット処理を実装
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .onChange(of: progressStore.settings.defaultDifficulty) { _, _ in
            progressStore.saveProgress()
        }
        .onChange(of: progressStore.settings.animationSpeed) { _, _ in
            progressStore.saveProgress()
        }
        .onAppear { clampDefaultDifficulty() }
        .onChange(of: progressStore.isPurchased) { _, _ in clampDefaultDifficulty() }
        .onChange(of: progressStore.settings.debugUnlockDifficulties) { _, _ in clampDefaultDifficulty() }
        .alert("Purchase Error", isPresented: $showingPurchaseAlert) {
            Button("OK") { }
        } message: {
            Text(purchaseError ?? "Unknown error occurred")
        }
    }
    
    // MARK: - Purchase Methods
    
    private func purchaseProVersion() async {
        guard let product = storeKitManager.products.first(where: { $0.id == "pro.unlock" }) else {
            purchaseError = "商品が見つかりません"
            showingPurchaseAlert = true
            return
        }
        
        do {
            if try await storeKitManager.purchase(product) != nil {
                // 購入成功
                progressStore.isPurchased = true
                progressStore.saveProgress()
            }
        } catch {
            purchaseError = error.localizedDescription
            showingPurchaseAlert = true
        }
    }
    
    private func restorePurchases() async {
        do {
            try await storeKitManager.restorePurchases()
            if storeKitManager.isPurchased {
                progressStore.isPurchased = true
                progressStore.saveProgress()
            }
        } catch {
            purchaseError = "購入の復元に失敗しました: \(error.localizedDescription)"
            showingPurchaseAlert = true
        }
    }
}

#Preview {
    SettingsView()
}

// MARK: - Helpers (Difficulty Gate)
private extension SettingsView {
    var allowedDifficulties: [Difficulty] {
        (progressStore.isPurchased || progressStore.settings.debugUnlockDifficulties) ? Difficulty.allCases : [.normal]
    }
    func clampDefaultDifficulty() {
        if !(progressStore.isPurchased || progressStore.settings.debugUnlockDifficulties) {
            progressStore.settings.defaultDifficulty = .normal
        }
    }
}

// MARK: - Developer Section (DEBUG only)
#if DEBUG
extension SettingsView {
    @ViewBuilder
    var developerSection: some View {
        Section("Developer Options") {
            Toggle("Debug: Unlock Difficulties", isOn: $progressStore.settings.debugUnlockDifficulties)
                .onChange(of: progressStore.settings.debugUnlockDifficulties) { _, _ in
                    progressStore.saveProgress()
                }
            Text("Disabled in release. Use to test Hard/Expert without purchase.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
#endif
