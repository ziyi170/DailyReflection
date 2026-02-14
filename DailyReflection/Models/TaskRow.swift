//
//  TaskRow.swift
//  DailyReflection
//
//  Created by 小艺 on 2026/2/5.
//
import SwiftUI

struct TaskRow: View {
    let task: Task
    let isCurrentTask: Bool
    let onToggle: () -> Void
    let onStart: () -> Void
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {

            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)

                if isCurrentTask {
                    Text("进行中")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            Spacer()

            Button(action: onStart) {
                Image(systemName: "play.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

