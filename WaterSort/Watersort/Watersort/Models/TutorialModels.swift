import Foundation

// MARK: - Tutorial Models
struct TutorialStep: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let type: TutorialStepType
    let targetElement: String? // ハイライトする要素のID
    let isInteractive: Bool // ユーザーの操作が必要か
    
    init(id: String, title: String, description: String, type: TutorialStepType, targetElement: String? = nil, isInteractive: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.targetElement = targetElement
        self.isInteractive = isInteractive
    }
}

enum TutorialStepType: String, Codable {
    case welcome = "welcome"
    case gameRules = "gameRules"
    case basicControls = "basicControls"
    case advancedFeatures = "advancedFeatures"
    case settings = "settings"
}

struct TutorialProgress: Codable {
    var completedSteps: Set<String> = []
    var currentStepIndex: Int = 0
    var isCompleted: Bool = false
    
    mutating func completeStep(_ stepId: String) {
        completedSteps.insert(stepId)
    }
    
    mutating func nextStep() {
        currentStepIndex += 1
    }
}

class TutorialManager: ObservableObject {
    @Published var currentTutorial: TutorialProgress
    @Published var isShowingTutorial: Bool = false
    @Published var currentStep: TutorialStep?
    
    private let userDefaults = UserDefaults.standard
    private let tutorialProgressKey = "tutorialProgress"
    
    static let shared = TutorialManager()
    
    private init() {
        if let data = userDefaults.data(forKey: tutorialProgressKey),
           let progress = try? JSONDecoder().decode(TutorialProgress.self, from: data) {
            self.currentTutorial = progress
        } else {
            self.currentTutorial = TutorialProgress()
        }
        
        // 初回起動時もチュートリアルは表示しない（仕様変更）
        isShowingTutorial = false
    }
    
    func startTutorial() {
        isShowingTutorial = true
        currentTutorial.currentStepIndex = 0
        loadCurrentStep()
    }
    
    func nextStep() {
        if let currentStep = currentStep {
            currentTutorial.completeStep(currentStep.id)
        }
        currentTutorial.nextStep()
        loadCurrentStep()
        saveProgress()
    }
    
    func skipTutorial() {
        isShowingTutorial = false
        currentTutorial.isCompleted = true
        saveProgress()
    }
    
    func completeTutorial() {
        isShowingTutorial = false
        currentTutorial.isCompleted = true
        saveProgress()
    }
    
    func loadCurrentStep() {
        let steps = getTutorialSteps()
        if currentTutorial.currentStepIndex < steps.count {
            currentStep = steps[currentTutorial.currentStepIndex]
        } else {
            completeTutorial()
        }
    }
    
    private func saveProgress() {
        if let data = try? JSONEncoder().encode(currentTutorial) {
            userDefaults.set(data, forKey: tutorialProgressKey)
        }
    }
    
    func getTutorialSteps() -> [TutorialStep] {
        return [
            TutorialStep(
                id: "welcome",
                title: "Welcome to JewelSort!",
                description: "Sort colorful gems by color and organize the cases.",
                type: .welcome
            ),
            TutorialStep(
                id: "gameRules",
                title: "Game Rules",
                description: "Collect same-colored gems into a single case to clear. You have two empty cases.",
                type: .gameRules
            ),
            TutorialStep(
                id: "basicControls",
                title: "Basic Controls",
                description: "Tap a case to select, then tap another case to pour gems.",
                type: .basicControls,
                isInteractive: true
            ),
            TutorialStep(
                id: "hint",
                title: "Hint",
                description: "Use the hint button when stuck. It shows the next move as ‘Case X → Case Y’.",
                type: .advancedFeatures
            ),
            TutorialStep(
                id: "undo",
                title: "Undo",
                description: "Undo reverses the last move. Restarting resets your streak.",
                type: .advancedFeatures
            ),
            TutorialStep(
                id: "settings",
                title: "Settings",
                description: "Adjust difficulty and animation speed in Settings.",
                type: .settings
            )
        ]
    }
}
