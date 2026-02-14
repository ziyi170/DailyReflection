import SwiftUI
import Speech
import AVFoundation
import Foundation



struct SmartAddMealView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var meals: [MealEntry]
    
    @State private var foodInput: String = ""
    @State private var mealType: MealEntry.MealType = .lunch
    @State private var recognizedMeals: [RecognizedMeal] = []
    @State private var isAnalyzing: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isRecording: Bool = false
    
    // 语音识别相关
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()
    
    var body: some View {
        NavigationView {
            Form {
                Section("输入方式") {
                    // 文字输入
                    HStack {
                        TextField("例如：一碗米饭，200克鸡胸肉", text: $foodInput)
                            .textFieldStyle(.roundedBorder)
                        
                        // 语音输入按钮
                        Button(action: toggleRecording) {
                            Image(systemName: isRecording ? "mic.fill" : "mic")
                                .foregroundColor(isRecording ? .red : .blue)
                                .font(.title2)
                        }
                    }
                    
                    // 快捷输入示例
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            quickInputButton("一碗米饭")
                            quickInputButton("一个苹果")
                            quickInputButton("100克鸡胸肉")
                            quickInputButton("一杯牛奶")
                        }
                    }
                }
                
                Section("餐次") {
                    Picker("选择餐次", selection: $mealType) {
                        ForEach(MealEntry.MealType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    Button(action: analyzeFoods) {
                        HStack {
                            if isAnalyzing {
                                ProgressView()
                                    .padding(.trailing, 5)
                            }
                            Text(isAnalyzing ? "AI识别中..." : "AI智能识别")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(foodInput.isEmpty || isAnalyzing)
                }
                
                // 识别结果
                if !recognizedMeals.isEmpty {
                    Section("识别结果") {
                        ForEach(recognizedMeals) { meal in
                            RecognizedMealRow(meal: meal)
                        }
                    }
                    
                    Section {
                        Button("确认添加 (\(recognizedMeals.count)项)") {
                            addRecognizedMeals()
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("智能添加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Quick Input Button
    private func quickInputButton(_ text: String) -> some View {
        Button(action: {
            foodInput = text
        }) {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
    }
    
    // MARK: - AI Analysis (不用 Task / async)
    func analyzeFoods() {
        isAnalyzing = true
        
        callClaudeAPI(prompt: """
        请分析以下食物描述，并返回JSON格式的数组。请严格按照格式返回，不要添加任何其他文字或解释。
        
        用户输入：\(foodInput)
        
        返回格式（只返回JSON数组，不要markdown代码块）：
        [
            {
                "name": "食物名称",
                "amount": 数量（克）,
                "unit": "单位",
                "calories": 卡路里数,
                "confidence": 置信度(0-1)
            }
        ]
        
        注意：
        1. 只返回JSON数组，不要包含```json或其他markdown标记
        2. 如果是"一碗米饭"，amount应为150克左右
        3. 如果是"一个苹果"，amount应为150克左右
        4. 根据常见食物数据库估算卡路里
        """) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let cleanedResponse = response
                        .replacingOccurrences(of: "```json", with: "")
                        .replacingOccurrences(of: "```", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if let data = cleanedResponse.data(using: .utf8),
                       let meals = try? JSONDecoder().decode([RecognizedMeal].self, from: data) {
                        self.recognizedMeals = meals
                        self.isAnalyzing = false
                    } else {
                        self.errorMessage = "无法解析AI返回的数据"
                        self.showError = true
                        self.isAnalyzing = false
                    }
                    
                case .failure(let error):
                    self.errorMessage = "AI识别失败：\(error.localizedDescription)"
                    self.showError = true
                    self.isAnalyzing = false
                }
            }
        }
    }
    
    // MARK: - Claude API Call (completion 版本，不用 async/await)
    func callClaudeAPI(
        prompt: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            completion(.failure(NSError(domain: "URL Error", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("YOUR_API_KEY", forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1024,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "No Data", code: -1)))
                }
                return
            }
            
            do {
                let response = try JSONDecoder().decode(ClaudeResponse.self, from: data)
                let text = response.content.first?.text ?? ""
                
                DispatchQueue.main.async {
                    completion(.success(text))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        .resume()
    }

    // MARK: - Add Recognized Meals
    func addRecognizedMeals() {
        for recognizedMeal in recognizedMeals {
            let mealEntry = MealEntry(
                name: recognizedMeal.name,
                calories: recognizedMeal.calories,
                mealType: mealType,
                date: Date(),
                description: "\(recognizedMeal.amount)\(recognizedMeal.unit)"
            )
            meals.append(mealEntry)
        }
        dismiss()
    }
    
    // MARK: - Speech Recognition
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    func startRecording() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    do {
                        try startAudioEngine()
                    } catch {
                        errorMessage = "无法启动语音识别：\(error.localizedDescription)"
                        showError = true
                    }
                } else {
                    errorMessage = "请在设置中允许语音识别权限"
                    showError = true
                }
            }
        }
    }
    
    func startAudioEngine() throws {
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "SpeechRecognitionError", code: -1)
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                foodInput = result.bestTranscription.formattedString
            }
            
            if error != nil || result?.isFinal == true {
                audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.isRecording = false
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isRecording = false
    }
}

// MARK: - Supporting Types
struct RecognizedMeal: Identifiable, Codable {
    let id = UUID()
    let name: String
    let amount: Double
    let unit: String
    let calories: Double
    let confidence: Double
    var source: String = "AI分析"
    
    enum CodingKeys: String, CodingKey {
        case name, amount, unit, calories, confidence, source
    }
}

struct RecognizedMealRow: View {
    let meal: RecognizedMeal
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name)
                    .font(.headline)
                Text("\(Int(meal.amount))\(meal.unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(meal.calories)) 卡")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Circle()
                            .fill(index < Int(meal.confidence * 5) ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SmartAddMealView(meals: .constant([]))
}
