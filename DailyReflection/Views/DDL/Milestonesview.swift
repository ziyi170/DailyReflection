import SwiftUI
import Combine

// MARK: - 主视图：DDL + 倒数日双页面
struct MilestonesView: View {
    @State private var selectedTab: MilestoneTab = .ddl

    enum MilestoneTab: String, CaseIterable {
        case ddl = "DDL"
        case countdown = "倒数日"

        var icon: String {
            switch self {
            case .ddl: return "flag.fill"
            case .countdown: return "calendar.badge.clock"
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    ForEach(MilestoneTab.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                TabView(selection: $selectedTab) {
                    DDLListView()
                        .tag(MilestoneTab.ddl)
                    CountdownDaysView()
                        .tag(MilestoneTab.countdown)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("里程碑")
        }
    }
}

// MARK: - DDL 列表视图
struct DDLListView: View {
    @State private var projects: [DDLProject] = []
    @State private var showingAddProject = false
    @State private var expandedProjectId: UUID?

    var activeProjects: [DDLProject] {
        projects.filter { !$0.isCompleted }.sorted { $0.deadline < $1.deadline }
    }

    var completedProjects: [DDLProject] {
        projects.filter { $0.isCompleted }.sorted { $0.deadline > $1.deadline }
    }

    var body: some View {
        ZStack {
            if projects.isEmpty {
                emptyState
            } else {
                List {
                    if !activeProjects.isEmpty {
                        Section("进行中") {
                            ForEach(activeProjects) { project in
                                DDLProjectRow(
                                    project: project,
                                    isExpanded: expandedProjectId == project.id,
                                    onTap: { toggleExpanded(project.id) },
                                    onToggle: { toggleCompletion(project) },
                                    onNotesChange: { updateNotes(project.id, $0) }
                                )
                            }
                            .onDelete { deleteProjects(at: $0, from: activeProjects) }
                        }
                    }

                    if !completedProjects.isEmpty {
                        Section("已完成") {
                            ForEach(completedProjects) { project in
                                DDLProjectRow(
                                    project: project,
                                    isExpanded: false,
                                    onTap: {},
                                    onToggle: { toggleCompletion(project) },
                                    onNotesChange: { _ in }
                                )
                            }
                            .onDelete { deleteProjects(at: $0, from: completedProjects) }
                        }
                    }
                }
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button { showingAddProject = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.cyan, .white)
                            .shadow(radius: 4)
                    }
                    .padding(20)
                }
            }
        }
        .sheet(isPresented: $showingAddProject) {
            AddDDLProjectView(onAdd: { project in
                addDDLProject(project)
            })
        }
        .onAppear { loadProjects() }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "flag.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("还没有DDL项目")
                .font(.title2).fontWeight(.semibold)
            Text("点击右下角 + 添加")
                .font(.subheadline).foregroundColor(.secondary)
        }
    }

    private func toggleExpanded(_ id: UUID) {
        withAnimation { expandedProjectId = (expandedProjectId == id ? nil : id) }
    }

    private func toggleCompletion(_ project: DDLProject) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index].isCompleted.toggle()
            if let reminderId = projects[index].reminderItemId {
                CalendarSyncManager.shared.updateDDLInReminders(reminderId: reminderId, ddl: projects[index])
            }
            // ✅ 完成时取消通知，恢复时重新注册
            if projects[index].isCompleted {
                NotificationManager.shared.cancelNotifications(for: projects[index].id)
            } else {
                NotificationManager.shared.reschedule(for: projects[index])
            }
            saveProjects()
        }
    }

    private func updateNotes(_ id: UUID, _ notes: String) {
        if let index = projects.firstIndex(where: { $0.id == id }) {
            projects[index].notes = notes
            saveProjects()
        }
    }

    private func deleteProjects(at offsets: IndexSet, from list: [DDLProject]) {
        let idsToDelete = offsets.map { list[$0].id }
        for id in idsToDelete {
            if let project = projects.first(where: { $0.id == id }) {
                // 取消本地通知
                NotificationManager.shared.cancelNotifications(for: id)
                // 从系统提醒事项删除
                if let reminderId = project.reminderItemId {
                    CalendarSyncManager.shared.deleteDDLFromReminders(reminderId: reminderId)
                }
            }
        }
        projects.removeAll { idsToDelete.contains($0.id) }
        saveProjects()
    }

    // ✅ 修复：CalendarSyncManager.addDDLToReminders 已在内部把 reminderId 写入
    //    UserDefaults（key: reminderItemId_\(id)），reminderItemId 是只读 getter
    //    不需要也不能手动赋值，直接删除那行赋值即可
    private func addDDLProject(_ project: DDLProject) {
        _ = CalendarSyncManager.shared.addDDLToReminders(project)
        // ✅ 按照用户在 AddDDLProjectView 设定的提醒时间发本地通知
        NotificationManager.shared.reschedule(for: project)
        projects.append(project)
        saveProjects()
    }

    private func loadProjects() {
        if let data = UserDefaults.standard.data(forKey: "ddlProjects"),
           let decoded = try? JSONDecoder().decode([DDLProject].self, from: data) {
            projects = decoded
        }
    }

    private func saveProjects() {
        if let encoded = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(encoded, forKey: "ddlProjects")
        }
    }
}

