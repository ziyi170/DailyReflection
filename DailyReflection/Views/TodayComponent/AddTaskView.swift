import SwiftUI

struct AddTaskView: View {
    @EnvironmentObject var dataManager: AppDataManager
    @StateObject private var whiteNoiseManager = WhiteNoiseManager.shared

    let selectedDate: Date
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var startTime = Date()

    // ✅ duration 统一改成 “分钟”
    @State private var duration: Double = 30

    @State private var enableWhiteNoise = false
    @State private var selectedSound: WhiteNoiseType = .rain

    // 🆕 收入和支出
    @State private var revenue = ""
    @State private var expense = ""
    @State private var category = "其他"
    @State private var notes = ""

    // 🆕 键盘控制
    @FocusState private var focusedField: Field?

    // 🆕 是否使用上一个任务的结束时间
    @State private var useLastTaskEndTime = false

    enum Field: Hashable {
        case title, revenue, expense, notes
    }

    let categories = ["工作", "学习", "健身", "娱乐", "其他"]

    // 🆕 上一个任务的结束时间（如果存在）
    var lastTaskEndTime: Date? {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: selectedDate)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        let todayTasks = dataManager.tasks.filter { task in
            task.startTime >= dayStart && task.startTime < dayEnd
        }.sorted { $0.startTime < $1.startTime }

        if let lastTask = todayTasks.last {
            return lastTask.endTime
        }
        return nil
    }

    init(selectedDate: Date, onSave: @escaping () -> Void) {
        self.selectedDate = selectedDate
        self.onSave = onSave

        _startTime = State(initialValue: Self.roundToNextHalfHour(selectedDate))
    }

    static func roundToNextHalfHour(_ date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let minute = components.minute ?? 0

        let roundedMinute = minute <= 30 ? 30 : 60
        let hourAdd = roundedMinute == 60 ? 1 : 0

        components.hour = (components.hour ?? 0) + hourAdd
        components.minute = roundedMinute == 60 ? 0 : roundedMinute
        components.second = 0

        return calendar.date(from: components) ?? date
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("任务信息")) {
                    TextField("任务名称", text: $title)
                        .focused($focusedField, equals: .title)

                    Picker("分类", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }

                    // 🆕 时间选择区域
                    VStack(alignment: .leading, spacing: 12) {
                        if let lastEndTime = lastTaskEndTime {
                            Toggle("从上一个任务结束时间开始 (\(timeString(lastEndTime)))", isOn: $useLastTaskEndTime)
                                .onChange(of: useLastTaskEndTime) { _, newValue in
                                    if newValue {
                                        startTime = lastEndTime
                                    } else {
                                        startTime = Self.roundToNextHalfHour(selectedDate)
                                    }
                                }
                        }

                        DatePicker("开始时间", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                            .disabled(useLastTaskEndTime && lastTaskEndTime != nil)

                        if useLastTaskEndTime {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.blue)

                                Text("已自动接续上一任务")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Spacer()

                                Button("调整时间") {
                                    useLastTaskEndTime = false
                                }
                                .font(.caption2)
                                .foregroundColor(.blue)
                            }
                        }
                    }

                    // ✅ 时长设置（分钟单位）
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("预计时长: \(Int(duration)) 分钟")
                                .font(.subheadline)
                            Spacer()
                            Text("结束: \(endTimeString)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        // 15~240 分钟
                        Slider(value: $duration, in: 15...240, step: 15)
                    }

                    TextField("备注（可选）", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                        .focused($focusedField, equals: .notes)
                }

                // 🆕 收入支出部分
                Section(header: Text("财务")) {
                    HStack {
                        Text("收入")
                            .foregroundColor(.green)
                            .frame(width: 60, alignment: .leading)
                        Text("¥")
                            .foregroundColor(.secondary)
                        TextField("预期收入", text: $revenue)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .revenue)
                    }

                    HStack {
                        Text("支出")
                            .foregroundColor(.red)
                            .frame(width: 60, alignment: .leading)
                        Text("¥")
                            .foregroundColor(.secondary)
                        TextField("预期支出", text: $expense)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .expense)
                    }

                    if !revenue.isEmpty || !expense.isEmpty {
                        let revenueValue = Double(revenue) ?? 0.0
                        let expenseValue = Double(expense) ?? 0.0
                        let net = revenueValue - expenseValue

                        HStack {
                            Text("净收入")
                                .fontWeight(.semibold)
                            Spacer()
                            Text("¥\(String(format: "%.2f", net))")
                                .fontWeight(.bold)
                                .foregroundColor(net >= 0 ? .green : .red)
                        }
                    }
                }

                Section(header: Text("白噪音")) {
                    Toggle("启用白噪音", isOn: $enableWhiteNoise)

                    if enableWhiteNoise {
                        Picker("选择音效", selection: $selectedSound) {
                            ForEach(WhiteNoiseType.allCases, id: \.self) { sound in
                                HStack {
                                    Image(systemName: sound.icon)
                                    Text(sound.displayName)
                                    if !sound.isFree {
                                        Image(systemName: "crown.fill")
                                            .font(.caption)
                                            .foregroundColor(.yellow)
                                    }
                                }
                                .tag(sound)
                            }
                        }

                        Button(action: {
                            whiteNoiseManager.toggle(noise: selectedSound)
                        }) {
                            HStack {
                                Image(systemName: whiteNoiseManager.isPlaying && whiteNoiseManager.currentNoise == selectedSound ? "stop.circle.fill" : "play.circle.fill")
                                Text(whiteNoiseManager.isPlaying && whiteNoiseManager.currentNoise == selectedSound ? "停止试听" : "试听")
                            }
                        }

                        if whiteNoiseManager.isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("加载中...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if let error = whiteNoiseManager.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("添加任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        whiteNoiseManager.stop()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        addTask()
                    }
                    .disabled(title.isEmpty)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") {
                        focusedField = nil
                    }
                }
            }
            .onDisappear {
                whiteNoiseManager.stop()
            }
            .onAppear {
                if let lastEndTime = lastTaskEndTime {
                    useLastTaskEndTime = true
                    startTime = lastEndTime
                }
            }
        }
    }

    // ✅ endTimeString 要用 duration(分钟) → 秒
    var endTimeString: String {
        let endTime = startTime.addingTimeInterval(duration * 60)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: endTime)
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    // ✅ 改完后的添加任务（统一走 dataManager.addTask）
    func addTask() {
        let revenueValue = Double(revenue) ?? 0.0
        let expenseValue = Double(expense) ?? 0.0

        // ✅ 存进去的 duration 就是分钟
        let newTask = Task(
            title: title,
            startTime: startTime,
            duration: duration,
            isCompleted: false,
            notes: notes,
            reflectionNotes: "",
            category: category,
            revenue: revenueValue,
            expense: expenseValue,
            enableWhiteNoise: enableWhiteNoise,
            whiteNoiseType: enableWhiteNoise ? selectedSound : nil
        )

        // ✅ 关键：统一入口（会同步日历 + Widget + Live Activity + 保存）
        dataManager.addTask(newTask)//连贯点

        whiteNoiseManager.stop()
        onSave()
        dismiss()
    }
}
