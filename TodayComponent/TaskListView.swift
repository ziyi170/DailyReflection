//  TaskListView.swift + TaskRowView.swift (合并，统一 DS 规范)
import SwiftUI

// ============================================================
// MARK: - TaskInfoView（已废弃，保留签名避免编译报错）
// ============================================================


// ============================================================
// MARK: - TaskListView（签名保留兼容，样式统一）
// ============================================================
struct TaskListView: View {
    let tasks: [Task]
    let onToggle: (Task) -> Void
    let onTap: (Task) -> Void
    let onStart: (Task) -> Void
    let onDelete: (Task) -> Void
    let onEdit: (Task) -> Void
    let currentTaskId: UUID?
    let mood: String
    let username: String

    @Binding var showingAddTask: Bool
    @Binding var showingSmartAdd: Bool

    var body: some View {
        VStack(spacing: 0) {
            // 标题行
            HStack(spacing: 6) {
                Text("今日任务").font(DS.T.sectionHeader)
                if !tasks.isEmpty {
                    Text("\(tasks.filter{$0.isCompleted}.count)/\(tasks.count)")
                        .font(.system(size: 11, weight: .semibold)).foregroundColor(.white)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(DS.blue.opacity(0.75)).cornerRadius(9)
                }
                Spacer()
                HStack(spacing: 7) {
                    miniBtn("sparkles", color: .purple) { showingSmartAdd = true }
                    miniBtn("plus",     color: .blue)   { showingAddTask  = true }
                }
            }
            .padding(.horizontal, DS.padding).padding(.vertical, 12)
            .background(DS.rowBg)

            if tasks.isEmpty {
                EmptyStateViewWithSmartAdd(showingAddTask: $showingAddTask, showingSmartAdd: $showingSmartAdd)
            } else {
                VStack(spacing: 0) {
                    ForEach(tasks) { task in
                        TaskRow(
                            task: task,
                            isCurrentTask: currentTaskId == task.id,
                            onToggle: { onToggle(task) },
                            onStart:  { onStart(task) },
                            onTap:    { onEdit(task) }
                        )
                        .padding(.horizontal, DS.padding).padding(.vertical, 8)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { onDelete(task) } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button { onEdit(task) } label: { Label("编辑", systemImage: "pencil") }
                                .tint(DS.blue)
                        }
                        if task.id != tasks.last?.id {
                            Divider().padding(.leading, DS.padding)
                        }
                    }
                }.padding(.bottom, 8)
            }
        }
        .background(DS.cardBg).cornerRadius(DS.radius)
        .shadow(color: DS.shadowColor, radius: DS.shadowRadius, x: 0, y: 2)
        .onAppear {
            if !tasks.isEmpty {
                LiveActivityManager.shared.start(tasks: tasks, mood: mood, username: username)
            }
        }
        .onChange(of: tasks.count) { _ in
            if tasks.isEmpty { LiveActivityManager.shared.stop() }
            else { LiveActivityManager.shared.update(tasks: tasks, mood: mood) }
        }
    }

    private func miniBtn(_ icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold)).foregroundColor(color)
                .frame(width: 26, height: 26).background(color.opacity(0.1)).cornerRadius(7)
        }
    }
}
