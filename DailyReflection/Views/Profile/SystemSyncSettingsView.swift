// SystemSyncSettingsView.swift
// 系统同步设置视图（iOS 日历和提醒事项）
// 放在 Views/Profile/ 文件夹中

import SwiftUI
import EventKit

struct SystemSyncSettingsView: View {
    @StateObject private var syncManager = CalendarSyncManager.shared
    @State private var showingCalendarAlert = false
    @State private var showingRemindersAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        List {
            // 日历同步部分
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(width: 40)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("同步到 iOS 日历")
                                .font(.headline)
                            Text("将任务自动添加到系统日历")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { syncManager.isCalendarSyncEnabled },
                            set: { newValue in
                                toggleCalendarSync(enabled: newValue)
                            }
                        ))
                    }
                    
                    // 权限状态
                    authorizationStatusView(
                        status: syncManager.calendarAuthStatus,
                        type: "日历"
                    )
                }
                .padding(.vertical, 8)
                
                // 日历同步说明
                if syncManager.isCalendarSyncEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("同步规则", systemImage: "info.circle")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            bulletPoint("新建任务时自动添加到日历")
                            bulletPoint("编辑任务时同步更新日历事件")
                            bulletPoint("删除任务时同时删除日历事件")
                            bulletPoint("使用独立的\"每日反思\"日历")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
                }
            } header: {
                Text("日历同步")
            } footer: {
                if syncManager.isCalendarSyncEnabled {
                    Text("任务将显示在 iOS 日历应用的\"每日反思\"日历中")
                        .font(.caption)
                }
            }
            
            // 提醒事项同步部分
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checklist")
                            .font(.title2)
                            .foregroundColor(.red)
                            .frame(width: 40)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("同步到提醒事项")
                                .font(.headline)
                            Text("将 DDL 自动添加到系统提醒")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { syncManager.isRemindersSyncEnabled },
                            set: { newValue in
                                toggleRemindersSync(enabled: newValue)
                            }
                        ))
                    }
                    
                    // 权限状态
                    authorizationStatusView(
                        status: syncManager.remindersAuthStatus,
                        type: "提醒事项"
                    )
                }
                .padding(.vertical, 8)
                
                // 提醒事项同步说明
                if syncManager.isRemindersSyncEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("同步规则", systemImage: "info.circle")
                            .font(.subheadline)
                            .foregroundColor(.red)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            bulletPoint("新建 DDL 时自动添加到提醒事项")
                            bulletPoint("编辑 DDL 时同步更新提醒")
                            bulletPoint("完成 DDL 时标记提醒为已完成")
                            bulletPoint("使用独立的\"每日反思 DDL\"列表")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.red.opacity(0.05))
                    .cornerRadius(12)
                }
            } header: {
                Text("提醒事项同步")
            } footer: {
                if syncManager.isRemindersSyncEnabled {
                    Text("DDL 将显示在提醒事项应用的\"每日反思 DDL\"列表中")
                        .font(.caption)
                }
            }
            
            // 功能说明
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    featureRow(
                        icon: "arrow.triangle.2.circlepath",
                        title: "双向同步",
                        description: "应用内修改会同步到系统，保持数据一致"
                    )
                    
                    Divider()
                    
                    featureRow(
                        icon: "shield.checkered",
                        title: "隐私保护",
                        description: "数据仅存储在您的设备上，我们不会上传任何信息"
                    )
                    
                    Divider()
                    
                    featureRow(
                        icon: "gearshape.2",
                        title: "灵活控制",
                        description: "可随时开启或关闭同步，不影响原有数据"
                    )
                }
                .padding(.vertical, 4)
            } header: {
                Text("功能特性")
            }
            
            // 常见问题
            Section {
                DisclosureGroup("如何查看同步的内容？") {
                    Text("打开 iOS 系统的「日历」或「提醒事项」应用，查找名为「每日反思」的日历和「每日反思 DDL」的提醒列表。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
                
                DisclosureGroup("关闭同步会删除已同步的内容吗？") {
                    Text("不会。关闭同步后，已添加到系统日历和提醒事项的内容会保留，只是不再自动同步新的更改。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
                
                DisclosureGroup("为什么需要授权？") {
                    Text("根据 Apple 的隐私政策，应用需要获得您的明确授权才能访问日历和提醒事项。我们承诺只在您开启同步功能时访问这些数据。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
            } header: {
                Text("常见问题")
            }
        }
        .navigationTitle("系统同步")
        .navigationBarTitleDisplayMode(.inline)
        .alert("同步状态", isPresented: $showingCalendarAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .alert("同步状态", isPresented: $showingRemindersAlert) {
            Button("确定", role: .cancel) {}
            Button("前往设置", role: .none) {
                openSettings()
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - 子视图
    
    private func authorizationStatusView(status: EKAuthorizationStatus, type: String) -> some View {
        Group {
            switch status {
            case .notDetermined:
                HStack(spacing: 8) {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.orange)
                    Text("未请求权限")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            case .restricted, .denied:
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("\(type)权限被拒绝")
                        .font(.caption)
                        .foregroundColor(.red)
                    Button("前往设置") {
                        openSettings()
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                }
            case .authorized, .fullAccess:
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("已授权")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            case .writeOnly:
                HStack(spacing: 8) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(.blue)
                    Text("仅写入权限")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            @unknown default:
                EmptyView()
            }
        }
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
    }
    
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - 方法
    
    private func toggleCalendarSync(enabled: Bool) {
        syncManager.toggleCalendarSync(enabled: enabled) { success in
            if !success {
                alertMessage = enabled ?
                    "无法开启日历同步。请在系统设置中授予日历访问权限。" :
                    "日历同步已关闭"
                showingCalendarAlert = true
            } else {
                alertMessage = enabled ?
                    "日历同步已开启。新建的任务将自动添加到系统日历。" :
                    "日历同步已关闭"
                showingCalendarAlert = true
            }
        }
    }
    
    private func toggleRemindersSync(enabled: Bool) {
        syncManager.toggleRemindersSync(enabled: enabled) { success in
            if !success {
                alertMessage = enabled ?
                    "无法开启提醒事项同步。请在系统设置中授予提醒事项访问权限。" :
                    "提醒事项同步已关闭"
                showingRemindersAlert = true
            } else {
                alertMessage = enabled ?
                    "提醒事项同步已开启。新建的 DDL 将自动添加到系统提醒事项。" :
                    "提醒事项同步已关闭"
                showingRemindersAlert = true
            }
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - 预览

#Preview {
    NavigationView {
        SystemSyncSettingsView()
    }
}
