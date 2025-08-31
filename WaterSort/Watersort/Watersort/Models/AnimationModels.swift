import Foundation
import SwiftUI

// MARK: - Animation Models
struct LiquidAnimation: Identifiable {
    let id = UUID()
    var fromIndex: Int
    var toIndex: Int
    var color: Color
    var progress: CGFloat = 0.0
    var isAnimating: Bool = false
}

struct TubeAnimationState {
    var selectedScale: CGFloat = 1.0
    var isShaking: Bool = false
    var isGlowing: Bool = false
    var glowColor: Color = .blue
    var surfaceWaveBoost: CGFloat = 1.0
}

class AnimationManager: ObservableObject {
    @Published var liquidAnimations: [LiquidAnimation] = []
    @Published var tubeAnimationStates: [Int: TubeAnimationState] = [:]
    
    // アニメーション設定
    var animationDuration: TimeInterval = 0.5
    var bounceIntensity: CGFloat = 0.1
    var glowIntensity: CGFloat = 0.3
    
    func animateLiquidPour(from: Int, to: Int, color: Color) {
        let animation = LiquidAnimation(fromIndex: from, toIndex: to, color: color)
        liquidAnimations.append(animation)
        
        // アニメーション実行
        withAnimation(.easeInOut(duration: animationDuration)) {
            if let index = liquidAnimations.firstIndex(where: { $0.id == animation.id }) {
                liquidAnimations[index].isAnimating = true
                liquidAnimations[index].progress = 1.0
            }
        }
        
        // アニメーション完了後に削除
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            self.liquidAnimations.removeAll { $0.id == animation.id }
        }

        // 注ぎ先の波面を一時的に強める
        boostSurfaceWave(on: to, factor: 1.8, duration: animationDuration * 0.8)
    }
    
    func animateTubeSelection(_ tubeIndex: Int, isSelected: Bool) {
        let targetScale: CGFloat = isSelected ? 1.1 : 1.0
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if tubeAnimationStates[tubeIndex] == nil {
                tubeAnimationStates[tubeIndex] = TubeAnimationState()
            }
            tubeAnimationStates[tubeIndex]?.selectedScale = targetScale
        }
    }
    
    func animateTubeShake(_ tubeIndex: Int) {
        guard tubeAnimationStates[tubeIndex] != nil else { return }
        
        tubeAnimationStates[tubeIndex]?.isShaking = true
        
        // シェイクアニメーション
        withAnimation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)) {
            // シェイク効果は別途実装
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.tubeAnimationStates[tubeIndex]?.isShaking = false
        }
    }
    
    func animateTubeGlow(_ tubeIndex: Int, color: Color, duration: TimeInterval = 1.0) {
        guard tubeAnimationStates[tubeIndex] != nil else { return }
        
        tubeAnimationStates[tubeIndex]?.isGlowing = true
        tubeAnimationStates[tubeIndex]?.glowColor = color
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.tubeAnimationStates[tubeIndex]?.isGlowing = false
        }
    }
    
    func animateVictory() {
        // 勝利時の全チューブを光らせる
        for tubeIndex in tubeAnimationStates.keys {
            animateTubeGlow(tubeIndex, color: .yellow, duration: 2.0)
        }
    }

    // MARK: - Surface Wave Boost
    func boostSurfaceWave(on tubeIndex: Int, factor: CGFloat = 1.6, duration: TimeInterval = 0.6) {
        if tubeAnimationStates[tubeIndex] == nil {
            tubeAnimationStates[tubeIndex] = TubeAnimationState()
        }
        tubeAnimationStates[tubeIndex]?.surfaceWaveBoost = factor
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.tubeAnimationStates[tubeIndex]?.surfaceWaveBoost = 1.0
        }
    }
    
    func resetAllAnimations() {
        liquidAnimations.removeAll()
        tubeAnimationStates.removeAll()
    }
}

// MARK: - Animation Extensions
extension View {
    func shakeEffect(isShaking: Bool) -> some View {
        self.modifier(ShakeEffect(isShaking: isShaking))
    }
    
    func glowEffect(color: Color, intensity: CGFloat) -> some View {
        self.modifier(GlowEffect(color: color, intensity: intensity))
    }
}

struct ShakeEffect: ViewModifier {
    let isShaking: Bool
    @State private var animationAmount: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .offset(x: isShaking ? sin(animationAmount * .pi * CGFloat(3)) * 5 : 0)
            .onChange(of: isShaking) { _, newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)) {
                        animationAmount += 1
                    }
                }
            }
    }
}

struct GlowEffect: ViewModifier {
    let color: Color
    let intensity: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(intensity), radius: 10, x: 0, y: 0)
            .shadow(color: color.opacity(intensity * 0.5), radius: 20, x: 0, y: 0)
    }
}
