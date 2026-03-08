import SwiftUI

// MARK: - AppTheme Model
struct AppTheme: Identifiable, Equatable, Codable {
    let id: String
    let name: String
    let primaryColor: Color
    let secondaryColor: Color
    let price: Int?       // nil = free
    let isPro: Bool
    
    // Equatable
    static func == (lhs: AppTheme, rhs: AppTheme) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Codable support for Color
    enum CodingKeys: String, CodingKey {
        case id, name, primaryColorHex, secondaryColorHex, price, isPro
    }
    
    init(id: String, name: String, primaryColor: Color, secondaryColor: Color, price: Int?, isPro: Bool) {
        self.id = id
        self.name = name
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.price = price
        self.isPro = isPro
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        price = try container.decodeIfPresent(Int.self, forKey: .price)
        isPro = try container.decode(Bool.self, forKey: .isPro)
        
        let primaryHex = try container.decode(String.self, forKey: .primaryColorHex)
        let secondaryHex = try container.decode(String.self, forKey: .secondaryColorHex)
        primaryColor = Color(hex: primaryHex)
        secondaryColor = Color(hex: secondaryHex)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(price, forKey: .price)
        try container.encode(isPro, forKey: .isPro)
        try container.encode(primaryColor.toHex() ?? "#007AFF", forKey: .primaryColorHex)
        try container.encode(secondaryColor.toHex() ?? "#007AFF4D", forKey: .secondaryColorHex)
    }
    
    // MARK: - Computed Properties
    var displayPrice: String {
        if let price = price {
            return "¥\(price)"
        } else if isPro {
            return "Pro专属"
        } else {
            return "免费"
        }
    }
    
    var isUnlockable: Bool {
        price != nil || isPro
    }
    
    var iconName: String {
        switch id {
        case "forest": return "leaf.fill"
        case "ocean": return "water.waves"
        case "sakura": return "sparkles"
        case "business": return "briefcase.fill"
        case "sunset": return "sunset.fill"
        case "lavender": return "cloud.fill"
        case "midnight": return "moon.stars.fill"
        default: return "paintpalette.fill"
        }
    }
}

// MARK: - Color Hex Extension
extension Color {
    func toHex() -> String? {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return String(
            format: "#%02X%02X%02X%02X",
            Int(a * 255),
            Int(r * 255),
            Int(g * 255),
            Int(b * 255)
        )
    }
}