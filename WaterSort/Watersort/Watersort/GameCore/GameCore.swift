import Foundation

class GameCore: ObservableObject {
    @Published var gameState: GameState
    @Published var selectedTubeIndex: Int?
    @Published var canUndo: Bool = false
    @Published var canHint: Bool = true
    
    private var config: LevelConfig
    private let progressStore: ProgressStore
    private var undoUsedInLevel: Int = 0

    // 現在の難易度（表示用）
    var difficulty: Difficulty { config.difficulty }
    
    init(config: LevelConfig, progressStore: ProgressStore) {
        self.config = config
        self.progressStore = progressStore
        self.gameState = GameState(tubes: Self.generateLevel(config: config), capacity: config.capacity)
    }
    
    // MARK: - Game Logic
    
    func selectTube(_ index: Int) {
        if selectedTubeIndex == nil {
            // 最初の選択
            if !gameState.tubes[index].isEmpty {
                selectedTubeIndex = index
            }
        } else if selectedTubeIndex == index {
            // 同じチューブを再度選択
            selectedTubeIndex = nil
        } else {
            // 移動を試行
            if canMove(from: selectedTubeIndex!, to: index) {
                performMove(from: selectedTubeIndex!, to: index)
            }
            selectedTubeIndex = nil
        }
    }
    
    func canMove(from sourceIndex: Int, to destinationIndex: Int) -> Bool {
        guard sourceIndex < gameState.tubes.count,
              destinationIndex < gameState.tubes.count,
              !gameState.tubes[sourceIndex].isEmpty,
              gameState.tubes[destinationIndex].count < config.capacity else {
            return false
        }
        
        let sourceTube = gameState.tubes[sourceIndex]
        let destinationTube = gameState.tubes[destinationIndex]
        // 目的地が空 or 目的地のトップが同色なら、部分注ぎでも可
        if destinationTube.isEmpty { return true }
        let sourceTopColor = sourceTube.last!
        let destinationTopColor = destinationTube.last!
        return sourceTopColor == destinationTopColor
    }
    
    func canPour(from sourceIndex: Int, to destinationIndex: Int) -> Bool {
        return canMove(from: sourceIndex, to: destinationIndex)
    }
    
    func pour(from sourceIndex: Int, to destinationIndex: Int) {
        if canPour(from: sourceIndex, to: destinationIndex) {
            performMove(from: sourceIndex, to: destinationIndex)
        }
    }
    
    private func getMovableAmount(from sourceIndex: Int) -> Int {
        let sourceTube = gameState.tubes[sourceIndex]
        guard !sourceTube.isEmpty else { return 0 }
        
        let topColor = sourceTube.last!
        var count = 0
        
        // 上から連続する同じ色の数をカウント
        for i in (0..<sourceTube.count).reversed() {
            if sourceTube[i] == topColor {
                count += 1
            } else {
                break
            }
        }
        
        return count
    }
    
    private func performMove(from sourceIndex: Int, to destinationIndex: Int) {
        let movableAmount = getMovableAmount(from: sourceIndex)
        let sourceTube = gameState.tubes[sourceIndex]
        let topColor = sourceTube.last!
        // 部分注ぎ：空き容量に応じて実際に注ぐ量を決定
        let availableSpace = config.capacity - gameState.tubes[destinationIndex].count
        let pourAmount = max(0, min(movableAmount, availableSpace))
        guard pourAmount > 0 else { return }
        
        // 移動を記録
        let move = Move(sourceIndex: sourceIndex,
                        destinationIndex: destinationIndex,
                        amount: pourAmount,
                        color: topColor)
        
        // 状態を更新
        gameState.moves.append(move)
        gameState.undoStack.removeAll() // 新しい移動でアンドゥスタックをクリア
        
        // チューブの内容を更新
        let newSourceTube = Array(sourceTube.dropLast(pourAmount))
        let newDestinationTube = gameState.tubes[destinationIndex] + Array(repeating: topColor, count: pourAmount)
        
        gameState.tubes[sourceIndex] = newSourceTube
        gameState.tubes[destinationIndex] = newDestinationTube
        
        // アンドゥ可能かチェック（購入済み or 残り3回まで）
        canUndo = gameState.moves.count > 0 && (progressStore.isPurchased || undoUsedInLevel < 3)
        
        // 勝利チェック
        if gameState.isWon {
            handleWin()
        }
    }
    
    func undo() {
        guard canUndo, let lastMove = gameState.moves.last else { return }
        
        // 移動を元に戻す
        let sourceTube = gameState.tubes[lastMove.sourceIndex]
        let destinationTube = gameState.tubes[lastMove.destinationIndex]
        
        // 移動先から色を削除
        let newDestinationTube = Array(destinationTube.dropLast(lastMove.amount))
        
        // 移動元に色を戻す
        let newSourceTube = sourceTube + Array(repeating: lastMove.color, count: lastMove.amount)
        
        gameState.tubes[lastMove.sourceIndex] = newSourceTube
        gameState.tubes[lastMove.destinationIndex] = newDestinationTube
        
        // 移動履歴を更新
        gameState.moves.removeLast()
        gameState.undoStack.append(lastMove)
        
        // アンドゥ使用回数を更新（購入済みは無制限）
        if !progressStore.isPurchased { undoUsedInLevel += 1 }
        // アンドゥ可能かチェック
        canUndo = gameState.moves.count > 0 && (progressStore.isPurchased || undoUsedInLevel < 3)
    }
    
