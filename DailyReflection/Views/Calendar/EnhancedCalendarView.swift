//
//  EnhancedCalendarView.swift
//  DailyReflection
//
//  ✅ 内嵌在 TodayView 同层 | 去掉财务 | 复盘同步 | 添加任务正常
//

import SwiftUI

// MARK: - 内嵌日历容器（供 TodayView 直接使用，不用 sheet）

struct InlineCalendarView: View {
    @EnvironmentObject var dataManager: AppDataManager
    @Binding var selectedDate: Date
    @Binding var showingAddTask: Bool

    @State private var currentMonth = Date()
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // 标题行：点击展开/收起日历
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "calendar").foregroundColor(.blue)
                    Text(formattedDate(selectedDate))
                        .font(.headline).foregroundColor(.primary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray).font(.caption)
                }
                .padding()
                .background(Color(.systemGray6))
            }

            if isExpanded {
                VStack(spacing: 0) {
                    MonthSelector(currentMonth: $currentMonth)
                    CalendarGrid(
                        currentMonth: currentMonth,
                        selectedDate: $selectedDate,
                        dataManager: dataManager
                    )
                    Divider()
                    SelectedDayDetail(
                        selectedDate: selectedDate,
                        showingAddTask: $showingAddTask,
                        dataManager: dataManager
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "M月d日 EEEE"
        f.locale = Locale(identifier: "zh_CN")
        return f.string(from: date)
    }
}

// MARK: - 所选日期详情

struct SelectedDayDetail: View {
    let selectedDate: Date
    @Binding var showingAddTask: Bool
    let dataManager: AppDataManager

    private var selectedDateEvents: CalendarEvent {
        dataManager.getEventsForDate(selectedDate)
    }
    private var canAddTask: Bool {
        Calendar.current.startOfDay(for: selectedDate) >= Calendar.current.startOfDay(for: Date())
    }
    private var isFutureDate: Bool {
        Calendar.current.startOfDay(for: selectedDate) > Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Text(formattedDate(selectedDate)).font(.subheadline).fontWeight(.bold)
                    dateLabel
                }
                Spacer()
                if canAddTask {
                    Button(action: { showingAddTask = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill").font(.subheadline)
                            Text("添加任务").font(.caption).fontWeight(.semibold)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.blue.opacity(0.1)).cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal).padding(.vertical, 12)

            Divider().padding(.horizontal)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if !selectedDateEvents.tasks.isEmpty { taskSection }
                    if !selectedDateEvents.tasks.isEmpty { taskStatsSection }

                    let burned = selectedDateEvents.tasks.reduce(0.0) { $0 + $1.caloriesBurned }
                    if burned > 0 {
                        DaySummaryCard(
                            title: "卡路里消耗", icon: "flame.fill", color: .red,
                            value: "\(Int(burned)) 卡",
                            subtitle: "来自 \(selectedDateEvents.tasks.filter { $0.caloriesBurned > 0 }.count) 个任务"
                        )
                    }

                    if !selectedDateEvents.meals.isEmpty {
                        DaySummaryCard(
                            title: "饮食摄入", icon: "fork.knife.circle.fill", color: .orange,
                            value: "\(Int(selectedDateEvents.totalCalories)) 卡",
                            subtitle: "共 \(selectedDateEvents.meals.count) 次进食"
                        )
                    }

                    if let weight = selectedDateEvents.weight {
                        DaySummaryCard(
                            title: "体重记录", icon: "scalemass.fill", color: .blue,
                            value: "\(String(format: "%.1f", weight.weight)) kg",
                            subtitle: weight.note.isEmpty ? "已记录" : weight.note
                        )
                    }

                    if !isFutureDate { reflectionSection }

                    if selectedDateEvents.tasks.isEmpty && selectedDateEvents.meals.isEmpty && selectedDateEvents.weight == nil {
                        emptyState
                    }
                }
                .padding(.vertical, 12)
            }
            .frame(maxHeight: 400)
        }
    }

    private var taskSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "list.bullet.circle.fill").foregroundColor(.blue)
                Text(isFutureDate ? "计划任务" : "任务清单").font(.subheadline).fontWeight(.semibold)
                Spacer()
                Text("\(selectedDateEvents.completedTaskCount)/\(selectedDateEvents.tasks.count)")
                    .font(.caption).foregroundColor(.secondary)
            }
            .padding(.horizontal)
            ForEach(selectedDateEvents.tasks) { task in
                CalendarTaskRow(task: task).padding(.horizontal)
            }
        }
    }

    private var taskStatsSection: some View {
        DaySummaryCard(
            title: "任务统计", icon: "checkmark.circle.fill", color: .green,
            value: "\(selectedDateEvents.completedTaskCount)/\(selectedDateEvents.tasks.count) 完成",
            subtitle: "时长: \(Int(selectedDateEvents.completedDuration))/\(Int(selectedDateEvents.totalDuration)) 分钟"
        )
    }

    @ViewBuilder
    private var reflectionSection: some View {
        let r = dataManager.dailyReflections.first {
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }
        if let r = r, (!r.todayLearnings.isEmpty || !r.tomorrowPlans.isEmpty) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "book.circle.fill").foregroundColor(.purple)
                    Text("今日复盘").font(.subheadline).fontWeight(.semibold)
                }
                .padding(.horizontal)
                VStack(alignment: .leading, spacing: 8) {
                    if !r.todayLearnings.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("今日收获", systemImage: "book.fill").font(.caption).foregroundColor(.green)
                            Text(r.todayLearnings).font(.callout)
                        }
                    }
                    if !r.tomorrowPlans.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("明日计划", systemImage: "calendar.badge.plus").font(.caption).foregroundColor(.blue)
                            Text(r.tomorrowPlans).font(.callout)
                        }
                    }
                }
                .padding()
                .background(Color.purple.opacity(0.05))
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: canAddTask ? "calendar.badge.plus" : "calendar")
                .font(.system(size: 36)).foregroundColor(.gray)
            Text(canAddTask ? "暂无记录，点击添加任务" : "暂无记录")
                .font(.subheadline).foregroundColor(.secondary)
            if canAddTask {
                Button(action: { showingAddTask = true }) {
                    Text("添加第一个任务")
                        .font(.caption).fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Color.blue).cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, 24)
    }

    @ViewBuilder
    private var dateLabel: some View {
        if Calendar.current.isDateInToday(selectedDate) {
            Text("今天").font(.caption2).foregroundColor(.blue)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Color.blue.opacity(0.1)).cornerRadius(4)
        } else if isFutureDate {
            Text("未来").font(.caption2).foregroundColor(.green)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Color.green.opacity(0.1)).cornerRadius(4)
        } else {
            Text("过去").font(.caption2).foregroundColor(.secondary)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Color(.systemGray5)).cornerRadius(4)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "M月d日 EEEE"; f.locale = Locale(identifier: "zh_CN")
        return f.string(from: date)
    }
}

