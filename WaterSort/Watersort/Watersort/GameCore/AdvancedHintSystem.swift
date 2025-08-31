import Foundation

// MARK: - Advanced Hint System
class AdvancedHintSystem {
    
    // MARK: - Solver Types
    
    enum SolverType {
        case iddfs
        case astar
    }
    
    struct SolverResult {
        let moves: [Move]
        let isComplete: Bool
        let searchTime: TimeInterval
    }
    
    // MARK: - Main Solver
    
    func findSolution(for tubes: [[Int]], config: LevelConfig, timeLimit: TimeInterval = 0.1) -> SolverResult {
        let startTime = Date()
        
        // まずIDDFSで試行
        if let result = solveWithIDDFS(tubes: tubes, config: config, timeLimit: timeLimit) {
            return SolverResult(
                moves: result,
                isComplete: true,
                searchTime: Date().timeIntervalSince(startTime)
            )
        }
        
        // IDDFSで解決できない場合は、ヒント用の部分解を探す
        if let hint = findHintMove(tubes: tubes, config: config) {
            return SolverResult(
                moves: [hint],
                isComplete: false,
                searchTime: Date().timeIntervalSince(startTime)
            )
        }
        
        // フォールバック：任意の有効な移動
        if let fallback = findAnyValidMove(tubes: tubes, config: config) {
            return SolverResult(
                moves: [fallback],
                isComplete: false,
                searchTime: Date().timeIntervalSince(startTime)
            )
        }
        
        return SolverResult(moves: [], isComplete: false, searchTime: Date().timeIntervalSince(startTime))
    }
    
    // MARK: - IDDFS Solver
    
    private func solveWithIDDFS(tubes: [[Int]], config: LevelConfig, timeLimit: TimeInterval) -> [Move]? {
        let startTime = Date()
        var maxDepth = 1
        
        while Date().timeIntervalSince(startTime) < timeLimit {
            if let solution = searchWithDepth(tubes: tubes, config: config, maxDepth: maxDepth, startTime: startTime, timeLimit: timeLimit) {
                return solution
            }
            maxDepth += 1
        }
        
        return nil
    }
    
    private func searchWithDepth(tubes: [[Int]], config: LevelConfig, maxDepth: Int, startTime: Date, timeLimit: TimeInterval) -> [Move]? {
        var visited = Set<String>()
        return dfs(tubes: tubes, config: config, depth: 0, maxDepth: maxDepth, visited: &visited, startTime: startTime, timeLimit: timeLimit)
    }
    
