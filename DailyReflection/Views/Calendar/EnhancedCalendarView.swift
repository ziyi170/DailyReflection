//
//  EnhancedCalendarView.swift (Updated)
//  DailyReflection
//
//  ✅ 添加财务统计 | 卡路里自动计算 | 保留所有原有功能
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

// MARK: - 所选日期详情（增强版：添加财务数据）

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

                    // ✅ 财务统计卡片
                    if hasFinanceData {
                        financeSummaryCard
                    }

                    // ✅ 卡路里统计卡片
                    if hasCalorieData {
                        caloriesSummaryCard
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

    // ✅ 财务数据检查
    private var hasFinanceData: Bool {
        let totalRevenue = selectedDateEvents.tasks.reduce(0.0) { $0 + $1.revenue }
        let totalExpense = selectedDateEvents.tasks.reduce(0.0) { $0 + $1.expense }
        return totalRevenue > 0 || totalExpense > 0
    }

    // ✅ 卡路里数据检查
    private var hasCalorieData: Bool {
        let burned = selectedDateEvents.tasks.reduce(0.0) { $0 + $1.caloriesBurned }
        return burned > 0
    }

    // ✅ 财务总结卡片
    private var financeSummaryCard: some View {
        let totalRevenue = selectedDateEvents.tasks.reduce(0.0) { $0 + $1.revenue }
        let totalExpense = selectedDateEvents.tasks.reduce(0.0) { $0 + $1.expense }
        let netIncome = totalRevenue - totalExpense
        
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "yensign.circle.fill").foregroundColor(.green)
                Text("财务统计").font(.subheadline).fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal).padding(.vertical, 12)
            
            Divider().padding(.horizontal)
            
            HStack(spacing: 0) {
                financeMetric(label: "收入", value: "¥\(String(format: "%.0f", totalRevenue))", color: .green)
                Divider().frame(height: 38).padding(.horizontal, 12)
                financeMetric(label: "支出", value: "¥\(String(format: "%.0f", totalExpense))", color: .red)
                Spacer()
            }
            .padding(.horizontal).padding(.vertical, 10)
            
            Divider().padding(.horizontal)
            
            HStack {
                Text("净收入")
                    .font(.subheadline).fontWeight(.semibold)
                Spacer()
                Text("¥\(String(format: "%.2f", netIncome))")
                    .font(.body).fontWeight(.bold)
                    .foregroundColor(netIncome >= 0 ? .green : .red)
            }
            .padding().background(Color(.systemGray6)).cornerRadius(8)
            .padding(.horizontal).padding(.vertical, 10)
        }
        .background(Color(.systemBackground)).cornerRadius(12).padding(.horizontal)
    }

    // ✅ 卡路里总结卡片
    private var caloriesSummaryCard: some View {
        let burned = selectedDateEvents.tasks.reduce(0.0) { $0 + $1.caloriesBurned }
        let consumed = selectedDateEvents.totalCalories
        let net = burned - consumed
        
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "flame.fill").foregroundColor(.orange)
                Text("卡路里统计").font(.subheadline).fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal).padding(.vertical, 12)
            
            Divider().padding(.horizontal)
            
            HStack(spacing: 0) {
                calorieMetric(label: "消耗", value: "\(Int(burned))", unit: "卡", color: .orange)
                Divider().frame(height: 38).padding(.horizontal, 12)
                calorieMetric(label: "摄入", value: "\(Int(consumed))", unit: "卡", color: .green)
                Spacer()
            }
            .padding(.horizontal).padding(.vertical, 10)
            
            Divider().padding(.horizontal)
            
            HStack {
                Text("净消耗")
                    .font(.subheadline).fontWeight(.semibold)
                Spacer()
                Text("\(Int(net)) 卡")
                    .font(.body).fontWeight(.bold)
                    .foregroundColor(net >= 0 ? .blue : .gray)
            }
            .padding().background(Color(.systemGray6)).cornerRadius(8)
            .padding(.horizontal).padding(.vertical, 10)
        }
        .background(Color(.systemBackground)).cornerRadius(12).padding(.horizontal)
    }

    // 财务指标项
    private func financeMetric(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundColor(.secondary)
            Text(value).font(.headline).foregroundColor(color)
        }
    }

    // 卡路里指标项
    private func calorieMetric(label: String, value: String, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value).font(.headline).foregroundColor(color)
                Text(unit).font(.caption).foregroundColor(.secondary)
            }
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
                .padding().background(Color(.systemGray6)).cornerRadius(8)
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
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

    private var dateLabel: some View {
        let isToday = Calendar.current.isDateInToday(selectedDate)
        let text = isToday ? "今天" : Calendar.current.isDateInYesterday(selectedDate) ? "昨天" : ""
        
        return Group {
            if !text.isEmpty {
                Text(text)
                    .font(.caption).fontWeight(.semibold)
                    .foregroundColor(isToday ? .blue : .gray)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(isToday ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .cornerRadius(6)
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "M月d日 EEEE"
        f.locale = Locale(identifier: "zh_CN")
        return f.string(from: date)
    }
}

// MARK: - 其他组件保持原样...

struct CalendarTaskRow: View {
    let task: DailyTask
    private var timeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: task.startTime))-\(formatter.string(from: task.endTime))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                Text(task.title)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                Spacer()
                if task.revenue > 0 || task.expense > 0 {
                    let net = task.revenue - task.expense
                    Text("¥\(String(format: "%.0f", net))")
                        .font(.caption).fontWeight(.semibold)
                        .foregroundColor(net >= 0 ? .green : .red)
                }
            }
            HStack(spacing: 10) {
                Text(timeRange).font(.caption).foregroundColor(.secondary)
                if !task.category.isEmpty {
                    Text("·").foregroundColor(.secondary)
                    Text(task.category).font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

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