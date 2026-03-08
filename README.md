# DailyReflection — 每日生活管理

![Swift](https://img.shields.io/badge/Swift-5.9-FA7343?style=flat&logo=swift&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-16.2+-000000?style=flat&logo=apple&logoColor=white)
![Xcode](https://img.shields.io/badge/Xcode-15-147EFB?style=flat&logo=xcode&logoColor=white)
![Claude API](https://img.shields.io/badge/Claude-API-D97706?style=flat)
![License](https://img.shields.io/badge/License-MIT-green?style=flat)

A full-featured iOS life management app built natively with SwiftUI. Combines AI-powered task input, real-time Dynamic Island progress tracking, calorie management with photo recognition, focus timer with white noise, and milestone countdown — all synced via iCloud across devices.

---

## 📱 Screenshots

| Today View | Statistics | Smart Add |
|:---:|:---:|:---:|
| ![Today](screenshots/today.jpg) | ![Stats](screenshots/stats.jpg) | ![Smart Add](screenshots/smart_add.jpg) |

| Diet Tracking | AI Food Input | Focus Timer |
|:---:|:---:|:---:|
| ![Diet](screenshots/diet.jpg) | ![AI Food](screenshots/ai_food.jpg) | ![Timer](screenshots/timer.jpg) |

| Milestones | Countdown | Profile |
|:---:|:---:|:---:|
| ![DDL](screenshots/ddl.jpg) | ![Countdown](screenshots/countdown.jpg) | ![Profile](screenshots/profile.jpg) |

---

## ✨ Features

### 🗓 Today View — Daily Planning Hub
- Inline weekly calendar strip with EventKit integration
- Smart task list with AI-powered and voice input
- Collapsible statistics: task completion rate, finance summary (revenue / expense / net income), calorie balance
- Daily reflection journal — today's learnings and tomorrow's plan

### 🤖 AI-Powered Input (Claude API)
- **Photo recognition** — photograph a schedule or handwritten note; Claude Vision API extracts and creates tasks automatically
- **Voice input** — speak tasks naturally via SFSpeechRecognizer with real-time transcription
- **Smart meal recognition** — describe food in natural language or photograph a meal; Claude estimates calories per item with confidence scoring

### 🏝 Dynamic Island (Live Activity)
- Real-time task progress shown in the Dynamic Island without opening the app
- Compact view: completion ratio; expanded view: current task + animated progress bar
- Full ActivityKit lifecycle: start on first task, update on completion, end when all done

### 📊 Diet & Calorie Tracking
- Daily intake tracking across breakfast, lunch, dinner and snacks
- Weight logging with history
- Three input methods: manual, AI text recognition, photo recognition

### ⏱ Focus Timer + White Noise
- Configurable durations: 5 / 10 / 15 / 25 / 30 / 45 / 60 / 90 min
- Integrated white noise: rain, forest, café, ocean, white noise, campfire
- Per-task white noise — plays automatically when a task is started

### 🏁 Milestones (DDL + Countdown)
- Deadline tracker with overdue detection
- Countdown to future events with custom emoji icons
- Visual date card UI

### 👤 Profile & Monetisation
- **Sign in with Apple** — privacy-first authentication via AuthenticationServices
- **Face ID / Touch ID** — biometric lock via LocalAuthentication
- **StoreKit** — free tier + premium upgrade; theme store for cosmetic items
- **iCloud sync** — all data backed up and synced via CloudKit

---

## 🏗 Architecture

```
DailyReflection/
├── Models/
│   ├── Task.swift                     # Core task model (Codable, Identifiable)
│   ├── MealEntry.swift                # Meal entry + MealType enum
│   ├── WeightEntry.swift              # Weight log
│   └── DailyReflection.swift          # Daily journal model
├── Managers/
│   ├── AppDataManager.swift           # @MainActor ObservableObject, App Groups persistence
│   ├── LiveActivityManager.swift      # ActivityKit singleton (start / update / end)
│   ├── CalendarSyncManager.swift      # EKEventStore wrapper with permission handling
│   ├── TimerManager.swift             # Pomodoro countdown
│   └── WhiteNoiseManager.swift        # AVAudioPlayer loop management
├── Views/
│   ├── TodayView.swift                # Main dashboard (calendar + tasks + stats + reflection)
│   ├── CalorieTrackingView.swift      # Diet management
│   ├── TimerView.swift                # Focus timer UI
│   ├── ReflectionView.swift           # Daily review
│   ├── SmartAddTaskView.swift         # AI + voice task input
│   ├── SmartAddMealView.swift         # AI meal text input
│   └── PhotoRecognitionView.swift     # Camera → Claude Vision → meal entries
├── Widget/
│   └── TodoWidget.swift               # WidgetKit TimelineProvider + small/medium layouts
└── LiveActivity/
    └── DailyReflectionActivity.swift  # ActivityKit attributes + Dynamic Island views
```

---

## ⚙️ Key Technical Decisions

| Decision | Rationale |
|---|---|
| **App Groups for persistence** | Widget Extension is a separate process with no access to the main app's UserDefaults; a shared App Groups container is the standard iOS IPC solution |
| **Single `EKEventStore` instance** | EventStore is expensive to initialise; singleton pattern avoids redundant allocations and maintains consistent auth state |
| **`@MainActor` on AppDataManager** | All `@Published` mutations must occur on the main thread; `@MainActor` enforces this at compile time, eliminating manual `DispatchQueue.main.async` calls |
| **ActivityKit singleton** | The `Activity<>` reference must persist across the app lifecycle to call `update()` and `end()`; a singleton is the correct ownership model |
| **Graceful EventKit fallback** | Calendar access can be revoked at runtime; every sync operation checks `authorizationStatus` before proceeding and degrades without crashing |
| **Claude API for food recognition** | Handles both natural language descriptions and image inputs in a single integration; confidence scoring allows the UI to communicate recognition certainty to the user |

---

## 🍎 Apple Platform APIs

| API | Usage |
|---|---|
| **ActivityKit** | Dynamic Island Live Activities — compact, expanded, minimal layouts |
| **WidgetKit** | Home screen widget with `TimelineProvider` and scheduled refresh |
| **EventKit** | Bidirectional sync with system Calendar and Reminders |
| **CloudKit** | iCloud data sync across devices |
| **StoreKit 2** | In-app purchases and subscription management |
| **AuthenticationServices** | Sign in with Apple |
| **LocalAuthentication** | Face ID / Touch ID biometric lock |
| **SFSpeechRecognizer** | Real-time voice transcription |
| **AVFoundation** | White noise audio with loop playback |
| **App Groups** | Shared data container between main app and Widget Extension |
| **UserNotifications** | Task deadline local notifications |

---

## 🚀 Setup

### Requirements
- Xcode 15+
- iOS 16.2+ deployment target
- Physical device for Dynamic Island (iPhone 14 Pro / 15 series)
- Apple Developer account

### Configuration

1. Clone the repo and open `DailyReflection.xcodeproj`
2. In **Signing & Capabilities**, enable:
   - `App Groups` → `group.com.ziyi170.dailyreflection`
   - `iCloud` → CloudKit container
   - `Push Notifications`
3. Create `Config.plist` (gitignored) with your Claude API key:
```xml
<key>CLAUDE_API_KEY</key>
<string>your-key-here</string>
```
4. Add white noise audio files to the bundle (`rain.mp3`, `forest.mp3`, `cafe.mp3`, `ocean.mp3`, `whitenoise.mp3`, `fire.mp3`)

### Info.plist Permissions
```
NSCalendarsFullAccessUsageDescription
NSRemindersFullAccessUsageDescription
NSSpeechRecognitionUsageDescription
NSMicrophoneUsageDescription
NSPhotoLibraryUsageDescription
NSCameraUsageDescription
NSFaceIDUsageDescription
```

---

## 🗺 Roadmap

- [ ] App Store release
- [ ] Apple Watch companion app
- [ ] Siri Shortcuts / App Intents integration
- [ ] Widget for calorie and focus stats
- [ ] AI-generated weekly review summary
- [ ] Unit tests for core business logic (XCTest)

---

## 📄 License

MIT
