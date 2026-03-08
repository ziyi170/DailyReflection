//
//  DeepLinkHandler.swift
//  DailyReflection
//
//  Created by 小艺 on 2026/2/17.
//
import SwiftUI
import Combine

// MARK: - DeepLink 类型
enum DailyReflectionDeepLink {
    case openAddTask
    case openToday
    case openTimer
    case openProfile
}

// MARK: - DeepLink 解析器
class DeepLinkHandler: ObservableObject {
    static let shared = DeepLinkHandler()
    
    @Published var activeLink: DailyReflectionDeepLink?
    
    func handle(url: URL) {
        guard url.scheme == "dailyreflection" else { return }
        
        switch url.host {
        case "add-task", "addTask":  // ✅ 同时兼容两种写法
            activeLink = .openAddTask
        case "today":
            activeLink = .openToday
        case "timer":
            activeLink = .openTimer
        case "profile":
            activeLink = .openProfile
        default:
            break
        }
    }
}

// MARK: - ViewModifier
struct DailyReflectionDeepLinkModifier: ViewModifier {
    
    @StateObject private var deepLinkHandler = DeepLinkHandler.shared
    
    @Binding var selectedTab: Int
    
    func body(content: Content) -> some View {
        content
            .onOpenURL { url in
                deepLinkHandler.handle(url: url)
            }
            .onReceive(deepLinkHandler.$activeLink) { link in
                guard let link = link else { return }
                
                switch link {
                case .openAddTask:
                    selectedTab = 0
                    NotificationCenter.default.post(name: .openAddTaskSheet, object: nil)
                    
                case .openToday:
                    selectedTab = 0
                    
                case .openTimer:
                    selectedTab = 3
                    
                case .openProfile:
                    selectedTab = 4
                }
            }
    }
}

// MARK: - View 扩展
extension View {
    func handleDailyReflectionDeepLinks(selectedTab: Binding<Int>) -> some View {
        self.modifier(DailyReflectionDeepLinkModifier(selectedTab: selectedTab))
    }
}

// MARK: - Notification
extension Notification.Name {
    static let openAddTaskSheet = Notification.Name("openAddTaskSheet")
}