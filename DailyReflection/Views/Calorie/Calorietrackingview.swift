//
//  CalorieTrackingView.swift
//  DailyReflection
//
//  Enhanced version with AI recognition and better UX
//

import SwiftUI
import PhotosUI

struct CalorieTrackingView: View {
    @EnvironmentObject var dataManager: AppDataManager
    @State private var showAddMeal = false
    @State private var showPhotoRecognition = false
    @State private var showSmartAdd = false
    @State private var showAddWeight = false
    @State private var selectedDate = Date()
    @State private var selectedMealType: MealEntry.MealType = .breakfast
    @State private var editingMeal: MealEntry?
    @State private var selectedImage: UIImage?
    
    var todayMeals: [MealEntry] {
        let today = Calendar.current.startOfDay(for: selectedDate)
        return dataManager.meals.filter { meal in
            Calendar.current.isDate(meal.date, inSameDayAs: today)
        }
    }
    
    var todayWeight: WeightEntry? {
        let today = Calendar.current.startOfDay(for: selectedDate)
        return dataManager.weights.first { weight in
            Calendar.current.isDate(weight.date, inSameDayAs: today)
        }
    }
    
    var totalCalories: Double {
        todayMeals.reduce(0) { $0 + $1.calories }
    }
    
    func mealsByType(_ type: MealEntry.MealType) -> [MealEntry] {
        todayMeals.filter { $0.mealType == type }
    }
    
    func caloriesForType(_ type: MealEntry.MealType) -> Double {
        mealsByType(type).reduce(0) { $0 + $1.calories }
    }
    
