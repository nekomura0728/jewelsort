//
//  WatersortTests.swift
//  WatersortTests
//
//  Created by 前村　真之介 on 2025/08/28.
//

import Testing
@testable import Watersort

struct WatersortTests {
    
    // MARK: - GameCore Tests
    
    @Test func test_GameCore_Initialization() async throws {
        let config = LevelConfig(seed: 1, colors: 5, capacity: 4, extraEmpty: 2, difficulty: .normal)
        let progressStore = ProgressStore()
        let gameCore = GameCore(config: config, progressStore: progressStore)
        
        #expect(gameCore.gameState.tubes.count == 7) // 5 colors + 2 empty
        #expect(gameCore.gameState.tubes[0].count == 4) // Each color tube should have 4 colors
        #expect(gameCore.canUndo == false)
        #expect(gameCore.canHint == true)
    }
    
    @Test func test_GameCore_ValidMove() async throws {
        let config = LevelConfig(seed: 1, colors: 3, capacity: 4, extraEmpty: 1, difficulty: .normal)
        let progressStore = ProgressStore()
        let gameCore = GameCore(config: config, progressStore: progressStore)
        
        // 最初のチューブを選択
        gameCore.selectTube(0)
        #expect(gameCore.selectedTubeIndex == 0)
        
        // 空のチューブに移動
        gameCore.selectTube(3) // 空のチューブ
        #expect(gameCore.selectedTubeIndex == nil)
        #expect(gameCore.gameState.tubes[3].count == 1) // 移動された
    }
    
    @Test func test_GameCore_InvalidMove() async throws {
        let config = LevelConfig(seed: 1, colors: 3, capacity: 4, extraEmpty: 1, difficulty: .normal)
        let progressStore = ProgressStore()
        let gameCore = GameCore(config: config, progressStore: progressStore)
        
        // 空のチューブから移動しようとする
        gameCore.selectTube(3) // 空のチューブ
        #expect(gameCore.selectedTubeIndex == nil)
        
        // 満杯のチューブに移動しようとする
        gameCore.selectTube(0)
        gameCore.selectTube(1) // 満杯のチューブ
        #expect(gameCore.selectedTubeIndex == 0) // 選択状態のまま
    }
    
    @Test func test_GameCore_Undo() async throws {
        let config = LevelConfig(seed: 1, colors: 3, capacity: 4, extraEmpty: 1, difficulty: .normal)
        let progressStore = ProgressStore()
        let gameCore = GameCore(config: config, progressStore: progressStore)
        
        // 有効な移動を実行
        let beforeMove = gameCore.gameState.tubes
        gameCore.selectTube(0)
        gameCore.selectTube(3)
        
        // アンドゥを実行
        gameCore.undo()
        #expect(gameCore.gameState.tubes == beforeMove)
    }
    
    @Test func test_GameCore_Hint() async throws {
        let config = LevelConfig(seed: 1, colors: 3, capacity: 4, extraEmpty: 1, difficulty: .normal)
        let progressStore = ProgressStore()
        let gameCore = GameCore(config: config, progressStore: progressStore)
        
        let hint = gameCore.getHint()
        #expect(hint != nil)
        #expect(gameCore.canHint == false) // ヒントを使用済み
    }
    
    // MARK: - Level Generation Tests
    
    @Test func test_LevelGeneration_ValidConfig() async throws {
        let config = LevelConfig(seed: 1, colors: 5, capacity: 4, extraEmpty: 2, difficulty: .normal)
        let tubes = GameCore.generateLevel(config: config)
        
        #expect(tubes.count == 7) // 5 colors + 2 empty
        #expect(tubes[0].count == 4) // Each color tube should have 4 colors
        #expect(tubes[5].isEmpty) // Empty tubes should be empty
        #expect(tubes[6].isEmpty)
    }
    
    @Test func test_LevelGeneration_DifferentSeeds() async throws {
        let config1 = LevelConfig(seed: 1, colors: 3, capacity: 4, extraEmpty: 1, difficulty: .normal)
        let config2 = LevelConfig(seed: 2, colors: 3, capacity: 4, extraEmpty: 1, difficulty: .normal)
        
        let tubes1 = GameCore.generateLevel(config: config1)
        let tubes2 = GameCore.generateLevel(config: config2)
        
        // 異なるシードでは異なる配置になるはず
        #expect(tubes1 != tubes2)
    }
    
    // MARK: - Game Models Tests
    
    @Test func test_GameState_Initialization() async throws {
        let tubes = [[0, 1, 2, 3], [4, 5, 6, 7], []]
        let gameState = GameState(tubes: tubes, capacity: 4)
        
        #expect(gameState.tubes.count == 3)
        #expect(gameState.moves.isEmpty)
        #expect(gameState.undoStack.isEmpty)
        #expect(gameState.isWon == false)
    }
    
    @Test func test_GameState_WinCondition() async throws {
        let tubes = [[0, 0, 0, 0], [1, 1, 1, 1], []]
        let gameState = GameState(tubes: tubes, capacity: 4)
        
        #expect(gameState.isWon == true)
    }
    
    @Test func test_LevelConfig_Initialization() async throws {
        let config = LevelConfig(seed: 123, colors: 5, capacity: 4, extraEmpty: 2, difficulty: .hard)
        
        #expect(config.seed == 123)
        #expect(config.colors == 5)
        #expect(config.capacity == 4)
        #expect(config.extraEmpty == 2)
        #expect(config.tubes == 7) // 5 + 2
        #expect(config.difficulty == .hard)
    }
}
