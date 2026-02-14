//  TodayView.swift
import SwiftUI
import Charts

struct TodayView: View {
    @EnvironmentObject var dataManager: AppDataManager
    @StateObject private var whiteNoiseManager = WhiteNoiseManager.shared
    @StateObject private var timerManager = TimerManager.shared
    @StateObject private var syncManager = CalendarSyncManager.shared

    @State private var showingAddTask = false
    @State private var showingSmartAdd = false
    @State private var editingTask: Task?
    @State private var selectedDate = Date()
    @State private var showCalendar = false

    @State private var isStatisticsExpanded = true
    @State private var isReflectionExpanded = false
    @State private var cachedCalculations: TodayCalculations?
    @FocusState private var focusedField: ReflectionField?
    @State private var hasAutoStartedLiveActivity = false

    enum ReflectionField: Hashable { case yesterday, today, tomorrow }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {

                    // 进度横幅（有任务才显示）
                    if !todayTasks.isEmpty, let calc = cachedCalculations {
                        TaskProgressBanner(
                            completedTasks: calc.completedTasks,
                            totalTasks: calc.totalTasks,
                            percentage: calc.completionPercentage
                        )
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }

                    // 日历入口卡片
                    CalendarEntryCard(
                        selectedDate: $selectedDate,
                        dataManager: dataManager,
                        onTap: { showCalendar = true }
                    )
                    .padding(.horizontal)

                    // 任务列表卡片
                    taskListCard.padding(.horizontal)

                    // 统计
                    if let calc = cachedCalculations {
                        CollapsibleStatisticsBox(isExpanded: $isStatisticsExpanded, calculations: calc)
                            .padding(.horizontal)
                    }

