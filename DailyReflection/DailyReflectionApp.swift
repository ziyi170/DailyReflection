// DailyReflectionApp.swift
// App 入口：注入全局依赖、监听前后台切换同步 Widget 数据

import SwiftUI
import ActivityKit

@main
struct DailyReflectionApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var dataManager = AppDataManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .accentColor(themeManager.currentTheme.primaryColor)
                .environment(\.currentTheme, themeManager.currentTheme)
                .onReceive(NotificationCenter.default.publisher(for: .themeDidChange)) { _ in
                    // 主题变化时强制刷新
                }
                .onOpenURL { url in
                    DeepLinkHandler.shared.handle(url: url)
                }
        }
        // App 回到前台时：
        // 1. saveToAppGroup()              — 确保 Widget 拿到最新数据
        // 2. syncCompletedTasksFromWidget() — 同步灵动岛/锁屏按钮操作回主 App
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                dataManager.saveToAppGroup()
                dataManager.syncCompletedTasksFromWidget()
            case .background:
                // 进入后台时也保存一次，确保 Widget 数据最新
                dataManager.saveToAppGroup()
            default:
                break
            }
        }
    }
}