    func deleteMeal(_ meal: MealEntry) {
        dataManager.meals.removeAll { $0.id == meal.id }
        dataManager.saveData()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 日期选择器
                    DatePicker("选择日期", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .padding(.horizontal)
                    
                    // 总卡路里卡片
                    CalorieSummaryCard(totalCalories: totalCalories)
                    
                    // 体重记录卡片
                    WeightCard(
                        todayWeight: todayWeight,
                        onAdd: { showAddWeight = true }
                    )
                    
                    // 各餐次卡路里统计 - 支持直接添加
                    VStack(spacing: 16) {
                        ForEach(MealEntry.MealType.allCases, id: \.self) { type in
                            EnhancedMealTypeSection(
                                type: type,
                                meals: mealsByType(type),
                                totalCalories: caloriesForType(type),
                                onAdd: {
                                    selectedMealType = type
                                    showSmartAdd = true
                                },
                                onEdit: { meal in
                                    editingMeal = meal
                                },
                                onDelete: { meal in
                                    deleteMeal(meal)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("饮食管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showPhotoRecognition = true }) {
                            Label("拍照识别", systemImage: "camera.fill")
                        }
                        Button(action: { showSmartAdd = true }) {
                            Label("智能添加", systemImage: "brain.head.profile")
                        }
                        Button(action: { showAddMeal = true }) {
                            Label("手动添加", systemImage: "plus.circle")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showAddMeal) {
                AddMealView(
                    isPresented: $showAddMeal,
                    selectedDate: selectedDate,
                    mealType: selectedMealType
                )
                .environmentObject(dataManager)
            }
            .sheet(isPresented: $showSmartAdd) {
                SmartAddMealView(meals: $dataManager.meals)
            }
            .sheet(isPresented: $showPhotoRecognition) {
                PhotoRecognitionView(
                    isPresented: $showPhotoRecognition,
                    selectedDate: selectedDate
                )
                .environmentObject(dataManager)
            }
            .sheet(isPresented: $showAddWeight) {
                AddWeightView(isPresented: $showAddWeight, selectedDate: selectedDate)
                    .environmentObject(dataManager)
            }
            .sheet(item: $editingMeal) { meal in
                EditMealView(
                    isPresented: Binding(
                        get: { editingMeal != nil },
                        set: { if !$0 { editingMeal = nil } }
                    ),
                    meal: meal
                )
                .environmentObject(dataManager)
            }
        }
    }
}

// MARK: - 卡路里摘要卡片
struct CalorieSummaryCard: View {
    let totalCalories: Double
    let targetCalories: Double = 2000
    
    var progress: Double {
        min(totalCalories / targetCalories, 1.0)
    }
    
    var progressColor: Color {
        if totalCalories > targetCalories {
            return .red
        } else if totalCalories > targetCalories * 0.75 {
            return .orange
        } else {
            return .green
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("今日摄入")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("\(Int(totalCalories)) 卡路里")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.orange)
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 20)
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * progress, height: 20)
                }
            }
            .frame(height: 20)
            
            HStack {
                Text("目标: \(Int(targetCalories)) 卡路里")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("剩余: \(Int(max(targetCalories - totalCalories, 0))) 卡")
                    .font(.caption)
                    .foregroundColor(totalCalories > targetCalories ? .red : .secondary)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - 体重卡片
struct WeightCard: View {
    let todayWeight: WeightEntry?
    let onAdd: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("体重记录", systemImage: "scalemass.fill")
                    .font(.headline)
                Spacer()
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
            
            if let weight = todayWeight {
                HStack {
                    Text("\(String(format: "%.1f", weight.weight)) kg")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    if !weight.note.isEmpty {
                        Text(weight.note)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("今日尚未记录体重")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - 增强的餐次部分
struct EnhancedMealTypeSection: View {
    let type: MealEntry.MealType
    let meals: [MealEntry]
    let totalCalories: Double
    let onAdd: () -> Void
    let onEdit: (MealEntry) -> Void
    let onDelete: (MealEntry) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(type.rawValue, systemImage: type.icon)
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(totalCalories)) 卡")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            
            if meals.isEmpty {
                Text("暂无记录")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(meals) { meal in
                    MealRow(
                        meal: meal,
                        onEdit: { onEdit(meal) },
                        onDelete: { onDelete(meal) }
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 餐食行
struct MealRow: View {
    let meal: MealEntry
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                if !meal.description.isEmpty {
                    Text(meal.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text("\(Int(meal.calories)) 卡")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
            
            Menu {
                Button(action: onEdit) {
                    Label("编辑", systemImage: "pencil")
                }
                Button(role: .destructive, action: onDelete) {
                    Label("删除", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 编辑食物视图
struct EditMealView: View {
    @EnvironmentObject var dataManager: AppDataManager
    @Binding var isPresented: Bool
    let meal: MealEntry
    
    @State private var name: String
    @State private var calories: String
    @State private var mealType: MealEntry.MealType
    @State private var description: String
    
    init(isPresented: Binding<Bool>, meal: MealEntry) {
        self._isPresented = isPresented
        self.meal = meal
        self._name = State(initialValue: meal.name)
        self._calories = State(initialValue: String(Int(meal.calories)))
        self._mealType = State(initialValue: meal.mealType)
        self._description = State(initialValue: meal.description)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("食物信息") {
                    TextField("食物名称", text: $name)
                    TextField("卡路里", text: $calories)
                        .keyboardType(.numberPad)
                    TextField("描述（可选）", text: $description)
                }
                
                Section("餐次") {
                    Picker("选择餐次", selection: $mealType) {
                        ForEach(MealEntry.MealType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("编辑食物")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveMeal()
                    }
                    .disabled(name.isEmpty || calories.isEmpty)
                }
            }
        }
    }
    
    func saveMeal() {
        guard let calorieValue = Double(calories) else { return }
        
        if let index = dataManager.meals.firstIndex(where: { $0.id == meal.id }) {
            dataManager.meals[index].name = name
            dataManager.meals[index].calories = calorieValue
            dataManager.meals[index].mealType = mealType
            dataManager.meals[index].description = description
            dataManager.saveData()
        }
        
        isPresented = false
    }
}

// MARK: - 手动添加食物视图（保留原有功能）
struct AddMealView: View {
    @EnvironmentObject var dataManager: AppDataManager
    @Binding var isPresented: Bool
    let selectedDate: Date
    let mealType: MealEntry.MealType
    
    @State private var name = ""
    @State private var calories = ""
    @State private var description = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("食物信息") {
                    TextField("食物名称", text: $name)
                    TextField("卡路里", text: $calories)
                        .keyboardType(.numberPad)
                    TextField("描述（可选）", text: $description)
                }
                
                Section("餐次") {
                    Text(mealType.rawValue)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("添加饮食")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveMeal()
                    }
                    .disabled(name.isEmpty || calories.isEmpty)
                }
            }
        }
    }
    
    func saveMeal() {
        guard let calorieValue = Double(calories) else { return }
        
        let meal = MealEntry(
            name: name,
            calories: calorieValue,
            mealType: mealType,
            date: selectedDate,
            description: description
        )
        
        dataManager.meals.append(meal)
        dataManager.saveData()
        isPresented = false
    }
}

// MARK: - 添加体重视图
struct AddWeightView: View {
    @EnvironmentObject var dataManager: AppDataManager
    @Binding var isPresented: Bool
    let selectedDate: Date
    
    @State private var weight = ""
    @State private var note = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("体重") {
                    TextField("体重 (kg)", text: $weight)
                        .keyboardType(.decimalPad)
                }
                
                Section("备注") {
                    TextField("备注（可选）", text: $note)
                }
            }
            .navigationTitle("记录体重")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveWeight()
                    }
                    .disabled(weight.isEmpty)
                }
            }
        }
    }
    
    func saveWeight() {
        guard let weightValue = Double(weight) else { return }
        
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        dataManager.weights.removeAll { entry in
            Calendar.current.isDate(entry.date, inSameDayAs: startOfDay)
        }
        
        let weightEntry = WeightEntry(
            weight: weightValue,
            date: selectedDate,
            note: note
        )
        
        dataManager.weights.append(weightEntry)
        dataManager.saveData()
        isPresented = false
    }
}
