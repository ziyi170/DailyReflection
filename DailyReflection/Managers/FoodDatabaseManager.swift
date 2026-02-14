// FoodDatabaseManager.swift
import Foundation

struct FoodItem: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let chineseName: String
    let aliases: [String]
    let calories: Double
    let protein: Double
    let fat: Double
    let carbs: Double
    let unit: String
    let standardWeight: Double?
    let category: String?
    
    init(id: String = UUID().uuidString, name: String, chineseName: String, aliases: [String],
         calories: Double, protein: Double, fat: Double, carbs: Double, unit: String,
         standardWeight: Double? = nil, category: String? = nil) {
        self.id = id
        self.name = name
        self.chineseName = chineseName
        self.aliases = aliases
        self.calories = calories
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
        self.unit = unit
        self.standardWeight = standardWeight
        self.category = category
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(chineseName)
    }
    
    static func == (lhs: FoodItem, rhs: FoodItem) -> Bool {
        return lhs.id == rhs.id && lhs.chineseName == rhs.chineseName
    }

    
    static let commonFoods: [FoodItem] = [
        // 主食
        FoodItem(name: "Rice", chineseName: "米饭", aliases: ["米饭", "白米饭", "大米饭"], calories: 116, protein: 2.6, fat: 0.3, carbs: 25.6, unit: "碗", standardWeight: 150),
        FoodItem(name: "Noodles", chineseName: "面条", aliases: ["面条", "拉面", "汤面"], calories: 137, protein: 4.5, fat: 0.7, carbs: 28.2, unit: "碗", standardWeight: 200),
        FoodItem(name: "Bread", chineseName: "面包", aliases: ["面包", "吐司"], calories: 265, protein: 8.8, fat: 3.2, carbs: 50.6, unit: "片", standardWeight: 40),
        FoodItem(name: "SteamedBun", chineseName: "馒头", aliases: ["馒头", "白馒头"], calories: 221, protein: 7.0, fat: 1.1, carbs: 47.0, unit: "个", standardWeight: 75),
        
        // 肉类
        FoodItem(name: "ChickenBreast", chineseName: "鸡胸肉", aliases: ["鸡胸肉", "鸡胸"], calories: 165, protein: 31.0, fat: 3.6, carbs: 0.0, unit: "克", standardWeight: 100),
        FoodItem(name: "Beef", chineseName: "牛肉", aliases: ["牛肉", "牛排"], calories: 250, protein: 26.0, fat: 15.0, carbs: 0.0, unit: "克", standardWeight: 100),
        FoodItem(name: "Pork", chineseName: "猪肉", aliases: ["猪肉", "猪肉片"], calories: 242, protein: 18.0, fat: 18.0, carbs: 0.0, unit: "克", standardWeight: 100),
        FoodItem(name: "Fish", chineseName: "鱼肉", aliases: ["鱼肉", "鱼"], calories: 104, protein: 20.0, fat: 2.7, carbs: 0.0, unit: "克", standardWeight: 100),
        
        // 蔬菜
        FoodItem(name: "Broccoli", chineseName: "西兰花", aliases: ["西兰花", "绿花菜"], calories: 34, protein: 2.8, fat: 0.4, carbs: 6.6, unit: "克", standardWeight: 100),
        FoodItem(name: "Tomato", chineseName: "番茄", aliases: ["番茄", "西红柿"], calories: 18, protein: 0.9, fat: 0.2, carbs: 3.9, unit: "克", standardWeight: 100),
        FoodItem(name: "Cucumber", chineseName: "黄瓜", aliases: ["黄瓜", "青瓜"], calories: 15, protein: 0.7, fat: 0.1, carbs: 3.6, unit: "克", standardWeight: 100),
        FoodItem(name: "Lettuce", chineseName: "生菜", aliases: ["生菜", "莴苣"], calories: 13, protein: 1.4, fat: 0.2, carbs: 2.2, unit: "克", standardWeight: 100),
        
        // 水果
        FoodItem(name: "Apple", chineseName: "苹果", aliases: ["苹果", "红富士"], calories: 52, protein: 0.3, fat: 0.2, carbs: 14.0, unit: "个", standardWeight: 150),
        FoodItem(name: "Banana", chineseName: "香蕉", aliases: ["香蕉", "芭蕉"], calories: 89, protein: 1.1, fat: 0.3, carbs: 22.8, unit: "根", standardWeight: 120),
        FoodItem(name: "Orange", chineseName: "橙子", aliases: ["橙子", "橘子"], calories: 47, protein: 0.9, fat: 0.1, carbs: 11.7, unit: "个", standardWeight: 130),
        FoodItem(name: "Grape", chineseName: "葡萄", aliases: ["葡萄", "提子"], calories: 69, protein: 0.7, fat: 0.2, carbs: 18.1, unit: "克", standardWeight: 100),
        
        // 其他
        FoodItem(name: "Egg", chineseName: "鸡蛋", aliases: ["鸡蛋", "蛋"], calories: 147, protein: 12.6, fat: 10.6, carbs: 1.1, unit: "个", standardWeight: 50),
        FoodItem(name: "Milk", chineseName: "牛奶", aliases: ["牛奶", "纯牛奶"], calories: 54, protein: 3.4, fat: 2.0, carbs: 5.5, unit: "毫升", standardWeight: 100),
        FoodItem(name: "Yogurt", chineseName: "酸奶", aliases: ["酸奶", "酸牛奶"], calories: 72, protein: 3.5, fat: 2.0, carbs: 10.0, unit: "克", standardWeight: 100),
        FoodItem(name: "Tofu", chineseName: "豆腐", aliases: ["豆腐", "豆干"], calories: 76, protein: 8.1, fat: 4.2, carbs: 2.6, unit: "克", standardWeight: 100)
    ]
}

