import Foundation
import Combine
import UserNotifications
import _Concurrency

#if canImport(ActivityKit)
import ActivityKit
#endif

final class TimerManager: ObservableObject {
    @Published var timeRemaining: TimeInterval = 0
    @Published var totalTime: TimeInterval = 0
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var currentTask: Task?

    private var timer: Timer?

    #if canImport(ActivityKit)
    @available(iOS 16.2, *)
    private var activity: Activity<TimerAttributes>?
    #endif

    static let shared = TimerManager()

    private init() {
        loadTimerState()
    }

    // MARK: - 计时器控制

    func startTimer(duration: TimeInterval, for task: Task? = nil) {
        totalTime = duration
        timeRemaining = duration
        isRunning = true
        isPaused = false
        currentTask = task

        if let task = task, task.enableWhiteNoise, let noiseType = task.whiteNoiseType {
            WhiteNoiseManager.shared.play(noise: noiseType)
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.handleTimerTick()
        }

        saveTimerState()
        startLiveActivityIfAvailable()
    }

    func pauseTimer() {
        isPaused = true
        timer?.invalidate()
        timer = nil
        saveTimerState()
        updateLiveActivityIfNeeded()
    }

    func resumeTimer() {
        guard timeRemaining > 0 else { return }

        isPaused = false
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.handleTimerTick()
        }

        saveTimerState()
        updateLiveActivityIfNeeded()
    }

    func stopTimer() {
        isRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        timeRemaining = 0
        currentTask = nil

        saveTimerState()
        WhiteNoiseManager.shared.stop()
        endLiveActivityIfAvailable()
    }

    // MARK: - Tick（⚠️ 这里是之前的雷点）

    private nonisolated func handleTimerTick() {
        _Concurrency.Task {  @MainActor in
            guard self.timeRemaining > 0 else {
                self.timerCompleted()
                return
            }

            self.timeRemaining -= 1
            self.saveTimerState()

            if Int(self.timeRemaining) % 5 == 0 {
                self.updateLiveActivityIfNeeded()
            }
        }
    }

    private func timerCompleted() {
        let completedTask = currentTask
        stopTimer()
        sendCompletionNotification(for: completedTask)
    }

    // MARK: - 计算属性

    var progress: Double {
        guard totalTime > 0 else { return 0 }
        return (totalTime - timeRemaining) / totalTime
    }

    var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var progressPercentage: Int {
        Int(progress * 100)
    }

    // MARK: - 数据持久化

    private func saveTimerState() {
        let defaults = UserDefaults.standard
        defaults.set(timeRemaining, forKey: "timerTimeRemaining")
        defaults.set(totalTime, forKey: "timerTotalTime")
        defaults.set(isRunning, forKey: "timerIsRunning")
        defaults.set(isPaused, forKey: "timerIsPaused")

        if let task = currentTask, let encoded = try? JSONEncoder().encode(task) {
            defaults.set(encoded, forKey: "timerCurrentTask")
        } else {
            defaults.removeObject(forKey: "timerCurrentTask")
        }
    }

    private func loadTimerState() {
        let defaults = UserDefaults.standard
        timeRemaining = defaults.double(forKey: "timerTimeRemaining")
        totalTime = defaults.double(forKey: "timerTotalTime")
        isRunning = defaults.bool(forKey: "timerIsRunning")
        isPaused = defaults.bool(forKey: "timerIsPaused")

        if let data = defaults.data(forKey: "timerCurrentTask"),
           let task = try? JSONDecoder().decode(Task.self, from: data) {
            currentTask = task
        }

        if isRunning && !isPaused && timeRemaining > 0 {
            resumeTimer()
        }
    }

    // MARK: - Live Activity

    private func startLiveActivityIfAvailable() {
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            startLiveActivity()
        }
        #endif
    }

    private func updateLiveActivityIfNeeded() {
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            updateLiveActivity()
        }
        #endif
    }

    private func endLiveActivityIfAvailable() {
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            endLiveActivity()
        }
        #endif
    }

    #if canImport(ActivityKit)
    @available(iOS 16.2, *)
    private func startLiveActivity() {
        guard isRunning else { return }

        if let existing = activity {
            _Concurrency.Task {
                let finalState = TimerAttributes.ContentState(
                    timeRemaining: 0,
                    isRunning: false,
                    isPaused: false,
                    startTime: Date(),
                    totalDuration: totalTime
                )
                await existing.end(
                    ActivityContent(state: finalState, staleDate: nil),
                    dismissalPolicy: .immediate
                )
            }
        }

        let attributes = TimerAttributes(
            taskName: currentTask?.title ?? "专注时间",
            totalDuration: totalTime
        )

        let state = TimerAttributes.ContentState(
            timeRemaining: timeRemaining,
            isRunning: true,
            isPaused: false,
            startTime: Date(),
            totalDuration: totalTime
        )

        activity = try? Activity.request(
            attributes: attributes,
            content: .init(state: state, staleDate: nil),
            pushType: nil
        )
    }

    @available(iOS 16.2, *)
    private func updateLiveActivity() {
        guard let activity = activity else { return }

        _Concurrency.Task {
            let state = TimerAttributes.ContentState(
                timeRemaining: timeRemaining,
                isRunning: !isPaused,
                isPaused: isPaused,
                startTime: Date(),
                totalDuration: totalTime
            )

            await activity.update(
                ActivityContent(state: state, staleDate: nil)
            )
        }
    }

    @available(iOS 16.2, *)
    private func endLiveActivity() {
        guard let activity = activity else { return }

        _Concurrency.Task {
            let finalState = TimerAttributes.ContentState(
                timeRemaining: 0,
                isRunning: false,
                isPaused: false,
                startTime: Date(),
                totalDuration: totalTime
            )

            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )

            await MainActor.run {
                self.activity = nil
            }
        }
    }
    #endif

    // MARK: - 通知

    private func sendCompletionNotification(for task: Task?) {
        let content = UNMutableNotificationContent()
        content.title = "专注时间结束 🎉"
        content.body = task != nil
            ? "任务「\(task!.title)」的专注时间已完成！"
            : "专注时间已完成！休息一下吧 😊"

        UNUserNotificationCenter.current().add(
            UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
        )
    }
}