// MARK: - 日历任务行

struct CalendarTaskRow: View {
    let task: Task

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? .green : .gray).font(.subheadline)
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title).font(.subheadline).fontWeight(.medium)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                HStack(spacing: 8) {
                    Label(timeStr(task.startTime), systemImage: "clock")
                        .font(.caption2).foregroundColor(.secondary)
                    Label("\(Int(task.duration))分", systemImage: "hourglass")
                        .font(.caption2).foregroundColor(.secondary)
                    if !task.category.isEmpty {
                        Label(task.category, systemImage: "tag")
                            .font(.caption2).foregroundColor(.secondary)
                    }
                }
            }
            Spacer()
            if task.caloriesBurned > 0 {
                Label("\(Int(task.caloriesBurned))卡", systemImage: "flame.fill")
                    .font(.caption2).foregroundColor(.red)
            }
        }
        .padding(.vertical, 8).padding(.horizontal, 12)
        .background(Color(.systemGray6)).cornerRadius(8)
    }

    private func timeStr(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: date)
    }
}

// MARK: - 独立弹出式日历

struct EnhancedCalendarView: View {
    @EnvironmentObject var dataManager: AppDataManager
    @Environment(\.dismiss) var dismiss

    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var showingAddTask = false

    private var selectedDateEvents: CalendarEvent { dataManager.getEventsForDate(selectedDate) }
    private var canAddTask: Bool {
        Calendar.current.startOfDay(for: selectedDate) >= Calendar.current.startOfDay(for: Date())
    }
    private var isFutureDate: Bool {
        Calendar.current.startOfDay(for: selectedDate) > Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                MonthSelector(currentMonth: $currentMonth)
                CalendarGrid(currentMonth: currentMonth, selectedDate: $selectedDate, dataManager: dataManager)
                Divider()
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        dateHeaderSection
                        taskListSection
                        taskStatisticsSection
                        calorieSection
                        weightSection
                        mealDetailsSection
                        reflectionSection
                        emptyStateSection
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("日历").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button("完成") { dismiss() } }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(selectedDate: selectedDate, onSave: {}).environmentObject(dataManager)
            }
        }
    }

    @ViewBuilder private var dateHeaderSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(fmtDate(selectedDate)).font(.title2).fontWeight(.bold)
                if Calendar.current.isDateInToday(selectedDate) {
                    Text("今天").font(.caption).foregroundColor(.blue)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1)).cornerRadius(4)
                } else if isFutureDate {
                    Text("未来").font(.caption).foregroundColor(.green)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Color.green.opacity(0.1)).cornerRadius(4)
                } else {
                    Text("过去").font(.caption).foregroundColor(.secondary)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Color(.systemGray5)).cornerRadius(4)
                }
            }
            Spacer()
            if canAddTask {
                Button(action: { showingAddTask = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill").font(.title3)
                        Text("添加任务").font(.subheadline).fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1)).cornerRadius(8)
                }
            }
        }
        .padding(.horizontal).padding(.top)
    }

    @ViewBuilder private var taskListSection: some View {
        if !selectedDateEvents.tasks.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "list.bullet.circle.fill").foregroundColor(.blue)
                    Text(isFutureDate ? "计划任务" : "任务清单").font(.headline)
                    Spacer()
                    Text("\(selectedDateEvents.completedTaskCount)/\(selectedDateEvents.tasks.count)")
                        .font(.caption).foregroundColor(.secondary)
                }
                .padding(.horizontal)
                ForEach(selectedDateEvents.tasks) { task in CalendarTaskRow(task: task).padding(.horizontal) }
            }
        }
    }

    @ViewBuilder private var taskStatisticsSection: some View {
        if !selectedDateEvents.tasks.isEmpty {
            DaySummaryCard(
                title: "任务统计", icon: "checkmark.circle.fill", color: .green,
                value: "\(selectedDateEvents.completedTaskCount)/\(selectedDateEvents.tasks.count) 完成",
                subtitle: "时长: \(Int(selectedDateEvents.completedDuration))/\(Int(selectedDateEvents.totalDuration)) 分钟"
            )
        }
    }

    @ViewBuilder private var calorieSection: some View {
        let burned = selectedDateEvents.tasks.reduce(0.0) { $0 + $1.caloriesBurned }
        if burned > 0 {
            DaySummaryCard(title: "卡路里消耗", icon: "flame.fill", color: .red,
                value: "\(Int(burned)) 卡",
                subtitle: "来自 \(selectedDateEvents.tasks.filter { $0.caloriesBurned > 0 }.count) 个任务")
        }
        if !selectedDateEvents.meals.isEmpty {
            DaySummaryCard(title: "饮食摄入", icon: "fork.knife.circle.fill", color: .orange,
                value: "\(Int(selectedDateEvents.totalCalories)) 卡",
                subtitle: "共 \(selectedDateEvents.meals.count) 次进食")
        }
    }

    @ViewBuilder private var weightSection: some View {
        if let w = selectedDateEvents.weight {
            DaySummaryCard(title: "体重记录", icon: "scalemass.fill", color: .blue,
                value: "\(String(format: "%.1f", w.weight)) kg",
                subtitle: w.note.isEmpty ? "已记录" : w.note)
        }
    }

    @ViewBuilder private var mealDetailsSection: some View {
        if !selectedDateEvents.meals.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "fork.knife.circle.fill").foregroundColor(.orange)
                    Text("饮食详情").font(.headline)
                }
                .padding(.horizontal)
                ForEach(MealEntry.MealType.allCases, id: \.self) { type in
                    let meals = selectedDateEvents.meals.filter { $0.mealType == type }
                    if !meals.isEmpty { MealTypeSection(type: type, meals: meals).padding(.horizontal) }
                }
            }
        }
    }

    @ViewBuilder private var reflectionSection: some View {
        if !isFutureDate {
            let r = dataManager.dailyReflections.first {
                Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
            }
            if let r = r, (!r.todayLearnings.isEmpty || !r.tomorrowPlans.isEmpty) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "book.circle.fill").foregroundColor(.purple)
                        Text("今日复盘").font(.headline)
                    }
                    .padding(.horizontal)
                    VStack(alignment: .leading, spacing: 10) {
                        if !r.todayLearnings.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("今日收获", systemImage: "book.fill").font(.caption).foregroundColor(.green)
                                Text(r.todayLearnings).font(.callout)
                            }
                        }
                        if !r.tomorrowPlans.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("明日计划", systemImage: "calendar.badge.plus").font(.caption).foregroundColor(.blue)
                                Text(r.tomorrowPlans).font(.callout)
                            }
                        }
                    }
                    .padding()
                    .background(Color.purple.opacity(0.05))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
            }
        }
    }

    @ViewBuilder private var emptyStateSection: some View {
        if selectedDateEvents.tasks.isEmpty && selectedDateEvents.meals.isEmpty && selectedDateEvents.weight == nil {
            VStack(spacing: 14) {
                Image(systemName: canAddTask ? "calendar.badge.plus" : "calendar")
                    .font(.system(size: 44)).foregroundColor(.gray)
                Text(canAddTask ? "还没有任何记录" : "暂无记录").font(.headline).foregroundColor(.secondary)
                if canAddTask {
                    Button(action: { showingAddTask = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("添加第一个任务")
                        }
                        .font(.subheadline).fontWeight(.medium).foregroundColor(.white)
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(Color.blue).cornerRadius(10)
                    }
                }
            }
            .frame(maxWidth: .infinity).padding(.vertical, 40)
        }
    }

    private func fmtDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "M月d日 EEEE"; f.locale = Locale(identifier: "zh_CN")
        return f.string(from: date)
    }
}

