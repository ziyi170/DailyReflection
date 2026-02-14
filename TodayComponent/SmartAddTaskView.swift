// SmartAddTaskView.swift
// 智能添加任务：支持拍照识别和语音输入
// 放在 Views/Planning/ 文件夹中
import Combine
import SwiftUI
import Vision
import VisionKit
import Speech
import AVFoundation

struct SmartAddTaskView: View {
    @EnvironmentObject var dataManager: AppDataManager
    @Environment(\.dismiss) var dismiss
    
    let selectedDate: Date
    let onSave: () -> Void
    
    @State private var showingCamera = false
    @State private var showingImagePicker = false
    @State private var isRecording = false
    @State private var recognizedText = ""
    @State private var isProcessing = false
    
    // 语音识别
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部提示
                VStack(spacing: 12) {
                    Text("智能添加任务")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("通过拍照或语音快速创建任务")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 30)
                .padding(.horizontal)
                
                Spacer()
                
                // 识别结果显示
                if !recognizedText.isEmpty {
                    recognizedTextView
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // 添加方式按钮
                VStack(spacing: 20) {
                    // 拍照添加
                    smartAddButton(
                        title: "拍照识别",
                        subtitle: "拍摄任务信息自动识别",
                        icon: "camera.fill",
                        color: .blue,
                        action: {
                            showingCamera = true
                        }
                    )
                    
                    // 相册选择
                    smartAddButton(
                        title: "从相册选择",
                        subtitle: "选择已有图片识别",
                        icon: "photo.fill",
                        color: .purple,
                        action: {
                            showingImagePicker = true
                        }
                    )
                    
                    // 语音添加
                    smartAddButton(
                        title: isRecording ? "正在录音..." : "语音添加",
                        subtitle: isRecording ? "点击停止" : "说出任务信息",
                        icon: isRecording ? "waveform" : "mic.fill",
                        color: isRecording ? .red : .green,
                        action: {
                            toggleRecording()
                        },
                        isActive: isRecording
                    )
                    
                    // 手动添加
                    Button(action: {
                        dismiss()
                        // 触发原有的添加任务视图
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("手动输入")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.blue)
                        .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
                
                Spacer()
            }
            .overlay(
                Group {
                    if isProcessing {
                        processingOverlay
                    }
                }
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraView { image in
                    processImage(image)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                PhotoPickerView { image in
                    processImage(image)
                }
            }
        }
    }
    
    // MARK: - 识别结果视图
    
    private var recognizedTextView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("识别成功")
                    .font(.headline)
                Spacer()
                Button("添加") {
                    parseAndAddTask()
                }
                .buttonStyle(.borderedProminent)
            }
            
            ScrollView {
                Text(recognizedText)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
            .frame(maxHeight: 200)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10)
        .padding()
    }
    
    // MARK: - 处理中遮罩
    
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text("正在识别...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(Color(.systemGray))
            .cornerRadius(20)
        }
    }
    
    // MARK: - 方法
    
    private func toggleRecording() {
        if isRecording {
            speechRecognizer.stopRecording()
            isRecording = false
            
            if let transcription = speechRecognizer.transcript {
                recognizedText = transcription
            }
        } else {
            speechRecognizer.requestPermission { granted in
                if granted {
                    speechRecognizer.startRecording()
                    isRecording = true
                } else {
                    // 显示权限提示
                    print("语音识别权限被拒绝")
                }
            }
        }
    }
    
    private func processImage(_ image: UIImage) {
        isProcessing = true
        
        // 使用 Vision 进行 OCR
        guard let cgImage = image.cgImage else {
            isProcessing = false
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    isProcessing = false
                }
                return
            }
            
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            DispatchQueue.main.async {
                recognizedText = recognizedStrings.joined(separator: "\n")
                isProcessing = false
                showingCamera = false
                showingImagePicker = false
            }
        }
        
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["zh-Hans", "en-US"]
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("OCR 识别失败: \(error)")
                DispatchQueue.main.async {
                    isProcessing = false
                }
            }
        }
    }
    
    private func parseAndAddTask() {
        isProcessing = true
        
        // 使用简单的文本解析（如果有 AI API，可以调用 AI 进行更智能的解析）
        let parser = TaskParser()
        let parsedTask = parser.parse(recognizedText, defaultDate: selectedDate)
        
        // 创建任务
        let newTask = Task(
            title: parsedTask.title,
            startTime: parsedTask.startTime,
            duration: parsedTask.duration,
            isCompleted: false,
            notes: parsedTask.notes,
            reflectionNotes: "",
            category: parsedTask.category,
            revenue: 0,
            expense: 0
        )
        
        dataManager.addTask(newTask)
        
        isProcessing = false
        dismiss()
        onSave()
    }
}

