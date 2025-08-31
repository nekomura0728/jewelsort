import Foundation

// MARK: - Level Configuration
struct LevelConfig: Codable {
    let seed: Int
    let colors: Int
    let tubes: Int
    let capacity: Int
    let extraEmpty: Int
    let difficulty: Difficulty
    
    init(seed: Int, colors: Int, capacity: Int = 4, extraEmpty: Int = 2, difficulty: Difficulty = .normal) {
        self.seed = seed
        self.colors = colors
        self.capacity = capacity
        self.extraEmpty = extraEmpty
        self.difficulty = difficulty
        self.tubes = colors + extraEmpty
    }
}

enum Difficulty: String, CaseIterable, Codable {
    case normal = "normal"
    case hard = "hard"
    case expert = "expert"
    
    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .hard: return "Hard"
        case .expert: return "Expert"
        }
    }
}

// MARK: - Game State
struct GameState: Codable {
    var tubes: [[Int]]
    var moves: [Move]
    var undoStack: [Move]
    var startTime: Date
    var bestMoves: Int?
    var bestTime: TimeInterval?
    // 勝利判定やUI表示のための容量（デフォルト4）。
    var capacity: Int
    
    init(tubes: [[Int]], capacity: Int = 4, startTime: Date = Date()) {
        self.tubes = tubes
        self.moves = []
        self.undoStack = []
        self.startTime = startTime
        self.bestMoves = nil
        self.bestTime = nil
        self.capacity = capacity
    }
    
    var isWon: Bool {
        tubes.allSatisfy { tube in
            tube.isEmpty || (tube.count == capacity && tube.allSatisfy { $0 == tube.first })
        }
    }
    
    var currentMoves: Int {
        moves.count
    }
    
    var currentTime: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
    
    // Codable（capacity 未保存データとの後方互換）
    private enum CodingKeys: String, CodingKey { case tubes, moves, undoStack, startTime, bestMoves, bestTime, capacity }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tubes = try container.decode([[Int]].self, forKey: .tubes)
        moves = (try? container.decode([Move].self, forKey: .moves)) ?? []
        undoStack = (try? container.decode([Move].self, forKey: .undoStack)) ?? []
        startTime = (try? container.decode(Date.self, forKey: .startTime)) ?? Date()
        bestMoves = try? container.decode(Int.self, forKey: .bestMoves)
        bestTime = try? container.decode(TimeInterval.self, forKey: .bestTime)
        capacity = (try? container.decode(Int.self, forKey: .capacity)) ?? 4
    }
}

// MARK: - Move
struct Move: Codable {
    let sourceIndex: Int
    let destinationIndex: Int
    let amount: Int
    let color: Int
    
    init(sourceIndex: Int, destinationIndex: Int, amount: Int, color: Int) {
        self.sourceIndex = sourceIndex
        self.destinationIndex = destinationIndex
        self.amount = amount
        self.color = color
    }
}

// MARK: - Best Record
struct BestRecord: Codable {
    let moves: Int
    let time: TimeInterval
}

// MARK: - Custom Level
struct CustomLevel: Codable, Identifiable {
    let id: UUID
    let name: String
    let config: LevelConfig
    let tubes: [[Int]]
    let createdAt: Date
}

// MARK: - Progress Store
class ProgressStore: ObservableObject {
    @Published var bestBySeed: [Int: BestRecord] = [:]
    @Published var currentStreak: Int = 0
    @Published var settings: GameSettings = GameSettings()
    @Published var isPurchased: Bool = false
    @Published var customLevels: [CustomLevel] = []
    
    private let userDefaults = UserDefaults.standard
    private let bestBySeedKey = "bestBySeed"
    private let currentStreakKey = "currentStreak"
    private let settingsKey = "gameSettings"
    private let purchasedKey = "isPurchased"
    private let customLevelsKey = "customLevels"
    
    init() {
        loadProgress()
    }
    
    func saveProgress() {
        if let data = try? JSONEncoder().encode(bestBySeed) {
            userDefaults.set(data, forKey: bestBySeedKey)
        }
        userDefaults.set(currentStreak, forKey: currentStreakKey)
        if let data = try? JSONEncoder().encode(settings) {
            userDefaults.set(data, forKey: settingsKey)
        }
        userDefaults.set(isPurchased, forKey: purchasedKey)
        if let data = try? JSONEncoder().encode(customLevels) {
            userDefaults.set(data, forKey: customLevelsKey)
        }
    }
    
    private func loadProgress() {
        if let data = userDefaults.data(forKey: bestBySeedKey),
           let best = try? JSONDecoder().decode([Int: BestRecord].self, from: data) {
            bestBySeed = best
        }
        currentStreak = userDefaults.integer(forKey: currentStreakKey)
        if let data = userDefaults.data(forKey: settingsKey),
           let settings = try? JSONDecoder().decode(GameSettings.self, from: data) {
            self.settings = settings
        }
        isPurchased = userDefaults.bool(forKey: purchasedKey)
        if let data = userDefaults.data(forKey: customLevelsKey),
           let levels = try? JSONDecoder().decode([CustomLevel].self, from: data) {
            self.customLevels = levels
        }
    }
    
    func updateBest(seed: Int, moves: Int, time: TimeInterval) {
        let current = bestBySeed[seed]
        if current == nil || moves < current!.moves || (moves == current!.moves && time < current!.time) {
            bestBySeed[seed] = BestRecord(moves: moves, time: time)
            saveProgress()
        }
    }
    
    func incrementStreak() {
        currentStreak += 1
        saveProgress()
    }
    
    func resetStreak() {
        currentStreak = 0
        saveProgress()
    }
    
    func markLevelAsCompleted(seed: Int) {
        // レベルをクリア済みとしてマーク
        if bestBySeed[seed] == nil {
            // 初回クリアの場合は基本的な記録を作成
            bestBySeed[seed] = BestRecord(moves: 0, time: 0)
        }
        saveProgress()
    }

    // MARK: - Custom Levels
    func saveCustomLevel(config: LevelConfig, tubes: [[Int]], name: String) {
        let item = CustomLevel(id: UUID(), name: name, config: config, tubes: tubes, createdAt: Date())
        customLevels.append(item)
        saveProgress()
    }

    func saveCustomLevel(config: LevelConfig, tubes: [[Int]]) {
        let defaultName = "Custom-\(config.seed)"
        saveCustomLevel(config: config, tubes: tubes, name: defaultName)
    }
}

// MARK: - Game Settings
struct GameSettings: Codable {
    var defaultDifficulty: Difficulty = .normal
    var colorblindMode: Bool = false
    var animationSpeed: AnimationSpeed = .normal
    var soundEnabled: Bool = true
    // デバッグ用: 難易度ロック解除（開発ビルドの設定画面から切替）
    var debugUnlockDifficulties: Bool = false
    
    enum AnimationSpeed: String, CaseIterable, Codable {
        case slow = "slow"
        case normal = "normal"
        case fast = "fast"
        
        var displayName: String {
            switch self {
            case .slow: return "Slow"
            case .normal: return "Normal"
            case .fast: return "Fast"
            }
        }
        
        var duration: Double {
            switch self {
            case .slow: return 0.5
            case .normal: return 0.3
            case .fast: return 0.15
            }
        }
    }
}
