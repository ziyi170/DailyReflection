import SwiftUI
import Combine
import Foundation

// ============================================================
// MARK: - 卡路里计算管理器（已修复）
// ============================================================
class CalorieCalculationManager: ObservableObject {
    static let shared = CalorieCalculationManager()
    
    @Published private(set) var lastCalculationDate: Date? {
        didSet { 
            UserDefaults.standard.set(lastCalculationDate, forKey: "lastCalorieCalcDate") 
        }
    }
    
    private let cacheKey = "lastCalorieCalcDate"
    
    init() {
        self.lastCalculationDate = UserDefaults.standard.object(forKey: cacheKey) as? Date
    }
    
    // MARK: - 是否需要计算卡路里
    func shouldCalculateCalories() -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastDate = lastCalculationDate {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            return today > lastDay
        }
        
        return true  // 第一次使用
    }
    
    // MARK: - 自动计算任务卡路里（仅按需调用一次）
    func calculateAndUpdateTaskCalories(for tasks: [DailyTask], dataManager: AppDataManager) {
        guard shouldCalculateCalories() else { return }
        
        var updatedTasks = tasks
        
        for i in 0..<updatedTasks.count {
            // 如果任务已有手动设置的卡路里消耗，则跳过
            if updatedTasks[i].caloriesBurned > 0 {
                continue
            }
            
            let calculatedCalories = estimateCalories(
                for: updatedTasks[i].category,
                duration: updatedTasks[i].duration
            )
            
            updatedTasks[i].caloriesBurned = calculatedCalories
        }
        
        // 批量更新数据管理器
        dataManager.tasks = updatedTasks
        dataManager.saveAllData()
        
        // 标记为已计算
        lastCalculationDate = Date()
        
        // 发布更新通知
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    // MARK: - 卡路里估算模型（基于任务分类）
    /// 根据任务分类和时长估算消耗的卡路里
    /// - Parameters:
    ///   - category: 任务分类（工作、学习、健身、娱乐、其他）
    ///   - duration: 任务时长（分钟）
    /// - Returns: 估算的卡路里消耗量
    func estimateCalories(for category: String, duration: Double) -> Double {
        // 卡路里消耗率（每分钟）
        // 基于平均体重 70kg 的参考值，用户可以根据实际调整
        let calorieRates: [String: Double] = [
            "工作": 1.2,      // 轻体力，坐着工作
            "学习": 1.0,      // 轻体力，思维为主
            "健身": 8.5,      // 高体力，如跑步、健身房
            "娱乐": 2.0,      // 中等体力，如运动娱乐
            "其他": 1.5       // 默认中等
        ]
        
        let rate = calorieRates[category] ?? 1.5
        return duration * rate
    }
    
    // MARK: - 重新计算单个任务卡路里（用户手动修改后调用）
    func recalculateIfNeeded(task: inout DailyTask) {
        // 如果用户未手动设置，则使用自动计算值
        if task.caloriesBurned == 0 {
            task.caloriesBurned = estimateCalories(
                for: task.category,
                duration: task.duration
            )
        }
        // 如果用户已手动设置，保持用户的值
    }
    
    // MARK: - 重置计算状态（测试或用户重置时调用）
    func resetCalculationDate() {
        lastCalculationDate = nil
        UserDefaults.standard.removeObject(forKey: cacheKey)
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}

// ============================================================
// MARK: - 扩展：AppDataManager 集成
// ============================================================
extension AppDataManager {
    /// 在应用启动或日期变更时调用，自动计算未设置的卡路里
    func autoCalculateTaskCalories() {
        CalorieCalculationManager.shared.calculateAndUpdateTaskCalories(
            for: self.tasks,
            dataManager: self
        )
    }
}