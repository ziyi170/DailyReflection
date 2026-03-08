//
//  CalorieEstimator.swift
//  DailyReflection
//
//  根据任务标题和时长自动估算卡路里消耗
//  MET（代谢当量）参考 Compendium of Physical Activities
//

import Foundation

// ============================================================
// MARK: - 卡路里估算器
// ============================================================
struct CalorieEstimator {

    // 默认体重（如无用户数据时使用，单位 kg）
    private static let defaultWeightKg: Double = 65.0

    // ── MET 关键词映射表 ──────────────────────────────────
    // MET = 代谢当量，1 MET = 1 kcal/kg/h（静息）
    // 卡路里 = MET × 体重(kg) × 时长(h)
    private static let metRules: [(keywords: [String], met: Double, label: String)] = [

        // 睡眠 / 休息
        (["睡觉", "午休", "休息", "打盹", "小憩", "冥想", "静坐"], 1.0, "休息"),

        // 办公 / 学习
        (["工作", "办公", "开会", "会议", "汇报", "写作", "写报告", "写代码", "编程", "coding",
          "读书", "看书", "学习", "复习", "背单词", "阅读", "看文献", "做笔记", "刷题",
          "网课", "上课", "讲课", "备课", "写论文", "调研"], 1.8, "脑力工作"),

        // 站立工作 / 轻度家务
        (["站立", "做饭", "烹饪", "洗碗", "整理", "收拾", "打扫", "扫地", "拖地", "洗衣",
          "购物", "逛街", "买菜"], 2.5, "轻度活动"),

        // 散步 / 慢走
        (["散步", "慢走", "遛弯", "遛狗", "逛公园", "饭后走"], 3.5, "散步"),

        // 瑜伽 / 拉伸 / 普拉提
        (["瑜伽", "拉伸", "普拉提", "太极", "冥想瑜伽", "热身"], 3.0, "瑜伽拉伸"),

        // 骑行
        (["骑车", "骑自行车", "单车", "cycling", "骑行"], 6.0, "骑行"),

        // 快走 / 爬楼
        (["快走", "爬楼", "爬山", "登山", "徒步", "hiking"], 5.0, "快走登山"),

        // 跑步（慢跑）
        (["慢跑", "跑步", "跑操", "晨跑", "夜跑", "running"], 8.0, "跑步"),

        // 跑步（快跑/长跑）
        (["长跑", "5公里", "10公里", "半马", "马拉松", "interval", "冲刺"], 11.0, "高强度跑"),

        // 游泳
        (["游泳", "蛙泳", "自由泳", "游泳馆", "swimming"], 7.0, "游泳"),

        // 力量训练 / 健身
        (["健身", "撸铁", "力量训练", "深蹲", "卧推", "硬拉", "引体向上", "俯卧撑",
          "gym", "哑铃", "杠铃", "健身房"], 5.0, "力量训练"),

        // HIIT / 搏击操
        (["hiit", "HIIT", "搏击", "跳操", "有氧操", "tabata", "burpee", "波比跳",
          "跳绳", "动感单车"], 9.0, "高强度有氧"),

        // 球类运动
        (["篮球", "足球", "羽毛球", "乒乓球", "网球", "排球", "棒球",
          "壁球", "高尔夫", "台球"], 7.0, "球类运动"),

        // 舞蹈
        (["跳舞", "舞蹈", "广场舞", "街舞", "爵士舞", "芭蕾", "舞"], 5.0, "舞蹈"),

        // 吃饭 / 社交（极低消耗）
        (["吃饭", "吃早饭", "吃午饭", "吃晚饭", "进餐", "喝咖啡", "吃零食",
          "聊天", "social"], 1.5, "进食社交"),
    ]

    // ── 主方法：估算卡路里 ────────────────────────────────
    /// - Parameters:
    ///   - title: 任务标题
    ///   - durationMinutes: 任务时长（分钟）
    ///   - weightKg: 用户体重，默认 65 kg
    /// - Returns: 估算卡路里（kcal），匹配不到则返回 nil
    static func estimate(
        title: String,
        durationMinutes: Double,
        weightKg: Double = defaultWeightKg
    ) -> CalorieEstimate? {

        let lower = title.lowercased()
        let hours = durationMinutes / 60.0

        for rule in metRules {
            if rule.keywords.contains(where: { lower.contains($0) }) {
                let kcal = rule.met * weightKg * hours
                return CalorieEstimate(
                    calories: kcal.rounded(),
                    activityLabel: rule.label,
                    met: rule.met,
                    isEstimated: true
                )
            }
        }
        return nil
    }

    /// 对一批任务批量估算，只处理 caloriesBurned == 0 的任务
    static func fillMissing(tasks: inout [DailyTask], weightKg: Double = defaultWeightKg) {
        for i in tasks.indices where tasks[i].caloriesBurned == 0 {
            if let est = estimate(
                title: tasks[i].title,
                durationMinutes: tasks[i].duration,
                weightKg: weightKg
            ) {
                tasks[i].caloriesBurned = est.calories
            }
        }
    }
}

// ── 估算结果 ──────────────────────────────────────────────
struct CalorieEstimate {
    let calories: Double
    let activityLabel: String
    let met: Double
    let isEstimated: Bool

    /// 展示用标签，如 "~120 卡 (跑步)"
    var displayText: String {
        "~\(Int(calories)) 卡 (\(activityLabel))"
    }
}