// MARK: - DDL 项目行视图
struct DDLProjectRow: View {
    let project: DDLProject
    let isExpanded: Bool
    let onTap: () -> Void
    let onToggle: () -> Void
    let onNotesChange: (String) -> Void

    @State private var notesText: String

    init(project: DDLProject, isExpanded: Bool, onTap: @escaping () -> Void,
         onToggle: @escaping () -> Void, onNotesChange: @escaping (String) -> Void) {
        self.project = project
        self.isExpanded = isExpanded
        self.onTap = onTap
        self.onToggle = onToggle
        self.onNotesChange = onNotesChange
        _notesText = State(initialValue: project.notes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    Button(action: onToggle) {
                        Image(systemName: project.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundColor(project.isCompleted ? .green : .gray)
                    }
                    .buttonStyle(BorderlessButtonStyle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.title)
                            .font(.headline)
                            .strikethrough(project.isCompleted)

                        HStack {
                            Image(systemName: "clock").font(.caption)
                            Text(project.timeRemaining)
                                .font(.subheadline)
                                .foregroundColor(project.isOverdue ? .red : .secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded && !project.isCompleted {
                VStack(alignment: .leading, spacing: 8) {
                    Text("备注")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    TextEditor(text: $notesText)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .onChange(of: notesText) { _, newValue in
                            onNotesChange(newValue)
                        }
                }
                .transition(.opacity)
            }
        }
    }
}

// MARK: - 添加 DDL 视图
struct AddDDLProjectView: View {
    let onAdd: (DDLProject) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var deadline = Date().addingTimeInterval(86400 * 7)
    @State private var selectedReminders: Set<ReminderSetting.ReminderType> = []

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("项目信息")) {
                    TextField("项目名称", text: $title)
                    DatePicker("截止日期", selection: $deadline, in: Date()...)
                }

                Section(header: Text("提醒设置")) {
                    ForEach([
                        ReminderSetting.ReminderType.oneHourBefore,
                        .oneDayBefore,
                        .threeDaysBefore,
                        .oneWeekBefore
                    ], id: \.self) { type in
                        Toggle(type.rawValue, isOn: Binding(
                            get: { selectedReminders.contains(type) },
                            set: { isOn in
                                if isOn { selectedReminders.insert(type) }
                                else    { selectedReminders.remove(type) }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("添加DDL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") { addProject() }
                        .disabled(title.isEmpty)
                }
            }
        }
    }

    func addProject() {
        let reminders = selectedReminders.map { ReminderSetting(type: $0) }
        let newProject = DDLProject(
            title: title,
            deadline: deadline,
            reminderSettings: reminders
        )
        onAdd(newProject)
        dismiss()
    }
}

// MARK: - 倒数日视图
struct CountdownDaysView: View {
    @State private var countdowns: [CountdownDay] = []
    @State private var showingAddCountdown = false

    var pinnedCountdowns: [CountdownDay] {
        countdowns.filter { $0.isPinned }.sorted { abs($0.daysCount) < abs($1.daysCount) }
    }

    var otherCountdowns: [CountdownDay] {
        countdowns.filter { !$0.isPinned }.sorted { $0.date < $1.date }
    }

    var body: some View {
        ZStack {
            if countdowns.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        if !pinnedCountdowns.isEmpty {
                            ForEach(pinnedCountdowns) { countdown in
                                CalendarCardView(
                                    countdown: countdown,
                                    onTogglePin: { togglePin(countdown) },
                                    onDelete: { deleteCountdown(countdown) }
                                )
                            }
                        }

                        if !otherCountdowns.isEmpty {
                            VStack(spacing: 8) {
                                ForEach(otherCountdowns) { countdown in
                                    CountdownRow(
                                        countdown: countdown,
                                        onTogglePin: { togglePin(countdown) },
                                        onDelete: { deleteCountdown(countdown) }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button { showingAddCountdown = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.purple, .white)
                            .shadow(radius: 4)
                    }
                    .padding(20)
                }
            }
        }
        .sheet(isPresented: $showingAddCountdown) {
            AddCountdownView(countdowns: $countdowns, onSave: saveCountdowns)
        }
        .onAppear { loadCountdowns() }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("还没有倒数日")
                .font(.title2).fontWeight(.semibold)
            Text("记录重要的日子")
                .font(.subheadline).foregroundColor(.secondary)
        }
    }

    private func togglePin(_ countdown: CountdownDay) {
        if let index = countdowns.firstIndex(where: { $0.id == countdown.id }) {
            countdowns[index].isPinned.toggle()
            saveCountdowns()
        }
    }

    private func deleteCountdown(_ countdown: CountdownDay) {
        countdowns.removeAll { $0.id == countdown.id }
        saveCountdowns()
    }

    private func loadCountdowns() {
        if let data = UserDefaults.standard.data(forKey: "countdownDays"),
           let decoded = try? JSONDecoder().decode([CountdownDay].self, from: data) {
            countdowns = decoded
        }
    }

    private func saveCountdowns() {
        if let encoded = try? JSONEncoder().encode(countdowns) {
            UserDefaults.standard.set(encoded, forKey: "countdownDays")
        }
    }
}

// MARK: - 倒数日数据模型
struct CountdownDay: Identifiable, Codable {
    let id: UUID
    var title: String
    var date: Date
    var isPinned: Bool
    var emoji: String

    init(id: UUID = UUID(), title: String, date: Date, isPinned: Bool = false, emoji: String = "📅") {
        self.id = id
        self.title = title
        self.date = date
        self.isPinned = isPinned
        self.emoji = emoji
    }

    var daysCount: Int {
        Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
    }

    var displayText: String {
        let days = abs(daysCount)
        if daysCount < 0      { return "还有 \(days) 天" }
        else if daysCount == 0 { return "就是今天！" }
        else                   { return "已过 \(days) 天" }
    }
}

// MARK: - 日历卡片视图（置顶样式）
struct CalendarCardView: View {
    let countdown: CountdownDay
    let onTogglePin: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text(countdown.date, format: .dateTime.month(.wide).year())
                .font(.caption)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(countdown.daysCount < 0 ? Color.red : Color.gray)

            VStack(spacing: 12) {
                Text(countdown.date, format: .dateTime.day())
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(countdown.date, format: .dateTime.weekday(.wide))
                    .font(.headline)
                    .foregroundColor(.secondary)

                Divider().padding(.horizontal, 30)

                VStack(spacing: 6) {
                    HStack {
                        Text(countdown.emoji).font(.title)
                        Text(countdown.title)
                            .font(.title3).fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                    }

                    Text(countdown.displayText)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: countdown.daysCount < 0 ? [.purple, .pink] : [.orange, .yellow],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                }
                .padding(.vertical, 12)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .frame(maxWidth: 300)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("删除", systemImage: "trash")
            }
            Button(action: onTogglePin) {
                Label("取消置顶", systemImage: "pin.slash")
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - 倒数日行视图（列表样式）
struct CountdownRow: View {
    let countdown: CountdownDay
    let onTogglePin: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(countdown.emoji).font(.title)

            VStack(alignment: .leading, spacing: 4) {
                Text(countdown.title).font(.headline)
                Text(countdown.date, format: .dateTime.year().month().day())
                    .font(.caption).foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(countdown.displayText)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(countdown.daysCount < 0 ? .purple : .orange)
                Text(countdown.date, format: .dateTime.weekday(.abbreviated))
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contextMenu {
            Button(action: onTogglePin) {
                Label("置顶", systemImage: "pin.fill")
            }
            Button(role: .destructive, action: onDelete) {
                Label("删除", systemImage: "trash")
            }
        }
    }
}

// MARK: - 添加倒数日视图
struct AddCountdownView: View {
    @Binding var countdowns: [CountdownDay]
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var date = Date()
    @State private var selectedEmoji = "📅"

    let emojiOptions = ["📅", "🎂", "💍", "🎓", "✈️", "🏠", "💼", "❤️", "🎉", "⭐", "🌸", "🎯"]

    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("倒数日名称", text: $title).font(.body)
                    DatePicker("日期", selection: $date, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                }

                Section("图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                        ForEach(emojiOptions, id: \.self) { emoji in
                            Text(emoji)
                                .font(.system(size: 32))
                                .padding(8)
                                .background(
                                    selectedEmoji == emoji
                                        ? Color.purple.opacity(0.2)
                                        : Color(.systemGray6)
                                )
                                .clipShape(Circle())
                                .onTapGesture { selectedEmoji = emoji }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("添加倒数日")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        let newCountdown = CountdownDay(
                            title: title,
                            date: Calendar.current.startOfDay(for: date),
                            emoji: selectedEmoji
                        )
                        countdowns.append(newCountdown)
                        onSave()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

#Preview {
    MilestonesView()
}