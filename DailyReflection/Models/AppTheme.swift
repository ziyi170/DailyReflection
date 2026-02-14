import SwiftUI

struct AppTheme: Identifiable {
    let id: String
    let name: String
    let primaryColor: Color
    let secondaryColor: Color
    let price: Int?
    let isPro: Bool
    
    var priceText: String {
        if let price = price {
            return "¥\(price)"
        } else if isPro {
            return "Pro专属"
        } else {
            return "免费"
        }
    }
}
