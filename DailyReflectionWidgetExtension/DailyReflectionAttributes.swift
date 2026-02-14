// DailyReflectionAttributes.swift
// 定义 Live Activity 的数据结构

import ActivityKit
import SwiftUI

@available(iOS 16.1, *)
struct DailyReflectionAttributes: ActivityAttributes {
    /// 动态内容（可以随时更新的状态）
    public struct ContentState: Codable, Hashable {
        // 当前任务信息
        var currentTask: String
        
        // 完成情况
        var completedCount: Int
        var totalCount: Int
        
        // 心情状态
        var mood: String
        
        // 最后更新时间
        var lastUpdate: Date
        
        /// 计算完成进度
        var progress: Double {
            guard totalCount > 0 else { return 0 }
            return Double(completedCount) / Double(totalCount)
        }
        
        /// 进度百分比文本
        var progressText: String {
            let percentage = Int(progress * 100)
            return "\(percentage)%"
        }
        
        /// 是否已完成所有任务
        var isAllCompleted: Bool {
            return completedCount >= totalCount && totalCount > 0
        }
    }
    
    // 不可变属性（创建 Activity 时设置，之后不能改变）
    var username: String
    var startTime: Date
}
