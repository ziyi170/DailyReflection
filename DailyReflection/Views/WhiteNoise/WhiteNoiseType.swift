import Foundation

enum WhiteNoiseType: String, CaseIterable, Codable {
    case rain = "rain"
    case ocean = "ocean"
    case forest = "forest"
    case fire = "fire"
    case cafe = "cafe"
    case wind = "wind"
    
    var displayName: String {
        switch self {
        case .rain: return "雨声"
        case .ocean: return "海浪"
        case .forest: return "森林"
        case .fire: return "火焰"
        case .cafe: return "咖啡厅"
        case .wind: return "风声"
        }
    }
    
    var icon: String {
        switch self {
        case .rain: return "cloud.rain.fill"
        case .ocean: return "water.waves"
        case .forest: return "tree.fill"
        case .fire: return "flame.fill"
        case .cafe: return "cup.and.saucer.fill"
        case .wind: return "wind"
        }
    }
    
    var color: (start: String, end: String) {
        switch self {
        case .rain: return ("blue", "cyan")
        case .ocean: return ("teal", "blue")
        case .forest: return ("green", "mint")
        case .fire: return ("orange", "red")
        case .cafe: return ("brown", "orange")
        case .wind: return ("gray", "blue")
        }
    }
    
    // 在线音频备用URL（免费资源）
    var onlineURL: String? {
        switch self {
        case .rain:
            return "https://www.soundjay.com/nature/sounds/rain-01.mp3"
        case .ocean:
            return "https://www.soundjay.com/nature/sounds/ocean-wave-1.mp3"
        case .forest:
            return "https://www.soundjay.com/nature/sounds/forest-1.mp3"
        case .fire:
            return "https://www.soundjay.com/nature/sounds/fire-1.mp3"
        default:
            return nil
        }
    }
    //
    var isFree: Bool {
        switch self {
        case .rain, .wind:
            return true
        case .ocean, .fire, .forest, .cafe:
            return false
        }
    }

}
