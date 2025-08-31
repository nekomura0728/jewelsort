import Foundation
import AVFoundation
import SwiftUI

// MARK: - Sound System
class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    @Published var isSoundEnabled: Bool = true
    @Published var isMusicEnabled: Bool = true
    @Published var soundVolume: Float = 0.7
    @Published var musicVolume: Float = 0.5
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var backgroundMusicPlayer: AVAudioPlayer?
    
    private init() {
        setupAudioSession()
        loadSettings()
    }
    
    // MARK: - Audio Session Setup
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Sound Effects
    
    func playSound(_ sound: SoundEffect) {
        guard isSoundEnabled else { return }
        
        if let player = audioPlayers[sound.rawValue] {
            player.volume = soundVolume
            player.currentTime = 0
            player.play()
        } else {
            loadSound(sound)
        }
        
        // ハプティックフィードバックも同時に実行
        playHapticFeedback(for: sound)
    }
    
    func playBackgroundMusic(_ music: BackgroundMusic) {
        guard isMusicEnabled else { return }
        
        if let player = backgroundMusicPlayer {
            player.volume = musicVolume
            player.currentTime = 0
            player.play()
        } else {
            loadBackgroundMusic(music)
        }
    }
    
    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
    }
    
    func pauseBackgroundMusic() {
        backgroundMusicPlayer?.pause()
    }
    
    func resumeBackgroundMusic() {
        backgroundMusicPlayer?.play()
    }
    
    // MARK: - Sound Loading
    
    private func loadSound(_ sound: SoundEffect) {
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") else {
            print("Sound file not found: \(sound.rawValue)")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.volume = soundVolume
            audioPlayers[sound.rawValue] = player
            player.play()
        } catch {
            print("Failed to load sound: \(error)")
        }
    }
    
    private func loadBackgroundMusic(_ music: BackgroundMusic) {
        guard let url = Bundle.main.url(forResource: music.rawValue, withExtension: "mp3") else {
            print("Music file not found: \(music.rawValue)")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1 // 無限ループ
            player.volume = musicVolume
            backgroundMusicPlayer = player
            player.play()
        } catch {
            print("Failed to load background music: \(error)")
        }
    }
    
    // MARK: - Settings Management
    
    private func loadSettings() {
        let userDefaults = UserDefaults.standard
        isSoundEnabled = userDefaults.bool(forKey: "soundEnabled")
        isMusicEnabled = userDefaults.bool(forKey: "musicEnabled")
        soundVolume = userDefaults.float(forKey: "soundVolume")
        musicVolume = userDefaults.float(forKey: "musicVolume")
        
        // デフォルト値の設定
        if userDefaults.object(forKey: "soundEnabled") == nil {
            isSoundEnabled = true
            userDefaults.set(true, forKey: "soundEnabled")
        }
        if userDefaults.object(forKey: "musicEnabled") == nil {
            isMusicEnabled = true
            userDefaults.set(true, forKey: "musicEnabled")
        }
        if userDefaults.object(forKey: "soundVolume") == nil {
            soundVolume = 0.7
            userDefaults.set(0.7, forKey: "soundVolume")
        }
        if userDefaults.object(forKey: "musicVolume") == nil {
            musicVolume = 0.5
            userDefaults.set(0.5, forKey: "musicVolume")
        }
    }
    
    func saveSettings() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(isSoundEnabled, forKey: "soundEnabled")
        userDefaults.set(isMusicEnabled, forKey: "musicEnabled")
        userDefaults.set(soundVolume, forKey: "soundVolume")
        userDefaults.set(musicVolume, forKey: "musicVolume")
    }
    
    // MARK: - Volume Control
    
    func setSoundVolume(_ volume: Float) {
        soundVolume = max(0, min(1, volume))
        saveSettings()
        
        // 現在再生中の音の音量を更新
        for player in audioPlayers.values {
            player.volume = soundVolume
        }
    }
    
    func setMusicVolume(_ volume: Float) {
        musicVolume = max(0, min(1, volume))
        saveSettings()
        
        // 背景音楽の音量を更新
        backgroundMusicPlayer?.volume = musicVolume
    }
    
    // MARK: - Game Sound Triggers
    
    func playGameStart() {
        playSound(.gameStart)
    }
    
    func playTubeSelect() {
        playSound(.tubeSelect)
    }
    
    func playLiquidPour() {
        playSound(.liquidPour)
    }
    
    // MARK: - Haptic Feedback
    
    private func playHapticFeedback(for sound: SoundEffect) {
        switch sound {
        case .victory, .levelComplete:
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        case .invalidMove:
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.warning)
        case .liquidPour, .tubeSelect:
            let lightImpactFeedback = UIImpactFeedbackGenerator(style: .light)
            lightImpactFeedback.impactOccurred()
        case .buttonTap:
            let selectionFeedback = UISelectionFeedbackGenerator()
            selectionFeedback.selectionChanged()
        default:
            let lightImpactFeedback = UIImpactFeedbackGenerator(style: .light)
            lightImpactFeedback.impactOccurred()
        }
    }
    
    func playInvalidMove() {
        playSound(.invalidMove)
    }
    
    func playLevelComplete() {
        playSound(.levelComplete)
    }
    
    func playVictory() {
        playSound(.victory)
        // 勝利時は背景音楽を一時停止
        pauseBackgroundMusic()
    }
    
    func playHint() {
        playSound(.hint)
    }
    
    func playUndo() {
        playSound(.undo)
    }
    
    func playButtonTap() {
        playSound(.buttonTap)
    }
    
    func playSettingsChange() {
        playSound(.settingsChange)
    }
}