                    // 反思
                    CollapsibleReflectionBox(
                        isExpanded: $isReflectionExpanded,
                        yesterdayPlan: yesterdayDailyReflection?.tomorrowPlans ?? "",
                        todayLearning: Binding(
                            get: { todayDailyReflection?.todayLearnings ?? "" },
                            set: { updateDailyReflection(todayLearnings: $0) }
                        ),
                        tomorrowPlan: Binding(
                            get: { todayDailyReflection?.tomorrowPlans ?? "" },
                            set: { updateDailyReflection(tomorrowPlans: $0) }
                        ),
                        focusedField: $focusedField
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("今日")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 6) {
                        toolbarBtn("sparkles", color: .purple) {
                            focusedField = nil; showingSmartAdd = true
                        }
                        toolbarBtn("plus", color: .blue) {
                            focusedField = nil; showingAddTask = true
                        }
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") { focusedField = nil }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(selectedDate: selectedDate, onSave: {}).environmentObject(dataManager)
            }
            .sheet(isPresented: $showingSmartAdd) {
                SmartAddTaskView(selectedDate: selectedDate, onSave: {}).environmentObject(dataManager)
            }
            .sheet(item: $editingTask) { task in
                EditTaskView(task: task, onSave: {}).environmentObject(dataManager)
            }
            .sheet(isPresented: $showCalendar) {
                EnhancedCalendarView().environmentObject(dataManager)
            }
            .onAppear { updateCachedCalculations(); autoStartLiveActivityIfNeeded() }
            .onChange(of: selectedDate) { _ in updateCachedCalculations() }
            .onReceive(dataManager.$tasks) { _ in updateCachedCalculations(); updateLiveActivity() }
            .onReceive(dataManager.$meals) { _ in updateCachedCalculations() }
        }
    }

    // ── Toolbar 按钮 ────────────────────────────────────────
    private func toolbarBtn(_ icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.1))
                .cornerRadius(8)
        }
    }

    // ── 任务列表卡片 ────────────────────────────────────────
    private var taskListCard: some View {
        VStack(spacing: 0) {
            // 标题行
            HStack(spacing: 6) {
                Text("今日任务")
                    .font(DS.T.sectionHeader)

                if !todayTasks.isEmpty {
                    let done = todayTasks.filter { $0.isCompleted }.count
                    Text("\(done)/\(todayTasks.count)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(DS.blue.opacity(0.75))
                        .cornerRadius(9)
                }

                Spacer()

                HStack(spacing: 7) {
                    headerBtn("sparkles", color: .purple) { showingSmartAdd = true }
                    headerBtn("plus",     color: .blue)   { showingAddTask  = true }
                }
            }
            .padding(.horizontal, DS.padding)
            .padding(.vertical, 12)
            .background(DS.rowBg)

            // 内容
            if todayTasks.isEmpty {
                EmptyStateViewWithSmartAdd(
                    showingAddTask: $showingAddTask,
                    showingSmartAdd: $showingSmartAdd
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(todayTasks.enumerated()), id: \.element.id) { idx, task in
                        // 空隙指示
                        if idx > 0 {
                            let gap = task.startTime.timeIntervalSince(todayTasks[idx-1].endTime)
                            if gap > 60 { TimeGapView(gap: gap) }
                        }
                        TimelineTaskRow(
                            task: task,
                            onToggle: { toggleTaskCompletion(task) },
                            onEdit:   { focusedField = nil; editingTask = task },
                            onDelete: { deleteTask(task) },
                            onPause:  { pauseTask(task) },
                            isCurrentTask: currentTask?.id == task.id
                        )
                        .padding(.horizontal, DS.padding)
                        .padding(.vertical, 5)

                        if idx < todayTasks.count - 1 {
                            Divider()
                                .padding(.leading, DS.padding + 44)
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .background(DS.cardBg)
        .cornerRadius(DS.radius)
        .shadow(color: DS.shadowColor, radius: DS.shadowRadius, x: 0, y: 2)
    }

    private func headerBtn(_ icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 26, height: 26)
                .background(color.opacity(0.1))
                .cornerRadius(7)
        }
    }

    // ── 计算属性 ────────────────────────────────────────────
    var todayTasks: [Task] {
        dataManager.tasks
            .filter { Calendar.current.isDate($0.startTime, inSameDayAs: selectedDate) }
            .sorted { $0.startTime < $1.startTime }
    }
    var yesterdayDailyReflection: DailyReflection? {
        let y = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
        return dataManager.dailyReflections.first { Calendar.current.isDate($0.date, inSameDayAs: y) }
    }
    var todayDailyReflection: DailyReflection? {
        dataManager.dailyReflections.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    var currentTask: Task? {
        let now = Date()
        return todayTasks.first { !$0.isCompleted && $0.startTime <= now && $0.endTime > now }
    }

    // ── 方法 ────────────────────────────────────────────────
    private func updateCachedCalculations() {
        let tasks = todayTasks
        let total = tasks.count, done = tasks.filter { $0.isCompleted }.count
        let pct  = total > 0 ? Int(Double(done)/Double(total)*100) : 0
        let tDur = tasks.reduce(0.0) { $0 + $1.duration }
        let cDur = tasks.filter { $0.isCompleted }.reduce(0.0) { $0 + $1.duration }
        let rev  = tasks.reduce(0.0) { $0 + $1.revenue }
        let exp  = tasks.reduce(0.0) { $0 + $1.expense }
        let brn  = tasks.reduce(0.0) { $0 + $1.caloriesBurned }
        let con  = dataManager.meals
            .filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
            .reduce(0.0) { $0 + $1.calories }
        let cats: [(category: String, duration: Double, percentage: Double)] =
            Dictionary(grouping: tasks) { $0.category }
            .map { k, v in let d = v.reduce(0.0){$0+$1.duration}; return (k, d, tDur>0 ? d/tDur*100 : 0) }
            .sorted { $0.1 > $1.1 }
        cachedCalculations = TodayCalculations(
            totalTasks: total, completedTasks: done, completionPercentage: pct,
            totalDuration: tDur, completedDuration: cDur,
            totalRevenue: rev, totalExpense: exp, netIncome: rev-exp,
            totalCaloriesBurned: brn, totalCaloriesConsumed: con, netCalories: brn-con,
            categoryDurations: cats
        )
    }

    func toggleTaskCompletion(_ task: Task) {
        dataManager.toggleTaskCompletion(task)
        updateCachedCalculations()
        if let id = task.calendarEventId { syncManager.updateTaskInCalendar(eventId: id, task: task) }
        if task.id == currentTask?.id { timerManager.stopTimer() }
    }
    func pauseTask(_ task: Task) {
        if timerManager.isRunning { timerManager.pauseTimer() }
        else if let i = dataManager.tasks.firstIndex(where: { $0.id == task.id }) {
            dataManager.tasks[i].actualStartTime = Date()
            if dataManager.tasks[i].enableWhiteNoise, let s = dataManager.tasks[i].whiteNoiseType {
                whiteNoiseManager.play(noise: s)
            }
            let rem = dataManager.tasks[i].endTime.timeIntervalSince(Date())
            if rem > 0 { timerManager.startTimer(duration: rem) }
            dataManager.saveAllData()
        }
    }
    func deleteTask(_ task: Task) {
        if let id = task.calendarEventId { syncManager.deleteTaskFromCalendar(eventId: id) }
        dataManager.deleteTask(task)
    }
    func updateDailyReflection(todayLearnings: String? = nil, tomorrowPlans: String? = nil) {
        let r = cachedCalculations?.totalRevenue ?? 0
        let e = cachedCalculations?.totalExpense ?? 0
        if let i = dataManager.dailyReflections.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
            if let tl = todayLearnings { dataManager.dailyReflections[i].todayLearnings = tl }
            if let tp = tomorrowPlans  { dataManager.dailyReflections[i].tomorrowPlans  = tp }
            dataManager.dailyReflections[i].totalRevenue = r
            dataManager.dailyReflections[i].totalExpense = e
        } else {
            dataManager.dailyReflections.append(DailyReflection(
                date: selectedDate, overallSummary: "",
                todayLearnings: todayLearnings ?? "", tomorrowPlans: tomorrowPlans ?? "",
                totalRevenue: r, totalExpense: e
            ))
        }
        dataManager.saveAllData()
    }
    private func autoStartLiveActivityIfNeeded() {
        guard #available(iOS 16.1, *) else { return }
        if !hasAutoStartedLiveActivity && !todayTasks.isEmpty {
            LiveActivityManager.shared.start(tasks: todayTasks, mood: "专注", username: "小艺")
            hasAutoStartedLiveActivity = true
        }
    }
    private func updateLiveActivity() {
        guard #available(iOS 16.1, *) else { return }
        if !todayTasks.isEmpty {
            if !hasAutoStartedLiveActivity {
                LiveActivityManager.shared.start(tasks: todayTasks, mood: "专注", username: "小艺")
                hasAutoStartedLiveActivity = true
            } else {
                LiveActivityManager.shared.update(tasks: todayTasks, mood: "专注")
            }
        } else {
            LiveActivityManager.shared.stop()
            hasAutoStartedLiveActivity = false
        }
    }
}

// ============================================================
// MARK: - 进度横幅
// ============================================================
struct TaskProgressBanner: View {
    let completedTasks: Int
    let totalTasks: Int
    let percentage: Int
    private var isDone: Bool { percentage == 100 }
    private var accent: Color { isDone ? DS.green : DS.blue }

    var body: some View {
        HStack(spacing: 14) {
            // 环形进度
            ZStack {
                Circle().stroke(DS.rowBg, lineWidth: 5).frame(width: 44, height: 44)
                Circle()
                    .trim(from: 0, to: CGFloat(percentage)/100)
                    .stroke(accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 44, height: 44)
                    .animation(.easeOut(duration: 0.4), value: percentage)
                Text("\(percentage)%")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(isDone ? "全部完成 🎉" : "今日进度")
                    .font(.system(size: 15, weight: .semibold))
                Text("\(completedTasks) / \(totalTasks) 个任务")
                    .font(DS.T.caption).foregroundColor(.secondary)
            }

            Spacer()

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(DS.rowBg).frame(height: 6)
                    Capsule()
                        .fill(LinearGradient(
                            colors: isDone ? [DS.green, DS.green] : [DS.blue, DS.purple],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * CGFloat(percentage)/100, height: 6)
                        .animation(.easeOut(duration: 0.4), value: percentage)
                }
            }
            .frame(width: 88, height: 6)
        }
        .padding(.horizontal, DS.padding)
        .padding(.vertical, 12)
        .background(DS.cardBg)
        .cornerRadius(DS.radius)
        .shadow(color: DS.shadowColor, radius: DS.shadowRadius, x: 0, y: 2)
    }
}

// ============================================================
// MARK: - 日历入口卡片
// ============================================================
struct CalendarEntryCard: View {
    @Binding var selectedDate: Date
    let dataManager: AppDataManager
    let onTap: () -> Void

    private var weekDays: [Date] {
        let cal = Calendar.current
        let today = Date()
        let wd = cal.component(.weekday, from: today)
        let start = cal.date(byAdding: .day, value: -(wd-1), to: today)!
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }
    private var taskCount: Int {
        dataManager.tasks.filter { Calendar.current.isDate($0.startTime, inSameDayAs: selectedDate) }.count
    }
    private var doneCount: Int {
        dataManager.tasks.filter { Calendar.current.isDate($0.startTime, inSameDayAs: selectedDate) && $0.isCompleted }.count
    }

    private static let dateFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "M月d日 EEEE"; f.locale = Locale(identifier: "zh_CN"); return f
    }()
    private static let dayFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d"; return f
    }()
    private static let wdFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE"; f.locale = Locale(identifier: "zh_CN"); return f
    }()

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 11) {
                // 顶部信息行
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(Self.dateFmt.string(from: selectedDate))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        Text(taskCount > 0 ? "\(doneCount)/\(taskCount) 个任务完成" : "点击查看完整日历")
                            .font(DS.T.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DS.blue)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, DS.paddingS)
                    .padding(.vertical, 6)
                    .background(DS.blue.opacity(0.08))
                    .cornerRadius(8)
                }

                // 本周迷你日历
                HStack(spacing: 0) {
                    ForEach(weekDays, id: \.self) { day in
                        let isSel   = Calendar.current.isDate(day, inSameDayAs: selectedDate)
                        let isToday = Calendar.current.isDateInToday(day)
                        let hasTsk  = dataManager.tasks.contains {
                            Calendar.current.isDate($0.startTime, inSameDayAs: day)
                        }
                        VStack(spacing: 4) {
                            Text(Self.wdFmt.string(from: day))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(isSel ? DS.blue : .secondary)
                            ZStack {
                                Circle()
                                    .fill(isSel ? DS.blue : (isToday ? DS.blue.opacity(0.12) : .clear))
                                    .frame(width: 28, height: 28)
                                Text(Self.dayFmt.string(from: day))
                                    .font(.system(size: 13, weight: isSel || isToday ? .bold : .regular))
                                    .foregroundColor(isSel ? .white : isToday ? DS.blue : .primary)
                            }
                            Circle()
                                .fill(hasTsk ? (isSel ? Color.white : DS.blue.opacity(0.45)) : .clear)
                                .frame(width: 4, height: 4)
                        }
                        .frame(maxWidth: .infinity)
                        .onTapGesture { selectedDate = day }
                    }
                }
            }
            .padding(.horizontal, DS.padding)
            .padding(.vertical, 13)
            .background(DS.cardBg)
            .cornerRadius(DS.radius)
            .shadow(color: DS.shadowColor, radius: DS.shadowRadius, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// ============================================================
// MARK: - 时间轴任务行
// ============================================================
struct TimelineTaskRow: View {
    let task: Task
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onPause: () -> Void
    let isCurrentTask: Bool

    @State private var now = Date()
    @StateObject private var timerManager = TimerManager.shared

    private var progress: Double {
        guard isCurrentTask else { return 0 }
        return min(max(now.timeIntervalSince(task.startTime) / (task.duration * 60), 0), 1)
    }
    private var remaining: String {
        guard isCurrentTask else { return "" }
        let r = task.endTime.timeIntervalSince(now)
        guard r > 0 else { return "已结束" }
        return "\(Int(r/60)):\(String(format:"%02d", Int(r.truncatingRemainder(dividingBy:60))))"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // 时间轴列
            VStack(spacing: 3) {
                Text(fmt(task.startTime))
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(isCurrentTask ? DS.blue : .secondary)
                ZStack {
                    Circle()
                        .fill(isCurrentTask ? DS.blue
                              : task.isCompleted ? DS.green
                              : Color(.systemGray4))
                        .frame(width: 9, height: 9)
                    if task.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 6, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(width: 1.5)
                    .frame(minHeight: 28)
            }
            .frame(width: 42)

            // 任务内容气泡
            VStack(alignment: .leading, spacing: 6) {
                // 标题行
                HStack(alignment: .top) {
                    Button(action: onToggle) {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 19))
                            .foregroundColor(task.isCompleted ? DS.green : Color(.systemGray3))
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(task.title)
                            .font(.system(size: 16, weight: .medium))
                            .strikethrough(task.isCompleted)
                            .foregroundColor(task.isCompleted ? .secondary : .primary)

                        // 标签 chips
                        HStack(spacing: 6) {
                            chip("\(Int(task.duration))分", icon: "clock", color: DS.blue)
                            if !task.category.isEmpty {
                                chip(task.category, icon: "tag", color: DS.purple)
                            }
                            if task.enableWhiteNoise {
                                Image(systemName: "ear.and.waveform")
                                    .font(.system(size: 12))
                                    .foregroundColor(DS.blue)
                            }
                            if task.revenue > 0 || task.expense > 0 {
                                let net = task.revenue - task.expense
                                chip("¥\(String(format:"%.0f",net))", icon: nil,
                                     color: net >= 0 ? DS.green : DS.red)
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }

                // 当前任务：进度 + 控制
                if isCurrentTask && !task.isCompleted {
                    VStack(spacing: 6) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(DS.rowBg).frame(height: 5)
                                Capsule()
                                    .fill(LinearGradient(colors: [DS.blue, DS.purple],
                                                        startPoint: .leading, endPoint: .trailing))
                                    .frame(width: geo.size.width * progress, height: 5)
                            }
                        }
                        .frame(height: 5)

                        HStack {
                            Button(action: onPause) {
                                HStack(spacing: 4) {
                                    Image(systemName: timerManager.isRunning ? "pause.fill" : "play.fill")
                                        .font(.system(size: 12, weight: .bold))
                                    Text(timerManager.isRunning ? "暂停" : "继续")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, DS.paddingS)
                                .padding(.vertical, 5)
                                .background(timerManager.isRunning ? DS.orange : DS.blue)
                                .cornerRadius(7)
                            }
                            Spacer()
                            if !remaining.isEmpty {
                                Text(remaining)
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(DS.blue)
                            }
                        }
                    }
                    .padding(.top, 2)
                }
            }
            .padding(11)
            .background(
                RoundedRectangle(cornerRadius: DS.radius - 2)
                    .fill(isCurrentTask ? DS.blue.opacity(0.07) : DS.rowBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.radius - 2)
                            .stroke(isCurrentTask ? DS.blue.opacity(0.3) : .clear, lineWidth: 1.5)
                    )
            )
            .contentShape(Rectangle())
            .onTapGesture { onEdit() }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive, action: onDelete) { Label("删除", systemImage: "trash") }
            }
            .swipeActions(edge: .leading) {
                Button(action: onEdit) { Label("编辑", systemImage: "pencil") }.tint(DS.blue)
            }
        }
        .onAppear {
            if isCurrentTask {
                if !timerManager.isPaused && !timerManager.isRunning {
                    let r = task.endTime.timeIntervalSince(Date())
                    if r > 0 { timerManager.startTimer(duration: r) }
                }
                tick()
            }
        }
        .onChange(of: isCurrentTask) { if $0 { tick() } }
    }

    @ViewBuilder
    private func chip(_ text: String, icon: String?, color: Color) -> some View {
        HStack(spacing: 3) {
            if let ic = icon {
                Image(systemName: ic).font(.system(size: 11))
            }
            Text(text).font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 7).padding(.vertical, 3)
        .background(color.opacity(0.1))
        .cornerRadius(5)
    }

    private func tick() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            now = Date()
            if !isCurrentTask { t.invalidate() }
        }
    }
    private func fmt(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: d)
    }
}

