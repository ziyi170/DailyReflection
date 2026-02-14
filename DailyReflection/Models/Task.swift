import Foundation

struct Task: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var startTime: Date
    var duration: Double  // 🔧 统一使用分钟（不是秒）
    var isCompleted: Bool
    
    var actualStartTime: Date?
    var actualEndTime: Date?
    var notes: String
    
    var reflectionNotes: String
    // 添加计算属性
    var durationInSeconds: Double {
        duration * 60
    }
    var durationString: String {
        if duration >= 60 {
            
            let hours = Int(duration / 60)
            let minutes = Int(duration.truncatingRemainder(dividingBy: 60))
            return hours > 0 ? "\(hours)小时\(minutes)分钟" : "\(minutes)分钟"
            
        } else {
          return "\(Int(duration))分钟"
          }
    }
    // 计算结束时间
    
    // 分类 + 财务
    var category: String
    var revenue: Double
    var expense: Double
    
    // 🆕 卡路里消耗
    var caloriesBurned: Double

    var enableWhiteNoise: Bool
    var whiteNoiseType: WhiteNoiseType?

    var date: Date {
        Calendar.current.startOfDay(for: startTime)
    }
    
    var netIncome: Double {
        revenue - expense
    }

    init(
        id: UUID = UUID(),
        title: String,
        startTime: Date,
        duration: Double,  // 分钟
        isCompleted: Bool = false,
        notes: String = "",
        reflectionNotes: String = "",
        category: String = "其他",
        revenue: Double = 0.0,
        expense: Double = 0.0,
        caloriesBurned: Double = 0.0,  // 🆕
        enableWhiteNoise: Bool = false,
        whiteNoiseType: WhiteNoiseType? = nil
    ) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.duration = duration
        self.isCompleted = isCompleted
        self.notes = notes
        self.reflectionNotes = reflectionNotes
        self.category = category
        self.revenue = revenue
        self.expense = expense
        self.caloriesBurned = caloriesBurned
        self.enableWhiteNoise = enableWhiteNoise
        self.whiteNoiseType = whiteNoiseType
    }

    var endTime: Date {
        // 🔧 duration 是分钟，需要转换为秒
        startTime.addingTimeInterval(duration*60)
    }

    var timeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
}