class FoodDatabaseManager {
    static let shared = FoodDatabaseManager()
    
    private var foodItems: [FoodItem] = []
    private var keywordIndex: [String: FoodItem] = [:]
    
    private init() {
        loadLocalDatabase()
        buildKeywordIndex()
    }
    
    // MARK: - 初始化数据库
    private func loadLocalDatabase() {
        print("📦 开始加载食物数据库...")
        
        // 1. 从Loader加载
        let loadedFoods = FoodDatabaseLoader.loadFoodDatabase()
        
        // 2. 合并食物（避免重复）
        var allFoods = Set<FoodItem>()
        
        // 先添加内置食物
        for food in FoodItem.commonFoods {
            allFoods.insert(food)
        }
        
        // 添加加载的食物
        for food in loadedFoods {
            allFoods.insert(food)
        }
        
        // 3. 转换为数组
        foodItems = Array(allFoods)
        
        // 4. 按分类排序
        foodItems.sort { (food1, food2) -> Bool in
            let categoryOrder: [String: Int] = [
                "水果": 1, "主食": 2, "蔬菜": 3, "肉类": 4,
                "海鲜": 5, "蛋类": 6, "奶制品": 7, "豆制品": 8,
                "饮料": 9, "酒类": 10, "零食": 11, "甜点": 12,
                "坚果": 13, "油脂": 14, "调味品": 15
            ]
            
            let order1 = categoryOrder[food1.category ?? "其他"] ?? 99
            let order2 = categoryOrder[food2.category ?? "其他"] ?? 99
            
            if order1 != order2 {
                return order1 < order2
            }
            
            return food1.chineseName < food2.chineseName
        }
        
        print("✅ 食物数据库加载完成，共 \(foodItems.count) 种食物")
        
        // 5. 保存到本地，供下次使用
        FoodDatabaseLoader.saveFoodDatabaseToDocuments(foodItems)
    }
    
    private func buildKeywordIndex() {
        for food in foodItems {
            keywordIndex[food.chineseName.lowercased()] = food
            for alias in food.aliases {
                keywordIndex[alias.lowercased()] = food
            }
        }
    }
    