// ============================================================
// MARK: - 时间间隙
// ============================================================
struct TimeGapView: View {
    let gap: TimeInterval
    private var label: String {
        let m = Int(gap/60)
        if m >= 60 { let h = m/60, r = m%60; return r > 0 ? "\(h)小时\(r)分" : "\(h)小时" }
        return "\(m)分钟"
    }
    var body: some View {
        HStack {
            Color.clear.frame(width: 42)
            HStack(spacing: 4) {
                Image(systemName: "moon.zzz")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Text("空闲 \(label)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, DS.paddingS)
            .padding(.vertical, 4)
            .background(DS.rowBg)
            .cornerRadius(7)
            Spacer()
        }
        .padding(.vertical, 3)
        .padding(.horizontal, DS.padding)
    }
}

// ============================================================
// MARK: - 数据结构
// ============================================================
struct TodayCalculations {
    let totalTasks: Int
    let completedTasks: Int
    let completionPercentage: Int
    let totalDuration: Double
    let completedDuration: Double
    let totalRevenue: Double
    let totalExpense: Double
    let netIncome: Double
    let totalCaloriesBurned: Double
    let totalCaloriesConsumed: Double
    let netCalories: Double
    let categoryDurations: [(category: String, duration: Double, percentage: Double)]
}

// ============================================================
// MARK: - 今日反思
// ============================================================
struct CollapsibleReflectionBox: View {
    @Binding var isExpanded: Bool
    let yesterdayPlan: String
    @Binding var todayLearning: String
    @Binding var tomorrowPlan: String
    @FocusState.Binding var focusedField: TodayView.ReflectionField?

    var body: some View {
        VStack(spacing: 0) {
            // 标题行
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DS.orange)
                    Text("今日反思")
                        .font(DS.T.sectionHeader)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, DS.padding)
                .padding(.vertical, 13)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 12) {
                    if !yesterdayPlan.isEmpty {
                        readBlock(
                            title: "昨日计划回顾", icon: "clock.arrow.circlepath",
                            iconColor: .secondary, content: yesterdayPlan
                        )
                    }
                    writeBlock(
                        title: "今日学习与收获", icon: "book.fill", iconColor: DS.green,
                        placeholder: "记录今天的收获和感悟...",
                        text: $todayLearning, field: .today
                    )
                    writeBlock(
                        title: "明日计划安排", icon: "calendar.badge.plus", iconColor: DS.blue,
                        placeholder: "规划明天的任务和目标...",
                        text: $tomorrowPlan, field: .tomorrow
                    )
                }
                .padding(.horizontal, DS.padding)
                .padding(.bottom, DS.padding)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(DS.cardBg)
        .cornerRadius(DS.radius)
        .shadow(color: DS.shadowColor, radius: DS.shadowRadius, x: 0, y: 2)
    }