// MARK: - 智能添加按钮

private func smartAddButton(
    title: String,
    subtitle: String,
    icon: String,
    color: Color,
    action: @escaping () -> Void,
    isActive: Bool = false
) -> some View {
    Button(action: action) {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: isActive ? color.opacity(0.3) : .black.opacity(0.05), radius: isActive ? 10 : 5)
        )
    }
    .buttonStyle(.plain)
}

// MARK: - 相机视图

struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        
        init(onCapture: @escaping (UIImage) -> Void) {
            self.onCapture = onCapture
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - 相册选择器

struct PhotoPickerView: UIViewControllerRepresentable {
    let onSelect: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onSelect: (UIImage) -> Void
        
        init(onSelect: @escaping (UIImage) -> Void) {
            self.onSelect = onSelect
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onSelect(image)
            }
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - 语音识别器

class SpeechRecognizer: ObservableObject {
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @Published var transcript: String?
    @Published var isAuthorized = false
    
    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    }
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                self.isAuthorized = authStatus == .authorized
                completion(authStatus == .authorized)
            }
        }
    }
    
    func startRecording() {
        // 停止之前的任务
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // 配置音频会话
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                }
            }
            
            if error != nil || result?.isFinal == true {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try? audioEngine.start()
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
    }
}

// MARK: - 任务解析器

struct TaskParser {
    struct ParsedTask {
        var title: String
        var startTime: Date
        var duration: Double
        var category: String
        var notes: String
    }
    
    func parse(_ text: String, defaultDate: Date) -> ParsedTask {
        var title = ""
        var startTime = defaultDate
        var duration: Double = 60 // 默认 60 分钟
        var category = "其他"
        var notes = text
        
        let lines = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        // 简单解析逻辑
        if let firstLine = lines.first {
            title = firstLine
        }
        
        // 尝试识别时间
        if let timeMatch = extractTime(from: text) {
            startTime = timeMatch
        }
        
        // 尝试识别时长
        if let durationMatch = extractDuration(from: text) {
            duration = durationMatch
        }
        
        // 尝试识别分类
        if let categoryMatch = extractCategory(from: text) {
            category = categoryMatch
        }
        
        return ParsedTask(
            title: title.isEmpty ? "新任务" : title,
            startTime: startTime,
            duration: duration,
            category: category,
            notes: notes
        )
    }
    
    private func extractTime(from text: String) -> Date? {
        // 匹配 HH:mm 格式
        let timePattern = #"(\d{1,2}):(\d{2})"#
        guard let regex = try? NSRegularExpression(pattern: timePattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }
        
        let hourRange = Range(match.range(at: 1), in: text)!
        let minuteRange = Range(match.range(at: 2), in: text)!
        
        let hour = Int(text[hourRange])!
        let minute = Int(text[minuteRange])!
        
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        
        return Calendar.current.date(from: components)
    }
    
    private func extractDuration(from text: String) -> Double? {
        // 匹配 "X小时" 或 "X分钟"
        if text.contains("小时") {
            let pattern = #"(\d+)\s*小时"#
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
                let range = Range(match.range(at: 1), in: text)!
                if let hours = Double(text[range]) {
                    return hours * 60
                }
            }
        }
        
        if text.contains("分钟") || text.contains("分") {
            let pattern = #"(\d+)\s*分"#
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
                let range = Range(match.range(at: 1), in: text)!
                return Double(text[range])
            }
        }
        
        return nil
    }
    
    private func extractCategory(from text: String) -> String? {
        let categories = ["工作", "学习", "健身", "娱乐"]
        for category in categories {
            if text.contains(category) {
                return category
            }
        }
        return nil
    }
}