// MARK: - 饮食组件

struct MealTypeSection: View {
    let type: MealEntry.MealType
    let meals: [MealEntry]
    private var totalCalories: Double { meals.reduce(0) { $0 + $1.calories } }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(type.rawValue, systemImage: type.icon).font(.subheadline).foregroundColor(.secondary)
                Spacer()
                Text("\(Int(totalCalories)) 卡").font(.caption).fontWeight(.semibold).foregroundColor(.orange)
            }
            ForEach(meals) { meal in
                HStack {
                    Text(meal.name).font(.callout)
                    Spacer()
                    Text("\(Int(meal.calories)) 卡").font(.caption).foregroundColor(.orange)
                }
            }
        }
        .padding().background(Color(.systemGray6)).cornerRadius(8)
    }
}

// MARK: - 月份选择器

struct MonthSelector: View {
    @Binding var currentMonth: Date
    private var monthYearString: String {
        let f = DateFormatter(); f.dateFormat = "yyyy年 M月"; f.locale = Locale(identifier: "zh_CN")
        return f.string(from: currentMonth)
    }
    var body: some View {
        HStack {
            Button(action: { if let d = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) { currentMonth = d } }) {
                Image(systemName: "chevron.left").font(.title3)
            }
            Spacer()
            Text(monthYearString).font(.headline)
            Spacer()
            Button(action: { if let d = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) { currentMonth = d } }) {
                Image(systemName: "chevron.right").font(.title3)
            }
        }
        .padding()
    }
}