// MARK: - Sound Effect Types

enum SoundEffect: String, CaseIterable {
    case gameStart = "game_start"
    case tubeSelect = "tube_select"
    case liquidPour = "liquid_pour"
    case invalidMove = "invalid_move"
    case levelComplete = "level_complete"
    case victory = "victory"
    case hint = "hint"
    case undo = "undo"
    case buttonTap = "button_tap"
    case settingsChange = "settings_change"
    
    var displayName: String {
        switch self {
        case .gameStart: return "ゲーム開始"
        case .tubeSelect: return "チューブ選択"
        case .liquidPour: return "液体注ぎ"
        case .invalidMove: return "無効な移動"
        case .levelComplete: return "レベル完了"
        case .victory: return "勝利"
        case .hint: return "ヒント"
        case .undo: return "アンドゥ"
        case .buttonTap: return "ボタンタップ"
        case .settingsChange: return "設定変更"
        }
    }
    
    var description: String {
        switch self {
        case .gameStart: return "ゲーム開始時の音"
        case .tubeSelect: return "チューブを選択した時の音"
        case .liquidPour: return "液体を注いだ時の音"
        case .invalidMove: return "無効な移動を試みた時の音"
        case .levelComplete: return "レベルをクリアした時の音"
        case .victory: return "ゲームクリア時の音"
        case .hint: return "ヒントを使用した時の音"
        case .undo: return "アンドゥした時の音"
        case .buttonTap: return "ボタンをタップした時の音"
        case .settingsChange: return "設定を変更した時の音"
        }
    }
}

// MARK: - Background Music Types

enum BackgroundMusic: String, CaseIterable {
    case mainTheme = "main_theme"
    case gameplay = "gameplay"
    case relaxing = "relaxing"
    case energetic = "energetic"
    
    var displayName: String {
        switch self {
        case .mainTheme: return "メインテーマ"
        case .gameplay: return "ゲームプレイ"
        case .relaxing: return "リラックス"
        case .energetic: return "エネルギッシュ"
        }
    }
    
    var description: String {
        switch self {
        case .mainTheme: return "メイン画面用の音楽"
        case .gameplay: return "ゲームプレイ用の音楽"
        case .relaxing: return "落ち着いた雰囲気の音楽"
        case .energetic: return "元気が出る音楽"
        }
    }
}

// MARK: - Sound Settings View

struct SoundSettingsView: View {
    @ObservedObject var soundManager = SoundManager.shared
    @State private var selectedMusic: BackgroundMusic = .mainTheme
    
    var body: some View {
        Form {
            Section("サウンド設定") {
                Toggle("サウンド効果", isOn: $soundManager.isSoundEnabled)
                    .onChange(of: soundManager.isSoundEnabled) { _, _ in
                        soundManager.saveSettings()
                    }
                
                Toggle("背景音楽", isOn: $soundManager.isMusicEnabled)
                    .onChange(of: soundManager.isMusicEnabled) { _, _ in
                        if soundManager.isMusicEnabled {
                            soundManager.playBackgroundMusic(selectedMusic)
                        } else {
                            soundManager.stopBackgroundMusic()
                        }
                        soundManager.saveSettings()
                    }
            }
            
            Section("音量設定") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("効果音")
                        Spacer()
                        Text("\(Int(soundManager.soundVolume * 100))%")
                    }
                    
                    Slider(value: Binding(
                        get: { Double(soundManager.soundVolume) },
                        set: { soundManager.setSoundVolume(Float($0)) }
                    ), in: 0...1, step: 0.1)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("音楽")
                        Spacer()
                        Text("\(Int(soundManager.musicVolume * 100))%")
                    }
                    
                    Slider(value: Binding(
                        get: { Double(soundManager.musicVolume) },
                        set: { soundManager.setMusicVolume(Float($0)) }
                    ), in: 0...1, step: 0.1)
                }
            }
            
            Section("背景音楽") {
                Picker("音楽", selection: $selectedMusic) {
                    ForEach(BackgroundMusic.allCases, id: \.self) { music in
                        Text(music.displayName).tag(music)
                    }
                }
                .onChange(of: selectedMusic) { _, newMusic in
                    if soundManager.isMusicEnabled {
                        soundManager.playBackgroundMusic(newMusic)
                    }
                }
                
                HStack {
                    Button("再生") {
                        soundManager.playBackgroundMusic(selectedMusic)
                    }
                    .disabled(!soundManager.isMusicEnabled)
                    
                    Button("停止") {
                        soundManager.stopBackgroundMusic()
                    }
                    .disabled(!soundManager.isMusicEnabled)
                    
                    Button("一時停止") {
                        soundManager.pauseBackgroundMusic()
                    }
                    .disabled(!soundManager.isMusicEnabled)
                }
            }
            
            Section("サウンドテスト") {
                ForEach(SoundEffect.allCases, id: \.self) { sound in
                    HStack {
                        Text(sound.displayName)
                        Spacer()
                        Button("再生") {
                            soundManager.playSound(sound)
                        }
                        .disabled(!soundManager.isSoundEnabled)
                    }
                }
            }
        }
        .navigationTitle("サウンド設定")
        .navigationBarTitleDisplayMode(.large)
    }
}
