import SwiftUI

struct ReflectionView: View {
    @State private var tasks: [Task] = []
    @State private var reflections: [DailyReflection] = []
    @State private var selectedDate = Date()
    @State private var expandedTaskId: UUID?
    @State private var currentReflection: DailyReflection?
    
    // 获取昨日日期
    private var yesterday: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? Date()
    }
    
    // 获取昨日复盘
    private var yesterdayReflection: DailyReflection? {
        reflections.first {
            Calendar.current.isDate($0.date, inSameDayAs: yesterday)
        }
    }
    
    var todayTasks: [Task] {
        tasks.filter { Calendar.current.isDate($0.startTime, inSameDayAs: selectedDate) }
            .sorted { $0.startTime < $1.startTime }
    }
    
    var completedTasks: [Task] {
        todayTasks.filter { $0.isCompleted }
    }
    
    var completionPercentage: Int {
        guard !todayTasks.isEmpty else { return 0 }
        return Int((Double(completedTasks.count) / Double(todayTasks.count)) * 100)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部统计卡片
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("今日完成")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(completedTasks.count)/\(todayTasks.count)")
                            .font(.system(size: 28, weight: .bold))
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(completionPercentage) / 100)
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(completionPercentage)%")
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                
                // 内容区域
                if todayTasks.isEmpty {
                    // 空状态
                    VStack(spacing: 20) {
                        Image(systemName: "moon.stars")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("今天还没有任务")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("去今日添加任务吧")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // 任务列表
                            ForEach(todayTasks) { task in
                                ReflectionTaskRow(
                                    task: task,
                                    isExpanded: expandedTaskId == task.id,
                                    onTap: {
                                        withAnimation(.spring(response: 0.3)) {
                                            if expandedTaskId == task.id {
                                                expandedTaskId = nil
                                            } else {
                                                expandedTaskId = task.id
                                            }
                                        }
                                    },
                                    onNotesChange: { notes in
                                        updateTaskReflection(taskId: task.id, notes: notes)
                                    }
                                )
                            }
                            
                            // 总体复盘区域
                            VStack(alignment: .leading, spacing: 16) {
                                Divider()
                                    .padding(.vertical, 8)
                                
                                Text("今日总复盘")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    // 昨日复盘（自动填充昨日"明日改进"）
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text("昨日复盘")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            
                                            if let yesterdayPlan = yesterdayReflection?.tomorrowPlans,
                                               !yesterdayPlan.isEmpty,
                                               currentReflection?.overallSummary.isEmpty ?? true {
                                                Text("（自动填充自昨日计划）")
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        
                                        TextEditor(text: Binding(
                                            get: {
                                                // 如果有已填写的内容，优先显示
                                                if let current = currentReflection, !current.overallSummary.isEmpty {
                                                    return current.overallSummary
                                                }
                                                // 否则显示昨日的"明日改进"
                                                return yesterdayReflection?.tomorrowPlans ?? ""
                                            },
                                            set: { updateOverallReflection(overallSummary: $0) }
                                        ))
                                        .frame(height: 100)
                                        .padding(8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                        .overlay(
                                            Group {
                                                if currentReflection?.overallSummary.isEmpty ?? true,
                                                   let yesterdayPlan = yesterdayReflection?.tomorrowPlans,
                                                   !yesterdayPlan.isEmpty {
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                                }
                                            }
                                        )
                                    }
                                    
                                    // 今日收获
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("今日收获")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        TextEditor(text: Binding(
                                            get: { currentReflection?.todayLearnings ?? "" },
                                            set: { updateOverallReflection(todayLearnings: $0) }
                                        ))
                                        .frame(height: 100)
                                        .padding(8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                    
                                    // 明日改进
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("明日改进")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        TextEditor(text: Binding(
                                            get: { currentReflection?.tomorrowPlans ?? "" },
                                            set: { updateOverallReflection(tomorrowPlans: $0) }
                                        ))
                                        .frame(height: 100)
                                        .padding(8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                }
                                
                                // 提示信息
                                if let yesterdayPlan = yesterdayReflection?.tomorrowPlans,
                                   !yesterdayPlan.isEmpty {
                                    HStack {
                                        Image(systemName: "info.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.caption)
                                        Text("昨日的改进计划已自动带入今日复盘")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.top, 8)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("日复盘")
            .onAppear {
                loadData()
            }
        }
    }
    
    // MARK: - 数据加载
    func loadData() {
        if let savedTasks = UserDefaults.standard.data(forKey: "tasks"),
           let decoded = try? JSONDecoder().decode([Task].self, from: savedTasks) {
            tasks = decoded
        }
        
        if let savedReflections = UserDefaults.standard.data(forKey: "reflections"),
           let decoded = try? JSONDecoder().decode([DailyReflection].self, from: savedReflections) {
            reflections = decoded
        }
        
        // 查找今日的复盘
        if let existing = reflections.first(where: {
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }) {
            currentReflection = existing
        } else {
            // 创建新的复盘，如果有昨日的"明日改进"，则自动填充到"昨日复盘"
            let yesterdayPlan = yesterdayReflection?.tomorrowPlans ?? ""
            let newReflection = DailyReflection(
                date: selectedDate,
                overallSummary: yesterdayPlan, // 自动填充昨日计划
                todayLearnings: "",
                tomorrowPlans: "",
                totalRevenue: 0.0,
                totalExpense: 0.0
            )
            reflections.append(newReflection)
            currentReflection = newReflection
            saveReflections()
        }
    }
    
    // MARK: - 数据更新
    func updateTaskReflection(taskId: UUID, notes: String) {
        if let index = tasks.firstIndex(where: { $0.id == taskId }) {
            tasks[index].reflectionNotes = notes
            saveTasks()
        }
    }
    
    func updateOverallReflection(overallSummary: String? = nil, todayLearnings: String? = nil, tomorrowPlans: String? = nil) {
        guard let index = reflections.firstIndex(where: { $0.id == currentReflection?.id }) else { return }
        
        if let overallSummary = overallSummary {
            reflections[index].overallSummary = overallSummary
        }
        if let todayLearnings = todayLearnings {
            reflections[index].todayLearnings = todayLearnings
        }
        if let tomorrowPlans = tomorrowPlans {
            reflections[index].tomorrowPlans = tomorrowPlans
        }
        
        currentReflection = reflections[index]
        saveReflections()
    }
    
    // MARK: - 数据保存
    func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: "tasks")
        }
    }
    
    func saveReflections() {
        if let encoded = try? JSONEncoder().encode(reflections) {
            UserDefaults.standard.set(encoded, forKey: "reflections")
        }
    }
}

// MARK: - 任务复盘行组件
struct ReflectionTaskRow: View {
    let task: Task
    let isExpanded: Bool
    let onTap: () -> Void
    let onNotesChange: (String) -> Void
    
    @State private var reflectionText: String
    
    init(task: Task, isExpanded: Bool, onTap: @escaping () -> Void, onNotesChange: @escaping (String) -> Void) {
        self.task = task
        self.isExpanded = isExpanded
        self.onTap = onTap
        self.onNotesChange = onNotesChange
        _reflectionText = State(initialValue: task.reflectionNotes)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 任务标题区域
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // 完成状态指示器
                    VStack(spacing: 4) {
                        Circle()
                            .fill(task.isCompleted ? Color.green : Color.gray)
                            .frame(width: 12, height: 12)
                        
                        if !isExpanded {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 2, height: 30)
                        }
                    }
                    
                    // 任务信息
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(task.timeRange)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if task.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Text(task.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("\(Int(task.duration))分钟")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // 展开/收起箭头
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // 展开的复盘内容
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 2)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("任务复盘")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $reflectionText)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .onChange(of: reflectionText) { oldValue, newValue in
                                    onNotesChange(newValue)
                                }
                            
                            Text("写下你对这个任务的思考、收获或改进...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 12)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - 预览
struct ReflectionView_Previews: PreviewProvider {
    static var previews: some View {
        ReflectionView()
    }
}
