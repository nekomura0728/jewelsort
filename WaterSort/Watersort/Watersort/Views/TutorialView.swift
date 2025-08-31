import SwiftUI

struct TutorialView: View {
    @StateObject var tutorialManager = TutorialManager.shared
    @State private var showingOverlay = false
    
    var body: some View {
        ZStack {
            if showingOverlay {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
            }
            
            if let currentStep = tutorialManager.currentStep {
                VStack(spacing: 20) {
                    HStack {
                        Text("チュートリアル")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("Skip") {
                            tutorialManager.skipTutorial()
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal)
                    
                    HStack(spacing: 8) {
                        ForEach(0..<tutorialManager.getTutorialSteps().count, id: \.self) { index in
                            Circle()
                                .fill(index <= tutorialManager.currentTutorial.currentStepIndex ? Color.white : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    VStack(spacing: 16) {
                        Text(currentStep.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(currentStep.description)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                        
                        stepIcon(for: currentStep.type)
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 30)
                    
                    HStack(spacing: 20) {
                        if tutorialManager.currentTutorial.currentStepIndex > 0 {
                            Button("前へ") {
                                tutorialManager.currentTutorial.currentStepIndex -= 1
                                tutorialManager.loadCurrentStep()
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue.opacity(0.8))
                            .cornerRadius(10)
                        }
                        
                        Button(tutorialManager.currentTutorial.currentStepIndex >= tutorialManager.getTutorialSteps().count - 1 ? "完了" : "次へ") {
                            if tutorialManager.currentTutorial.currentStepIndex >= tutorialManager.getTutorialSteps().count - 1 {
                                tutorialManager.completeTutorial()
                            } else {
                                tutorialManager.nextStep()
                            }
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                    }
                    .padding(.bottom, 30)
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.purple.opacity(0.9)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .padding(.vertical, 80)
                .frame(maxWidth: 600)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingOverlay = true
            }
        }
    }
    
    @ViewBuilder
    private func stepIcon(for type: TutorialStepType) -> some View {
        switch type {
        case .welcome:
            Image(systemName: "hand.wave.fill")
        case .gameRules:
            Image(systemName: "book.fill")
        case .basicControls:
            Image(systemName: "hand.tap.fill")
        case .advancedFeatures:
            Image(systemName: "lightbulb.fill")
        case .settings:
            Image(systemName: "gearshape.fill")
        }
    }
}
