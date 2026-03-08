import SwiftUI

struct ContentView: View {
    @StateObject private var dataManager = AppDataManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 今日（包含日历入口）
            TodayView()
                .tabItem {
                    Label("今日", systemImage: "sun.max.fill")
                }
                .tag(0)
                .environmentObject(dataManager)
            
            // 饮食管理
            CalorieTrackingView()
                .tabItem {
                    Label("饮食", systemImage: "fork.knife")
                }
                .tag(1)
                .environmentObject(dataManager)
            
            // DDL
            MilestonesView()
                .tabItem {
                    Label("DDL", systemImage: "calendar.badge.exclamationmark")
                }
                .tag(2)
            
            // 专注计时器
            TimerView()
                .tabItem {
                    Label("专注", systemImage: "timer")
                }
                .tag(3)
            
            // 个人资料
            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
                .tag(4)
        }
        .accentColor(ThemeManager.shared.currentTheme.primaryColor)
        .handleDailyReflectionDeepLinks(selectedTab: $selectedTab)
    }
}
