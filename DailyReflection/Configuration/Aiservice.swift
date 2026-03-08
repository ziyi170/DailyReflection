import Foundation
import SwiftUI

// MARK: - AI Service（Haiku 4.5，日记分析 + 体验钩子）

class AIService: ObservableObject {
    static let shared = AIService()

    @Published var isLoading = false
    @Published var errorMessage: String?

    private let model = "claude-haiku-4-5-20251001"  // Haiku 4.5，成本最低
    private let maxTokens = 600

    private init() {}

    // MARK: - 主入口：日记 AI 分析
    // 调用前先检查 SubscriptionManager.shared.canUseAI
    func analyzeDiary(_ entry: String) async -> AIAnalysisResult? {
        guard !entry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        let prompt = buildDiaryPrompt(entry)
        return await callClaude(prompt: prompt, context: .diary)
    }

    // MARK: - 基础版1次体验（任何用户，装机仅限1次）
    func useBasicTrial(entry: String) async -> AIAnalysisResult? {
        guard SubscriptionManager.shared.canUseBasicAITrial else {
            errorMessage = "AI 体验次数已用完"
            return nil
        }
        let result = await callClaude(prompt: buildDiaryPrompt(entry), context: .trial)
        if result != nil {
            SubscriptionManager.shared.consumeBasicAITrial()
        }
        return result
    }

    // MARK: - Pro 每日5次
    func analyzeWithPro(entry: String) async -> AIAnalysisResult? {
        guard SubscriptionManager.shared.canUseAI else {
            errorMessage = "今日 AI 次数已用完（5次），明天再来"
            return nil
        }
        let result = await callClaude(prompt: buildDiaryPrompt(entry), context: .diary)
        if result != nil {
            SubscriptionManager.shared.recordAIUsage()
        }
        return result
    }

    // MARK: - AI 周报（Pro，批量，成本更低）
    func generateWeeklyReport(entries: [String]) async -> String? {
        guard SubscriptionManager.shared.entitlement.aiWeeklyReport else { return nil }
        let combined = entries.prefix(7).joined(separator: "\n---\n")
        let prompt = """
        你是一个温暖的心理顾问，帮助用户回顾这一周的日记。
        日记内容：
        \(combined)

        请生成一份简洁的周报，包含：
        1. 本周情绪关键词（3个）
        2. 积极进展（2-3条）
        3. 下周小建议（1条）

        语气温暖、简短，控制在150字以内。
        """
        let result = await callClaude(prompt: prompt, context: .report)
        return result?.summary
    }

    // MARK: - Core API Call
    private func callClaude(prompt: String, context: CallContext) async -> AIAnalysisResult? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let request = buildRequest(prompt: prompt) else {
            errorMessage = "请求构建失败"
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:   break
                case 401:   errorMessage = "API Key 无效"; return nil
                case 429:   errorMessage = "请求过于频繁，请稍后重试"; return nil
                case 500...: errorMessage = "服务器错误，请稍后重试"; return nil
                default:    errorMessage = "网络错误（\(httpResponse.statusCode)）"; return nil
                }
            }

            return try parseResponse(data: data)
        } catch {
            errorMessage = "网络请求失败，请检查网络连接"
            print("❌ AI call error: \(error)")
            return nil
        }
    }

    // MARK: - Request Builder
    private func buildRequest(prompt: String) -> URLRequest? {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(AppConfig.claudeAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "system": systemPrompt,
            "messages": [["role": "user", "content": prompt]]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }

    // MARK: - Response Parser
    private func parseResponse(data: Data) throws -> AIAnalysisResult? {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let content = (json?["content"] as? [[String: Any]])?.first,
              let text = content["text"] as? String else { return nil }

        // 尝试解析 JSON 格式回复，失败则用纯文本
        if let jsonData = text.data(using: .utf8),
           let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            return AIAnalysisResult(
                summary:    parsed["summary"] as? String ?? text,
                mood:       parsed["mood"] as? String ?? "平静",
                moodEmoji:  parsed["moodEmoji"] as? String ?? "😌",
                highlights: parsed["highlights"] as? [String] ?? [],
                suggestion: parsed["suggestion"] as? String ?? ""
            )
        }

        // 纯文本兜底
        return AIAnalysisResult(summary: text, mood: "平静", moodEmoji: "😌", highlights: [], suggestion: "")
    }

    // MARK: - Prompts
    private var systemPrompt: String {
        """
        你是一个温暖、细心的日记分析助手。用中文回复，语气亲切自然。
        请用 JSON 格式回复，包含以下字段：
        {
          "summary": "对日记的简短总结（50字内）",
          "mood": "情绪词（如：平静、愉快、焦虑、充实）",
          "moodEmoji": "对应 emoji（如 😊、😌、😰）",
          "highlights": ["今日亮点1", "今日亮点2"],
          "suggestion": "一句温暖的建议或肯定（30字内）"
        }
        只返回 JSON，不要其他文字。
        """
    }

    private func buildDiaryPrompt(_ entry: String) -> String {
        "请分析这篇日记：\n\(entry.prefix(800))"  // 限制 token 用量
    }

    private enum CallContext { case diary, trial, report }
}