    private func readBlock(title: String, icon: String, iconColor: Color, content: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            blockLabel(title, icon: icon, color: iconColor)
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func writeBlock(title: String, icon: String, iconColor: Color,
                            placeholder: String, text: Binding<String>,
                            field: TodayView.ReflectionField) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            blockLabel(title, icon: icon, color: iconColor)
            ZStack(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 14))
                        .foregroundColor(Color(.placeholderText))
                        .padding(.top, 9).padding(.leading, 5)
                }
                TextEditor(text: text)
                    .font(.system(size: 14))
                    .frame(minHeight: 64)
                    .focused($focusedField, equals: field)
            }
            .padding(9)
            .background(DS.rowBg)
            .cornerRadius(DS.radius - 2)
            .overlay(
                RoundedRectangle(cornerRadius: DS.radius - 2)
                    .stroke(focusedField == field ? DS.blue.opacity(0.4) : .clear, lineWidth: 1.5)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func blockLabel(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 11)).foregroundColor(color)
            Text(title).font(DS.T.micro).foregroundColor(.secondary)
        }
    }
}

// 保留旧名兼容
struct ReflectionSection: View {
    let title: String; let content: String; let icon: String; let iconColor: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 11)).foregroundColor(iconColor)
                Text(title).font(DS.T.micro).foregroundColor(.secondary)
            }
            Text(content).font(.system(size: 14)).foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ReflectionInputSection: View {
    let title: String; let placeholder: String
    @Binding var text: String
    let icon: String; let iconColor: Color
    @FocusState.Binding var focusedField: TodayView.ReflectionField?
    let fieldType: TodayView.ReflectionField
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 11)).foregroundColor(iconColor)
                Text(title).font(DS.T.micro).foregroundColor(.secondary)
            }
            TextEditor(text: $text)
                .font(.system(size: 14))
                .frame(minHeight: 64)
                .padding(9).background(DS.rowBg)
                .cornerRadius(DS.radius - 2)
                .overlay(RoundedRectangle(cornerRadius: DS.radius-2).stroke(Color(.systemGray4), lineWidth: 1))
                .focused($focusedField, equals: fieldType)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
