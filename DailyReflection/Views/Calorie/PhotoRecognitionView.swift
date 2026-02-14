import SwiftUI
import PhotosUI
import _Concurrency

struct PhotoRecognitionView: View {
    @EnvironmentObject var dataManager: AppDataManager
    @Binding var isPresented: Bool
    let selectedDate: Date

    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var recognizedMeals: [RecognizedMeal] = []
    @State private var isAnalyzing = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showCostAlert = false
    @State private var costAlertMessage = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {

                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .cornerRadius(10)
                        .padding(.horizontal)

                    Button {
                        analyzeImage()
                    } label: {
                        HStack {
                            if isAnalyzing {
                                ProgressView()
                            } else {
                                Image(systemName: "brain.head.profile")
                            }
                            Text(isAnalyzing ? "AI识别中..." : "AI识别食物")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isAnalyzing)
                    .padding(.horizontal)

                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.gray.opacity(0.3))

                        Text("拍摄或选择食物照片")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Button("选择照片") {
                            showImagePicker = true
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }

                if isAnalyzing {
                    ProgressView("正在分析图片...")
                }

                Spacer()
            }
            .navigationTitle("拍照识别")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .alert("识别错误", isPresented: $showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - 图像识别

    func analyzeImage() {
        guard let image = selectedImage else { return }
        isAnalyzing = true

        _Concurrency.Task {
            do {
                guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                    throw NSError(domain: "VisionAPI", code: -1)
                }

                let base64Image = imageData.base64EncodedString()
                let response = try await callClaudeVisionAPI(base64Image: base64Image)

                let cleaned = response
                    .replacingOccurrences(of: "```json", with: "")
                    .replacingOccurrences(of: "```", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard
                    let data = cleaned.data(using: .utf8),
                    let meals = try? JSONDecoder().decode([RecognizedMeal].self, from: data)
                else {
                    throw NSError(domain: "VisionAPI", code: -2)
                }

                await MainActor.run {
                    recognizedMeals = meals
                    isAnalyzing = false
                }

            } catch {
                await MainActor.run {
                    errorMessage = "图像识别失败：\(error.localizedDescription)"
                    showError = true
                    isAnalyzing = false
                }
            }
        }
    }

    func callClaudeVisionAPI(base64Image: String) async throws -> String {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("YOUR_API_KEY", forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1024,
            "messages": [[
                "role": "user",
                "content": [[
                    "type": "image",
                    "source": [
                        "type": "base64",
                        "media_type": "image/jpeg",
                        "data": base64Image
                    ]
                ]]
            ]]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: request)

        let decoded = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        return decoded.content.first?.text ?? ""
    }
}

//
// MARK: - ImagePicker（✅ 缺失的就是它）
//

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