// MARK: - AI Result Model
struct AIAnalysisResult {
    let summary: String
    let mood: String
    let moodEmoji: String
    let highlights: [String]
    let suggestion: String
}

// MARK: - AI Result Card View（可复用的结果展示）
struct AIAnalysisCard: View {
    let result: AIAnalysisResult
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(
                            colors: [themeManager.currentTheme.primaryColor.opacity(0.15),
                                     themeManager.currentTheme.primaryColor.opacity(0.08)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 36, height: 36)
                    Text("✨")
                        .font(.system(size: 16))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("AI 日记分析")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                    Text("由 Claude AI 生成")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                // Mood badge
                HStack(spacing: 4) {
                    Text(result.moodEmoji)
                    Text(result.mood)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color(UIColor.tertiarySystemGroupedBackground))
                .clipShape(Capsule())
            }

            // Summary
            Text(result.summary)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            // Highlights
            if !result.highlights.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(result.highlights, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundColor(themeManager.currentTheme.primaryColor)
                                .font(.system(size: 14, weight: .bold))
                            Text(item)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Suggestion
            if !result.suggestion.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.pink)
                    Text(result.suggestion)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary.opacity(0.75))
                        .italic()
                }
                .padding(10)
                .background(Color.pink.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: themeManager.currentTheme.primaryColor.opacity(0.1), radius: 8, y: 4)
        )
    }
}

// MARK: - AI Entry Point Button（日记页底部，智能判断权益）
struct AIAnalysisButton: View {
    let diaryText: String
    @ObservedObject private var aiService = AIService.shared
    @ObservedObject private var sub = SubscriptionManager.shared
    @State private var result: AIAnalysisResult?
    @State private var showUpgrade = false

    var body: some View {
        VStack(spacing: 12) {
            if let result = result {
                AIAnalysisCard(result: result)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Group {
                if sub.currentTier == .pro {
                    // Pro：每日5次
                    proButton
                } else if sub.canUseBasicAITrial {
                    // 任何用户（含免费）：1次体验
                    trialButton
                } else {
                    // 已用完体验，引导升级
                    upgradePromptButton
                }
            }
        }
        .sheet(isPresented: $showUpgrade) {
            PricingSheet(trigger: .aiLimit)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: result != nil)
    }

    // Pro 按钮
    private var proButton: some View {
        Button {
            Task { result = await aiService.analyzeWithPro(entry: diaryText) }
        } label: {
            HStack(spacing: 8) {
                if aiService.isLoading {
                    ProgressView().tint(.white).scaleEffect(0.8)
                } else {
                    Image(systemName: "sparkles")
                }
                Text(aiService.isLoading ? "分析中…" : "AI 分析日记")
                Spacer()
                Text("\(sub.aiRemainingToday)/5")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 18).padding(.vertical, 13)
            .background(
                LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .purple.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(aiService.isLoading || !sub.canUseAI)
    }

    // 1次体验按钮
    private var trialButton: some View {
        Button {
            Task { result = await aiService.useBasicTrial(entry: diaryText) }
        } label: {
            HStack(spacing: 8) {
                if aiService.isLoading {
                    ProgressView().tint(.white).scaleEffect(0.8)
                } else {
                    Image(systemName: "sparkles")
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(aiService.isLoading ? "分析中…" : "免费体验 AI 分析")
                        .font(.system(size: 15, weight: .semibold))
                    Text("仅限1次，升级解锁更多")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.75))
                }
                Spacer()
                Text("免费")
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.white.opacity(0.25))
                    .clipShape(Capsule())
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18).padding(.vertical, 12)
            .background(
                LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .orange.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(aiService.isLoading)
    }

    // 体验已用完，引导升级
    private var upgradePromptButton: some View {
        Button { showUpgrade = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 13))
                Text("解锁 AI 每日分析")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Text("升级 Pro")
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18).padding(.vertical, 13)
            .background(Color.secondary.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}