// MARK: - 日历网格

struct CalendarGrid: View {
    let currentMonth: Date
    @Binding var selectedDate: Date
    let dataManager: AppDataManager
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]

    private var daysInMonth: [Date?] {
        var days: [Date?] = []
        let cal = Calendar.current
        let firstDay = cal.date(from: cal.dateComponents([.year, .month], from: currentMonth))!
        let firstWeekday = cal.component(.weekday, from: firstDay)
        for _ in 1..<firstWeekday { days.append(nil) }
        let range = cal.range(of: .day, in: .month, for: currentMonth)!
        for day in range {
            if let d = cal.date(byAdding: .day, value: day - 1, to: firstDay) { days.append(d) }
        }
        return days
    }

    var body: some View {
        VStack(spacing: 8) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekdays, id: \.self) { wd in
                    Text(wd).font(.caption).foregroundColor(.secondary).frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(daysInMonth.indices, id: \.self) { i in
                    if let date = daysInMonth[i] {
                        DayCell(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            hasData: !dataManager.getEventsForDate(date).tasks.isEmpty ||
                                     !dataManager.getEventsForDate(date).meals.isEmpty
                        )
                        .onTapGesture { selectedDate = date }
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 日期单元格

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let hasData: Bool
    private static let dayFmt: DateFormatter = { let f = DateFormatter(); f.dateFormat = "d"; return f }()
    private var day: String { Self.dayFmt.string(from: date) }
    private var isToday: Bool { Calendar.current.isDateInToday(date) }

    var body: some View {
        VStack(spacing: 2) {
            Text(day).font(.system(size: 16)).fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(isSelected ? .white : isToday ? .blue : .primary)
            if hasData {
                Circle().fill(isSelected ? Color.white : Color.orange).frame(width: 4, height: 4)
            }
        }
        .frame(maxWidth: .infinity).frame(height: 40)
        .background(isSelected ? Color.blue : isToday ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}

// MARK: - 汇总卡片

struct DaySummaryCard: View {
    let title: String
    let icon: String
    let color: Color
    let value: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon).font(.title).foregroundColor(color)
                .frame(width: 50, height: 50).background(color.opacity(0.1)).cornerRadius(10)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.caption).foregroundColor(.secondary)
                Text(value).font(.title3).fontWeight(.bold).foregroundColor(color)
                Text(subtitle).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding().background(color.opacity(0.05)).cornerRadius(12).padding(.horizontal)
    }
}
