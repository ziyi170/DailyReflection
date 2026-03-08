// FoodDatabaseLoader.swift
import Foundation

// MARK: - Legacy FoodDatabase structure for JSON compatibility
struct FoodDatabase: Codable {
    let foods: [FoodItem]
    
    init(foods: [FoodItem]) {
        self.foods = foods
    }
}

class FoodDatabaseLoader {
    static func loadFoodDatabase() -> [FoodItem] {
        // 1. 先尝试从本地JSON文件加载
        if let foods = loadFromBundleJSON() {
            print("✅ 从Bundle加载食物数据库，共 \(foods.count) 种食物")
            return foods
        }
        
        // 2. 尝试从Documents目录加载
        if let foods = loadFromDocumentsJSON() {
            print("✅ 从Documents加载食物数据库，共 \(foods.count) 种食物")
            return foods
        }
        
        // 3. 使用内置的常见食物
        print("⚠️ 未找到食物数据库文件，使用内置的 \(FoodItem.commonFoods.count) 种常见食物")
        return FoodItem.commonFoods
    }
    
    private static func loadFromBundleJSON() -> [FoodItem]? {
        guard let url = Bundle.main.url(forResource: "food_database", withExtension: "json") else {
            print("❌ 未找到 food_database.json 文件")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            
            // Try decoding as FoodDatabase first
            if let database = try? decoder.decode(FoodDatabase.self, from: data) {
                return database.foods
            }
            
            // Fallback: try decoding as array of FoodItem
            if let foods = try? decoder.decode([FoodItem].self, from: data) {
                return foods
            }
            
            print("❌ 无法解析 food_database.json")
            return nil
        } catch {
            print("❌ 解析 food_database.json 失败: \(error)")
            return nil
        }
    }
    
    private static func loadFromDocumentsJSON() -> [FoodItem]? {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentsURL.appendingPathComponent("food_database.json")
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            
            // Try decoding as FoodDatabase first
            if let database = try? decoder.decode(FoodDatabase.self, from: data) {
                return database.foods
            }
            
            // Fallback: try decoding as array of FoodItem
            if let foods = try? decoder.decode([FoodItem].self, from: data) {
                return foods
            }
            
            print("❌ 无法解析 Documents/food_database.json")
            return nil
        } catch {
            print("❌ 解析 Documents/food_database.json 失败: \(error)")
            return nil
        }
    }
    
    static func saveFoodDatabaseToDocuments(_ foods: [FoodItem]) {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let fileURL = documentsURL.appendingPathComponent("food_database.json")
        
        do {
            // Save as array of FoodItem (simpler format)
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(foods)
            try data.write(to: fileURL)
            print("✅ 食物数据库已保存到 Documents，共 \(foods.count) 种食物")
        } catch {
            print("❌ 保存食物数据库失败: \(error)")
        }
    }
    
    static func downloadFoodDatabaseFromServer() async throws -> [FoodItem] {
        // 这里可以添加从服务器下载最新数据库的逻辑
        // 暂时返回空数组
        return []
    }
}
