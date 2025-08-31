import Foundation
import SwiftUI

// MARK: - Color Management
struct GameColors {
    static let colorBlindFriendly: [Color] = [
        Color(red: 0.8, green: 0.4, blue: 0.4),   // 赤
        Color(red: 0.4, green: 0.6, blue: 0.8),   // 青
        Color(red: 0.4, green: 0.8, blue: 0.4),   // 緑
        Color(red: 0.8, green: 0.8, blue: 0.4),   // 黄
        Color(red: 0.8, green: 0.6, blue: 0.4),   // オレンジ
        Color(red: 0.8, green: 0.4, blue: 0.8),   // 紫
        Color(red: 0.8, green: 0.6, blue: 0.8),   // ピンク
        Color(red: 0.4, green: 0.8, blue: 0.8),   // シアン
        Color(red: 0.6, green: 0.4, blue: 0.2),   // 茶
        Color(red: 0.6, green: 0.8, blue: 0.6),   // ミント
        Color(red: 0.6, green: 0.4, blue: 0.8),   // インディゴ
        Color(red: 0.4, green: 0.6, blue: 0.6),   // ティール
        Color(red: 0.6, green: 0.6, blue: 0.6),   // グレー
        Color(red: 0.3, green: 0.3, blue: 0.3)    // 黒
    ]
    
    static let standard: [Color] = [
        .red, .blue, .green, .yellow, .orange, .purple, .pink, .cyan,
        .brown, .mint, .indigo, .teal, .gray, .black
    ]
    
    static func getColor(for index: Int, colorBlindMode: Bool = false) -> Color {
        let colors = colorBlindMode ? colorBlindFriendly : standard
        return colors[index % colors.count]
    }
    
    static func getContrastColor(for color: Color) -> Color {
        // 色の明度を計算してコントラスト色を返す
        let brightness = getBrightness(color: color)
        return brightness > 0.5 ? .black : .white
    }
    
    static func getBrightness(color: Color) -> CGFloat {
        // 簡易的な明度計算
        let components = color.components
        return (components.red * 0.299 + components.green * 0.587 + components.blue * 0.114)
    }
}

// Color拡張
extension Color {
    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue, alpha)
    }
    
    // カラーブラインド対応の色分け
    var colorBlindAlternative: Color {
        let brightness = GameColors.getBrightness(color: self)
        let saturation: CGFloat = 0.8
        let hue = self.hue
        
        if brightness < 0.3 {
            return Color(hue: hue, saturation: saturation, brightness: 0.7)
        } else if brightness > 0.7 {
            return Color(hue: hue, saturation: saturation, brightness: 0.3)
        } else {
            return self
        }
    }
    
    var hue: CGFloat {
        let components = self.components
        let max = max(components.red, components.green, components.blue)
        let min = min(components.red, components.green, components.blue)
        let delta = max - min
        
        if delta == 0 {
            return 0
        }
        
        var hue: CGFloat = 0
        if max == components.red {
            hue = (components.green - components.blue) / delta
        } else if max == components.green {
            hue = 2 + (components.blue - components.red) / delta
        } else {
            hue = 4 + (components.red - components.green) / delta
        }
        
        hue *= 60
        if hue < 0 {
            hue += 360
        }
        
        return hue / 360
    }

    // 共通の色ミックスヘルパ
    func mixed(with other: Color, t: CGFloat) -> Color {
        let a = self.components
        let b = other.components
        let tt = max(0, min(1, t))
        let r = a.red * (1 - tt) + b.red * tt
        let g = a.green * (1 - tt) + b.green * tt
        let bl = a.blue * (1 - tt) + b.blue * tt
        let al = a.alpha * (1 - tt) + b.alpha * tt
        return Color(red: r, green: g, blue: bl, opacity: al)
    }
}

// MARK: - Color Theme
enum ColorTheme: String, CaseIterable, Codable {
    case classic = "classic"
    case pastel = "pastel"
    case neon = "neon"
    case earth = "earth"
    