    func getHint() -> (from: Int, to: Int)? {
        guard canHint else { return nil }
        
        let hintSystem = AdvancedHintSystem()
        let result = hintSystem.findSolution(for: gameState.tubes, config: config, timeLimit: 0.1)
        
        if let firstMove = result.moves.first {
            // ヒントを使用（購入済みは無制限）
            if !progressStore.isPurchased { canHint = false }
            return (from: firstMove.sourceIndex, to: firstMove.destinationIndex)
        }
        
        return nil
    }
    
    func restart() {
        gameState = GameState(tubes: Self.generateLevel(config: config), capacity: config.capacity)
        selectedTubeIndex = nil
        canUndo = false
        canHint = true
        undoUsedInLevel = 0
        // リスタートで連勝をリセット
        progressStore.resetStreak()
    }
    
    func nextLevel() {
        // 現在のレベルをクリア済みとしてマーク
        progressStore.markLevelAsCompleted(seed: config.seed)
        
        let newSeed = config.seed + 1
        let newConfig = LevelConfig(seed: newSeed, 
                                  colors: config.colors, 
                                  capacity: config.capacity, 
                                  extraEmpty: config.extraEmpty, 
                                  difficulty: config.difficulty)
        
        // 新しいレベルを生成
        gameState = GameState(tubes: Self.generateLevel(config: newConfig), capacity: newConfig.capacity)
        selectedTubeIndex = nil
        canUndo = false
        canHint = true
        undoUsedInLevel = 0
        
        // 設定を更新
        config = newConfig
    }
    
    private func handleWin() {
        let moves = gameState.currentMoves
        let time = gameState.currentTime
        
        // ベスト記録を更新
        progressStore.updateBest(seed: config.seed, moves: moves, time: time)
        
        // ストリークを更新
        progressStore.incrementStreak()
    }
    
    // MARK: - Level Generation
    
    static func generateLevel(config: LevelConfig) -> [[Int]] {
        var attempts = 0
        let maxAttempts = 10
        
        while attempts < maxAttempts {
            let tubes = generateRandomLevel(config: config)
            if isSolvable(tubes: tubes, config: config) {
                return tubes
            }
            attempts += 1
        }
        
        // 最大試行回数に達した場合は、基本的な解決可能なレベルを返す
        return generateBasicSolvableLevel(config: config)
    }
    
    private static func generateRandomLevel(config: LevelConfig) -> [[Int]] {
        var rng = SeededRandomNumberGenerator(seed: UInt64(config.seed))
        
        // 各色をcapacity回ずつ作成
        var allColors: [Int] = []
        for color in 0..<config.colors {
            allColors += Array(repeating: color, count: config.capacity)
        }
        
        // シャッフル
        allColors.shuffle(using: &rng)
        
        // チューブに分配
        var tubes: [[Int]] = []
        let colorsPerTube = config.capacity
        
        for i in 0..<config.colors {
            let startIndex = i * colorsPerTube
            let endIndex = startIndex + colorsPerTube
            let tubeColors = Array(allColors[startIndex..<endIndex])
            tubes.append(tubeColors)
        }
        
        // 空のチューブを追加
        for _ in 0..<config.extraEmpty {
            tubes.append([])
        }
        
        return tubes
    }
    
    private static func generateBasicSolvableLevel(config: LevelConfig) -> [[Int]] {
        // 基本的な解決可能なレベル（各色が既に整列されている）
        var tubes: [[Int]] = []
        
        for color in 0..<config.colors {
            tubes.append(Array(repeating: color, count: config.capacity))
        }
        
        // 空のチューブを追加
        for _ in 0..<config.extraEmpty {
            tubes.append([])
        }
        
        return tubes
    }
    
    private static func isSolvable(tubes: [[Int]], config: LevelConfig) -> Bool {
        // 簡単な解決可能性チェック
        // 1. 各色が正確に4回出現するかチェック
        var colorCounts: [Int: Int] = [:]
        for tube in tubes {
            for color in tube {
                colorCounts[color, default: 0] += 1
            }
        }
        
        // 各色が正確にcapacity回出現するかチェック
        for color in 0..<config.colors {
            if colorCounts[color, default: 0] != config.capacity {
                return false
            }
        }
        
        // 2. 既に解決済みでないかチェック
        if isAlreadySolved(tubes: tubes, capacity: config.capacity) {
            return false
        }
        
        // 3. 基本的な移動可能性チェック
        return hasValidMoves(tubes: tubes, config: config)
    }
    
    private static func isAlreadySolved(tubes: [[Int]], capacity: Int) -> Bool {
        return tubes.allSatisfy { tube in
            tube.isEmpty || (tube.count == capacity && tube.allSatisfy { $0 == tube.first })
        }
    }
    
    private static func hasValidMoves(tubes: [[Int]], config: LevelConfig) -> Bool {
        for sourceIndex in 0..<tubes.count {
            let sourceTube = tubes[sourceIndex]
            if sourceTube.isEmpty { continue }
            
            let topColor = sourceTube.last!
            _ = getMovableAmount(from: sourceTube, topColor: topColor)
            
            for destIndex in 0..<tubes.count {
                if sourceIndex == destIndex { continue }
                
                let destTube = tubes[destIndex]
                if destTube.count >= config.capacity { continue }
                
                // 移動先が空、または同じ色の場合
                if destTube.isEmpty || destTube.last == topColor {
                    return true
                }
            }
        }
        return false
    }
    
    private static func getMovableAmount(from tube: [Int], topColor: Int) -> Int {
        var count = 0
        for i in (0..<tube.count).reversed() {
            if tube[i] == topColor {
                count += 1
            } else {
                break
            }
        }
        return count
    }
}

// MARK: - Seeded Random Number Generator

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed
    }
    
    mutating func next() -> UInt64 {
        state = state &* 2862933555777941757 &+ 3037000493
        return state
    }
}