    private func dfs(tubes: [[Int]], config: LevelConfig, depth: Int, maxDepth: Int, visited: inout Set<String>, startTime: Date, timeLimit: TimeInterval) -> [Move]? {
        // 時間制限チェック
        if Date().timeIntervalSince(startTime) > timeLimit {
            return nil
        }
        
        // 勝利チェック
        if isWon(tubes: tubes, capacity: config.capacity) {
            return []
        }
        
        // 深さ制限チェック
        if depth >= maxDepth {
            return nil
        }
        
        // 状態のハッシュ化
        let stateHash = hashState(tubes)
        if visited.contains(stateHash) {
            return nil
        }
        visited.insert(stateHash)
        
        // 有効な移動を試行
        for sourceIndex in 0..<tubes.count {
            for destIndex in 0..<tubes.count {
                if sourceIndex == destIndex { continue }
                
                if canMove(from: sourceIndex, to: destIndex, tubes: tubes, config: config) {
                    let newTubes = performMove(from: sourceIndex, to: destIndex, tubes: tubes, config: config)
                    let move = Move(sourceIndex: sourceIndex, destinationIndex: destIndex, amount: 1, color: tubes[sourceIndex].last!)
                    
                    if let remainingMoves = dfs(tubes: newTubes, config: config, depth: depth + 1, maxDepth: maxDepth, visited: &visited, startTime: startTime, timeLimit: timeLimit) {
                        return [move] + remainingMoves
                    }
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Hint Finding
    
    private func findHintMove(tubes: [[Int]], config: LevelConfig) -> Move? {
        // 最も良い移動を見つける（ヒューリスティックベース）
        var bestMove: Move?
        var bestScore = Int.min
        
        for sourceIndex in 0..<tubes.count {
            for destIndex in 0..<tubes.count {
                if sourceIndex == destIndex { continue }
                
                if canMove(from: sourceIndex, to: destIndex, tubes: tubes, config: config) {
                    let score = evaluateMove(from: sourceIndex, to: destIndex, tubes: tubes, config: config)
                    if score > bestScore {
                        bestScore = score
                        let move = Move(sourceIndex: sourceIndex, destinationIndex: destIndex, amount: 1, color: tubes[sourceIndex].last!)
                        bestMove = move
                    }
                }
            }
        }
        
        return bestMove
    }
    
    private func findAnyValidMove(tubes: [[Int]], config: LevelConfig) -> Move? {
        for sourceIndex in 0..<tubes.count {
            for destIndex in 0..<tubes.count {
                if sourceIndex == destIndex { continue }
                
                if canMove(from: sourceIndex, to: destIndex, tubes: tubes, config: config) {
                    return Move(sourceIndex: sourceIndex, destinationIndex: destIndex, amount: 1, color: tubes[sourceIndex].last!)
                }
            }
        }
        return nil
    }
    
    // MARK: - Helper Methods
    
    private func canMove(from sourceIndex: Int, to destIndex: Int, tubes: [[Int]], config: LevelConfig) -> Bool {
        guard sourceIndex < tubes.count,
              destIndex < tubes.count,
              !tubes[sourceIndex].isEmpty,
              tubes[destIndex].count < config.capacity else {
            return false
        }
        
        let sourceTube = tubes[sourceIndex]
        let destTube = tubes[destIndex]
        let topColor = sourceTube.last!
        
        return destTube.isEmpty || destTube.last == topColor
    }
    
    private func performMove(from sourceIndex: Int, to destIndex: Int, tubes: [[Int]], config: LevelConfig) -> [[Int]] {
        var newTubes = tubes
        let topColor = newTubes[sourceIndex].removeLast()
        newTubes[destIndex].append(topColor)
        return newTubes
    }
    
    private func isWon(tubes: [[Int]], capacity: Int) -> Bool {
        return tubes.allSatisfy { tube in
            tube.isEmpty || (tube.count == capacity && tube.allSatisfy { $0 == tube.first })
        }
    }
    
    private func hashState(_ tubes: [[Int]]) -> String {
        return tubes.map { tube in
            tube.map(String.init).joined(separator: ",")
        }.joined(separator: "|")
    }
    
    private func evaluateMove(from sourceIndex: Int, to destIndex: Int, tubes: [[Int]], config: LevelConfig) -> Int {
        var score = 0
        let sourceTube = tubes[sourceIndex]
        let destTube = tubes[destIndex]
        let topColor = sourceTube.last!
        
        // 移動先が空の場合のボーナス
        if destTube.isEmpty {
            score += 10
        }
        
        // 同じ色への移動のボーナス
        if destTube.last == topColor {
            score += 20
            
            // 完全に埋まる場合の追加ボーナス
            if destTube.count + 1 == config.capacity {
                score += 50
            }
        }
        
        // 移動元が空になる場合のボーナス
        if sourceTube.count == 1 {
            score += 15
        }
        
        // 移動元の色が統一される場合のボーナス
        if sourceTube.count > 1 {
            let remainingColors = Array(sourceTube.dropLast())
            if !remainingColors.isEmpty && remainingColors.allSatisfy({ $0 == remainingColors.first }) {
                score += 30
            }
        }
        
        return score
    }
}

// MARK: - Hint Models
struct HintStep {
    let step: Int
    let from: Int
    let to: Int
    let reason: String
}

struct HintAnalysis {
    let difficulty: Difficulty
    let estimatedMoves: Int
    let strategicTips: [String]
    let commonMistakes: [String]
}