    var displayName: String {
        switch self {
        case .classic: return "クラシック"
        case .pastel: return "パステル"
        case .neon: return "ネオン"
        case .earth: return "アース"
        }
    }
    
    var colors: [Color] {
        switch self {
        case .classic:
            return GameColors.standard
        case .pastel:
            return [
                Color(red: 1.0, green: 0.7, blue: 0.7),   // 薄い赤
                Color(red: 0.7, green: 0.8, blue: 1.0),   // 薄い青
                Color(red: 0.7, green: 1.0, blue: 0.7),   // 薄い緑
                Color(red: 1.0, green: 1.0, blue: 0.7),   // 薄い黄
                Color(red: 1.0, green: 0.8, blue: 0.7),   // 薄いオレンジ
                Color(red: 1.0, green: 0.7, blue: 1.0),   // 薄い紫
                Color(red: 1.0, green: 0.8, blue: 1.0),   // 薄いピンク
                Color(red: 0.7, green: 1.0, blue: 1.0),   // 薄いシアン
                Color(red: 0.8, green: 0.6, blue: 0.4),   // 薄い茶
                Color(red: 0.8, green: 1.0, blue: 0.8),   // 薄いミント
                Color(red: 0.8, green: 0.6, blue: 1.0),   // 薄いインディゴ
                Color(red: 0.6, green: 0.8, blue: 0.8),   // 薄いティール
                Color(red: 0.8, green: 0.8, blue: 0.8),   // 薄いグレー
                Color(red: 0.5, green: 0.5, blue: 0.5)    // 薄い黒
            ]
        case .neon:
            return [
                Color(red: 1.0, green: 0.0, blue: 0.0),   // ネオン赤
                Color(red: 0.0, green: 0.0, blue: 1.0),   // ネオン青
                Color(red: 0.0, green: 1.0, blue: 0.0),   // ネオン緑
                Color(red: 1.0, green: 1.0, blue: 0.0),   // ネオン黄
                Color(red: 1.0, green: 0.5, blue: 0.0),   // ネオンオレンジ
                Color(red: 1.0, green: 0.0, blue: 1.0),   // ネオン紫
                Color(red: 1.0, green: 0.5, blue: 1.0),   // ネオンピンク
                Color(red: 0.0, green: 1.0, blue: 1.0),   // ネオンシアン
                Color(red: 0.8, green: 0.4, blue: 0.0),   // ネオン茶
                Color(red: 0.5, green: 1.0, blue: 0.5),   // ネオンミント
                Color(red: 0.5, green: 0.0, blue: 1.0),   // ネオンインディゴ
                Color(red: 0.0, green: 0.8, blue: 0.8),   // ネオンティール
                Color(red: 0.8, green: 0.8, blue: 0.8),   // ネオングレー
                Color(red: 0.2, green: 0.2, blue: 0.2)    // ネオン黒
            ]
        case .earth:
            return [
                Color(red: 0.6, green: 0.3, blue: 0.2),   // アース赤
                Color(red: 0.2, green: 0.4, blue: 0.6),   // アース青
                Color(red: 0.3, green: 0.6, blue: 0.3),   // アース緑
                Color(red: 0.8, green: 0.7, blue: 0.4),   // アース黄
                Color(red: 0.7, green: 0.5, blue: 0.3),   // アースオレンジ
                Color(red: 0.5, green: 0.3, blue: 0.6),   // アース紫
                Color(red: 0.8, green: 0.5, blue: 0.6),   // アースピンク
                Color(red: 0.4, green: 0.6, blue: 0.6),   // アースシアン
                Color(red: 0.5, green: 0.4, blue: 0.2),   // アース茶
                Color(red: 0.5, green: 0.7, blue: 0.5),   // アースミント
                Color(red: 0.4, green: 0.3, blue: 0.6),   // アースインディゴ
                Color(red: 0.3, green: 0.5, blue: 0.5),   // アースティール
                Color(red: 0.5, green: 0.5, blue: 0.5),   // アースグレー
                Color(red: 0.2, green: 0.2, blue: 0.2)    // アース黒
            ]
        }
    }
}
