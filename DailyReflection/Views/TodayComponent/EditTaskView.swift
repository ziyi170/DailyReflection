import SwiftUI

struct EditTaskView: View {
    @EnvironmentObject var dataManager: AppDataManager
    @StateObject private var whiteNoiseManager = WhiteNoiseManager.shared

    let task: Task
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss

    @State private var title: String
    @State private var startTime: Date
    @State private var duration: Double   // ✅ 统一：分钟
    @State private var revenue: String
    @State private var expense: String
    @State private var caloriesBurned: String
    @State private var category: String
    @State private var notes: String

    @State private var enableWhiteNoise: Bool
    @State private var selectedSound: WhiteNoiseType

    @State private var showDeleteAlert = false

    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case title, revenue, expense, calories, notes
    }

    let categories = ["工作", "学习", "健身", "娱乐", "其他"]

    init(task: Task, onSave: @escaping () -> Void) {
        self.task = task
        self.onSave = onSave

        _title = State(initialValue: task.title)
        _startTime = State(initialValue: task.startTime)

        // ✅ Task.duration 已经是分钟：这里不要 /60
        _duration = State(initialValue: task.duration)

        _revenue = State(initialValue: task.revenue > 0 ? String(format: "%.2f", task.revenue) : "")
        _expense = State(initialValue: task.expense > 0 ? String(format: "%.2f", task.expense) : "")
        _caloriesBurned = State(initialValue: task.caloriesBurned > 0 ? String(format: "%.0f", task.caloriesBurned) : "")
        _category = State(initialValue: task.category)
        _notes = State(initialValue: task.notes)

        _enableWhiteNoise = State(initialValue: task.enableWhiteNoise)
        _selectedSound = State(initialValue: task.whiteNoiseType ?? .rain)
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

                    DatePicker("开始时间", selection: $startTime, displayedComponents: [.date, .hourAndMinute])

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("预计时长: \(Int(duration)) 分钟")
                                .font(.subheadline)
                            Spacer()
                            Text("结束: \(endTimeString)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        // ✅ Slider 也是分钟
                        Slider(value: $duration, in: 15...240, step: 15)
                    }

                    TextField("备注", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                        .focused($focusedField, equals: .notes)
                }

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

                Section(header: Text("健康")) {
                    HStack {
                        Text("消耗")
                            .foregroundColor(.orange)
                            .frame(width: 60, alignment: .leading)
                        TextField("卡路里消耗", text: $caloriesBurned)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .calories)
                        Text("卡")
                            .foregroundColor(.secondary)
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
                                Image(systemName: whiteNoiseManager.isPlaying && whiteNoiseManager.currentNoise == selectedSound
                                      ? "stop.circle.fill"
                                      : "play.circle.fill")
                                Text(whiteNoiseManager.isPlaying && whiteNoiseManager.currentNoise == selectedSound ? "停止试听" : "试听")
                            }
                        }
                    }
                }

                Section {
                    Button(role: .destructive, action: {
                        showDeleteAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("删除任务")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("编辑任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        whiteNoiseManager.stop()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        updateTask()
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
            .alert("确认删除", isPresented: $showDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    deleteTask()
                }
            } message: {
                Text("确定要删除这个任务吗？此操作无法撤销。")
            }
            .onDisappear {
                whiteNoiseManager.stop()
            }
        }
    }

    // ✅ duration 是分钟，所以这里乘 60 转成秒
    var endTimeString: String {
        let endTime = startTime.addingTimeInterval(duration * 60)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: endTime)
    }

    func updateTask() {
        if let index = dataManager.tasks.firstIndex(where: { $0.id == task.id }) {
            let oldEndTime = dataManager.tasks[index].endTime

            var updatedTask = dataManager.tasks[index]
            updatedTask.title = title
            updatedTask.startTime = startTime

            // ✅ duration 直接存分钟（不乘不除）
            updatedTask.duration = duration

            updatedTask.revenue = Double(revenue) ?? 0.0
            updatedTask.expense = Double(expense) ?? 0.0
            updatedTask.caloriesBurned = Double(caloriesBurned) ?? 0.0
            updatedTask.category = category
            updatedTask.notes = notes
            updatedTask.enableWhiteNoise = enableWhiteNoise
            updatedTask.whiteNoiseType = enableWhiteNoise ? selectedSound : nil

            dataManager.tasks[index] = updatedTask

            // 自动调整后续任务时间
            adjustSubsequentTasks(
                afterTaskId: task.id,
                oldEndTime: oldEndTime,
                newEndTime: updatedTask.endTime
            )

            whiteNoiseManager.stop()
            dataManager.saveAllData()
            onSave()
        }
        dismiss()
    }

    func adjustSubsequentTasks(afterTaskId: UUID, oldEndTime: Date, newEndTime: Date) {
        let timeDifference = newEndTime.timeIntervalSince(oldEndTime)

        if abs(timeDifference) < 1 {
            return
        }

        let calendar = Calendar.current
        let taskDate = calendar.startOfDay(for: task.startTime)

        for i in 0..<dataManager.tasks.count {
            let currentTask = dataManager.tasks[i]

            if calendar.isDate(currentTask.startTime, inSameDayAs: taskDate),
               currentTask.startTime > task.startTime,
               currentTask.id != afterTaskId {
                dataManager.tasks[i].startTime = currentTask.startTime.addingTimeInterval(timeDifference)
            }
        }
    }

    func deleteTask() {
        dataManager.deleteTask(task)
        whiteNoiseManager.stop()
        onSave()
        dismiss()
    }
}
