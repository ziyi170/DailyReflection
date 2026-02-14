import Foundation

#if canImport(ActivityKit)
import ActivityKit
import SwiftUI

@available(iOS 16.1, *)
struct TimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var timeRemaining: TimeInterval
        var isRunning: Bool
        var isPaused: Bool
        var startTime: Date
        var totalDuration: TimeInterval  // 添加这个属性，让它可以访问
        
        // 计算属性
        var formattedTime: String {
            let minutes = Int(timeRemaining) / 60
            let seconds = Int(timeRemaining) % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }
        
        var progress: Double {
            guard totalDuration > 0 else { return 0 }
            return (totalDuration - timeRemaining) / totalDuration
        }
        
        // 添加完整的初始化器
        init(timeRemaining: TimeInterval, isRunning: Bool, isPaused: Bool, startTime: Date, totalDuration: TimeInterval) {
            self.timeRemaining = timeRemaining
            self.isRunning = isRunning
            self.isPaused = isPaused
            self.startTime = startTime
            self.totalDuration = totalDuration
        }
        
        // Swift 6 需要这个
        enum CodingKeys: String, CodingKey {
            case timeRemaining
            case isRunning
            case isPaused
            case startTime
            case totalDuration
        }
    }
    
    // 不可变的属性
    var taskName: String
    var totalDuration: TimeInterval
    
    // 添加完整的初始化器
    init(taskName: String, totalDuration: TimeInterval) {
        self.taskName = taskName
        self.totalDuration = totalDuration
    }
}
#endif
