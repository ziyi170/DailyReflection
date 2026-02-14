import Foundation
import ActivityKit
import WidgetKit
import Combine
import _Concurrency   // 👈 关键这一行

@available(iOS 16.1, *)
final class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()

    @Published var currentActivity: Activity<DailyReflectionAttributes>?

    private init() {
        checkActiveActivities()
    }

    private func checkActiveActivities() {
        for activity in Activity<DailyReflectionAttributes>.activities {
            currentActivity = activity
        }
    }
    
    
    func start(tasks: [Task], mood: String, username: String) {

        print("🔥 START CALLED")

        print("Activities enabled:",
              ActivityAuthorizationInfo().areActivitiesEnabled)

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("❌ Live Activities not enabled")
            return
        }

        // 如果已有 Activity，先结束
        if let existing = currentActivity {
            _Concurrency.Task {
                await existing.end(dismissalPolicy: .immediate)
            }
        }

        let currentTask = tasks.first(where: { !$0.isCompleted })?.title ?? "开始今日任务"
        let completedCount = tasks.filter { $0.isCompleted }.count

        let attributes = DailyReflectionAttributes(
            username: username,
            startTime: Date()
        )

        let state = DailyReflectionAttributes.ContentState(
            currentTask: currentTask,
            completedCount: completedCount,
            totalCount: tasks.count,
            mood: mood,
            lastUpdate: Date()
        )

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                contentState: state,
                pushType: nil
            )
            print("✅ Live Activity started")
        } catch {
            print("❌ Error starting Live Activity:", error)
        }
    }


    
    func update(tasks: [Task], mood: String) {
        guard let activity = currentActivity else { return }

        let currentTask = tasks.first(where: { !$0.isCompleted })?.title ?? "所有任务已完成！"
        let completedCount = tasks.filter { $0.isCompleted }.count

        let updatedState = DailyReflectionAttributes.ContentState(
            currentTask: currentTask,
            completedCount: completedCount,
            totalCount: tasks.count,
            mood: mood,
            lastUpdate: Date()
        )

        _Concurrency.Task {
            await activity.update(using: updatedState)
        }
    }

    func stop() {
        guard let activity = currentActivity else { return }

        _Concurrency.Task {
            await activity.end(dismissalPolicy: .immediate)
            await MainActor.run {
                self.currentActivity = nil
            }
        }
    }
    
    

    
    func endWithDelay(tasks: [Task], mood: String) {
        guard let activity = currentActivity else { return }

        let finalState = DailyReflectionAttributes.ContentState(
            currentTask: "今日任务已完成！🎉",
            completedCount: tasks.filter { $0.isCompleted }.count,
            totalCount: tasks.count,
            mood: mood,
            lastUpdate: Date()
        )

        _Concurrency.Task {
            await activity.update(using: finalState)

            try? await _Concurrency.Task.sleep(nanoseconds: 3_000_000_000)

            await activity.end(dismissalPolicy: .default)

            await MainActor.run {
                self.currentActivity = nil
            }
        }
    }
}