    // MARK: - 公开接口
    func searchFood(query: String) -> [(name: String, calories: Double)] {
        return foodItems.filter {
            $0.chineseName.contains(query) ||
            $0.aliases.contains { $0.contains(query) }
        }.map { (name: $0.chineseName, calories: $0.calories) }
    }
    
    func calculateCalories(food: String, amount: Double) -> Double? {
        guard let foodItem = findFoodItem(food) else { return nil }
        let weight = foodItem.standardWeight != nil ? amount * foodItem.standardWeight! / 100 : amount
        return foodItem.calories * weight / 100
    }
    
    // MARK: - 智能匹配
    func matchFood(_ input: String) -> (matched: Bool, foodItem: FoodItem?, confidence: Double) {
        let normalizedInput = input.lowercased().trimmingCharacters(in: .whitespaces)
        
        // 1. 完全匹配
        if let exactMatch = keywordIndex[normalizedInput] {
            return (true, exactMatch, 1.0)
        }
        
        // 2. 包含匹配
        for (keyword, food) in keywordIndex {
            if normalizedInput.contains(keyword) {
                return (true, food, 0.8)
            }
        }
        
        return (false, nil, 0.0)
    }
    
    func findFoodItem(_ name: String) -> FoodItem? {
        return keywordIndex[name.lowercased()]
    }
    
    // MARK: - AI缓存管理
    func addAIFoodItem(_ item: FoodItem) {
        if !foodItems.contains(where: { $0.chineseName == item.chineseName }) {
            foodItems.append(item)
            updateKeywordIndex(with: item)
            saveAIFoodItemToCache(item)
            saveToJSONFile()
        }
    }
    
    private func updateKeywordIndex(with item: FoodItem) {
        keywordIndex[item.chineseName.lowercased()] = item
        for alias in item.aliases {
            keywordIndex[alias.lowercased()] = item
        }
    }
    
    // MARK: - 文件操作
    private func loadFromJSONFile() -> [FoodItem]? {
        guard let url = getFoodDatabaseURL() else { return nil }
        
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([FoodItem].self, from: data)
        } catch {
            print("❌ 加载本地数据库失败: \(error)")
            return nil
        }
    }
    
    private func saveToJSONFile() {
        guard let url = getFoodDatabaseURL() else { return }
        
        do {
            let data = try JSONEncoder().encode(foodItems)
            try data.write(to: url)
            print("✅ 本地数据库保存成功，共 \(foodItems.count) 种食物")
        } catch {
            print("❌ 保存数据库失败: \(error)")
        }
    }
    
    private func getFoodDatabaseURL() -> URL? {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first?.appendingPathComponent("food_database.json")
    }
    
    private func loadAICachedFoods() {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.yourapp.dailyreflection"),
              let data = sharedDefaults.data(forKey: "ai_food_cache"),
              let cachedFoods = try? JSONDecoder().decode([FoodItem].self, from: data) else {
            return
        }
        
        for food in cachedFoods {
            if !foodItems.contains(where: { $0.chineseName == food.chineseName }) {
                foodItems.append(food)
                updateKeywordIndex(with: food)
            }
        }
    }
    
    private func saveAIFoodItemToCache(_ item: FoodItem) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.yourapp.dailyreflection") else {
            return
        }
        
        var cachedFoods = [FoodItem]()
        if let data = sharedDefaults.data(forKey: "ai_food_cache"),
           let existing = try? JSONDecoder().decode([FoodItem].self, from: data) {
            cachedFoods = existing
        }
        
        if !cachedFoods.contains(where: { $0.chineseName == item.chineseName }) {
            cachedFoods.append(item)
            
            if let data = try? JSONEncoder().encode(cachedFoods) {
                sharedDefaults.set(data, forKey: "ai_food_cache")
                print("✅ AI食物已缓存: \(item.chineseName)")
            }
        }
    }
}
