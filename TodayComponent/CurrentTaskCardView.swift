//  CurrentTaskCardView.swift
//  DailyReflection
//
//  Created by å°è‰º on 2026/1/31.
//

import SwiftUI
import Combine

struct CurrentTaskCard: View {
    let task: Task
    let onStart: () -> Void
    let onComplete: () -> Void
    let onToggleWhiteNoise: () -> Void
    
    @State private var currentTime = Date()
    @State private var timerCancellable: AnyCancellable?
    
    var progress: Double {
        let elapsed = currentTime.timeIntervalSince(task.startTime)
        let total = task.duration*60  // duration 是分钟，转为秒
        return min(max(elapsed / total, 0), 1)
    }
    
    var timeRemaining: String {
        let remaining = task.endTime.timeIntervalSince(currentTime)
        if remaining <= 0 {
            return "已结束"
        }
        
        let totalMinutes = Int(remaining / 60)
        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            return "\(hours)小时\(minutes)分"
        } else if totalMinutes > 0 {
            let seconds = Int(remaining.truncatingRemainder(dividingBy: 60))
            return "\(totalMinutes)分\(String(format: "%02d", seconds))秒"
        } else {
            return "\(Int(remaining))秒"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("正在进行")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(task.title)
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(timeRemaining)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 进度条
            ProgressBar(progress: progress)
                .frame(height: 12)
            
            HStack(spacing: 16) {
                Button(action: onToggleWhiteNoise) {
                    VStack(spacing: 4) {
                        Image(systemName: task.enableWhiteNoise ? "speaker.wave.3.fill" : "speaker.slash.fill")
                            .font(.title2)
                            .foregroundColor(task.enableWhiteNoise ? .blue : .gray)
                        Text(task.whiteNoiseType?.displayName ?? "白噪音")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                Button(action: onComplete) {
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        Text("完成")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue, lineWidth: 2)
                )
        )
        .onAppear {
            // 启动 Timer
            timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { time in
                    currentTime = time
                }
        }
        .onDisappear {
            // 清理 Timer
            timerCancellable?.cancel()
            timerCancellable = nil
        }
    }
}

// 提取进度条为独立组件
struct ProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 12)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: 12)
            }
        }
    }
}
