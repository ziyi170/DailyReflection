import SwiftUI

// DDL项目数据模型
struct DDLProject: Identifiable, Codable {
    let id: UUID
    var title: String
    var deadline: Date
    var notes: String
    var reminderSettings: [ReminderSetting]
    var isCompleted: Bool
    
    init(id: UUID = UUID(), title: String, deadline: Date, notes: String = "", reminderSettings: [ReminderSetting] = [], isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.deadline = deadline
        self.notes = notes
        self.reminderSettings = reminderSettings
        self.isCompleted = isCompleted
    }
    
    var timeRemaining: String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: now, to: deadline)
        
        if let days = components.day, days > 0 {
            return "还有\(days)天"
        } else if let hours = components.hour, hours > 0 {
            return "还有\(hours)小时"
        } else if let minutes = components.minute, minutes > 0 {
            return "还有\(minutes)分钟"
        } else {
            return "已截止"
        }
    }
    
    var isOverdue: Bool {
        deadline < Date()
    }
}

struct ReminderSetting: Codable, Identifiable {
    let id: UUID
    var type: ReminderType
    var customDays: Int?
    
    init(id: UUID = UUID(), type: ReminderType, customDays: Int? = nil) {
        self.id = id
        self.type = type
        self.customDays = customDays
    }
    
    enum ReminderType: String, Codable {
        case oneHourBefore = "1小时前"
        case oneDayBefore = "1天前"
        case threeDaysBefore = "3天前"
        case oneWeekBefore = "1周前"
        case custom = "自定义"
    }
}

struct DDLView: View {
    @State private var projects: [DDLProject] = []
    @State private var showingAddProject = false
    @State private var expandedProjectId: UUID?
    
    var activeProjects: [DDLProject] {
        projects.filter { !$0.isCompleted }
            .sorted { $0.deadline < $1.deadline }
    }
    
    var completedProjects: [DDLProject] {
        projects.filter { $0.isCompleted }
            .sorted { $0.deadline > $1.deadline }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if projects.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("还没有DDL项目")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("点击右上角 + 添加项目")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        if !activeProjects.isEmpty {
                            Section(header: Text("进行中")) {
                                ForEach(activeProjects) { project in
                                    DDLProjectRow(
                                        project: project,
                                        isExpanded: expandedProjectId == project.id,
                                        onTap: {
                                            withAnimation {
                                                if expandedProjectId == project.id {
                                                    expandedProjectId = nil
                                                } else {
                                                    expandedProjectId = project.id
                                                }
                                            }
                                        },
                                        onToggle: {
                                            toggleProjectCompletion(project)
                                        },
                                        onNotesChange: { notes in
                                            updateProjectNotes(projectId: project.id, notes: notes)
                                        }
                                    )
                                }
                            }
                        }
                        
                        if !completedProjects.isEmpty {
                            Section(header: Text("已完成")) {
                                ForEach(completedProjects) { project in
                                    DDLProjectRow(
                                        project: project,
                                        isExpanded: false,
                                        onTap: {},
                                        onToggle: {
                                            toggleProjectCompletion(project)
                                        },
                                        onNotesChange: { _ in }
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("DDL")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddProject = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddProject) {
                AddDDLProjectView(projects: $projects, onSave: saveProjects)
            }
            .onAppear {
                loadProjects()
            }
        }
    }
    
    func toggleProjectCompletion(_ project: DDLProject) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index].isCompleted.toggle()
            saveProjects()
        }
    }
    
    func updateProjectNotes(projectId: UUID, notes: String) {
        if let index = projects.firstIndex(where: { $0.id == projectId }) {
            projects[index].notes = notes
            saveProjects()
        }
    }
    
    func loadProjects() {
        if let saved = UserDefaults.standard.data(forKey: "ddlProjects"),
           let decoded = try? JSONDecoder().decode([DDLProject].self, from: saved) {
            projects = decoded
        }
    }
    
    func saveProjects() {
        if let encoded = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(encoded, forKey: "ddlProjects")
        }
    }
}

struct DDLProjectRow: View {
    let project: DDLProject
    let isExpanded: Bool
    let onTap: () -> Void
    let onToggle: () -> Void
    let onNotesChange: (String) -> Void
    
    @State private var notesText: String
    
    init(project: DDLProject, isExpanded: Bool, onTap: @escaping () -> Void, onToggle: @escaping () -> Void, onNotesChange: @escaping (String) -> Void) {
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
                            Image(systemName: "clock")
                                .font(.caption)
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
                        .onChange(of: notesText) { oldValue, newValue in
                            onNotesChange(newValue)
                        }
                }
                .transition(.opacity)
            }
        }
    }
}

struct AddDDLProjectView: View {
    @Binding var projects: [DDLProject]
    let onSave: () -> Void
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
                                if isOn {
                                    selectedReminders.insert(type)
                                } else {
                                    selectedReminders.remove(type)
                                }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("添加DDL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        addProject()
                    }
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
        
        projects.append(newProject)
        onSave()
        dismiss()
    }
}

