import AVFoundation
import Combine

// ⚠️ 删除这里的 WhiteNoiseType enum，因为它已经移到 Models/WhiteNoiseType.swift

class WhiteNoiseManager: ObservableObject {
    @Published var isPlaying = false
    @Published var currentNoise: WhiteNoiseType?
    @Published var volume: Float = 0.5
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var audioPlayer: AVAudioPlayer?
    
    static let shared = WhiteNoiseManager()
    
    private init() {
        setupAudioSession()
        loadSettings()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Failed to setup audio session: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 获取音频URL（本地优先，在线备用）
    
    private func getAudioURL(for noise: WhiteNoiseType) -> URL? {
        // 方法1: 尝试从主Bundle加载
        if let localURL = Bundle.main.url(forResource: noise.rawValue, withExtension: "mp3") {
            print("✅ Found local audio: \(noise.rawValue).mp3")
            return localURL
        }
        
        // 方法2: 尝试从Sounds文件夹加载
        if let soundsPath = Bundle.main.path(forResource: noise.rawValue, ofType: "mp3", inDirectory: "Sounds") {
            let url = URL(fileURLWithPath: soundsPath)
            print("✅ Found audio in Sounds folder: \(noise.rawValue).mp3")
            return url
        }
        
        // 方法3: 检查所有可能的路径
        if let resourcePath = Bundle.main.resourcePath {
            let soundsURL = URL(fileURLWithPath: resourcePath).appendingPathComponent("Sounds").appendingPathComponent("\(noise.rawValue).mp3")
            if FileManager.default.fileExists(atPath: soundsURL.path) {
                print("✅ Found audio at custom path: \(soundsURL.path)")
                return soundsURL
            }
        }
        
        // 方法4: 使用在线URL作为备用
        if let onlineURLString = noise.onlineURL,
           let onlineURL = URL(string: onlineURLString) {
            print("⚠️ Local file not found, using online URL for: \(noise.displayName)")
            return onlineURL
        }
        
        print("❌ No audio source found for: \(noise.displayName)")
        return nil
    }
    
    // MARK: - 播放控制
    
    func play(noise: WhiteNoiseType) {
        isLoading = true
        errorMessage = nil
        
        guard let url = getAudioURL(for: noise) else {
            errorMessage = "找不到音频文件: \(noise.displayName)"
            isLoading = false
            print("❌ \(errorMessage ?? "")")
            return
        }
        
        // 如果是在线URL，异步下载并播放
        if url.scheme == "http" || url.scheme == "https" {
            playOnlineAudio(url: url, noise: noise)
        } else {
            playLocalAudio(url: url, noise: noise)
        }
    }
    
    private func playLocalAudio(url: URL, noise: WhiteNoiseType) {
        do {
            audioPlayer?.stop()
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.volume = volume
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            isPlaying = true
            currentNoise = noise
            isLoading = false
            saveSettings()
            
            print("✅ Playing local audio: \(noise.displayName)")
        } catch {
            errorMessage = "播放失败: \(error.localizedDescription)"
            isLoading = false
            print("❌ Failed to play local audio: \(error)")
        }
    }
    
    private func playOnlineAudio(url: URL, noise: WhiteNoiseType) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "下载失败: \(error.localizedDescription)"
                    self.isLoading = false
                    print("❌ Failed to download audio: \(error)")
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "无效的音频数据"
                    self.isLoading = false
                    return
                }
                
                do {
                    self.audioPlayer?.stop()
                    self.audioPlayer = try AVAudioPlayer(data: data)
                    self.audioPlayer?.numberOfLoops = -1
                    self.audioPlayer?.volume = self.volume
                    self.audioPlayer?.prepareToPlay()
                    self.audioPlayer?.play()
                    
                    self.isPlaying = true
                    self.currentNoise = noise
                    self.isLoading = false
                    self.saveSettings()
                    
                    print("✅ Playing online audio: \(noise.displayName)")
                } catch {
                    self.errorMessage = "播放失败: \(error.localizedDescription)"
                    self.isLoading = false
                    print("❌ Failed to play online audio: \(error)")
                }
            }
        }.resume()
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentNoise = nil
        errorMessage = nil
        saveSettings()
        
        print("⏹️ Stopped white noise")
    }
    
    func toggle(noise: WhiteNoiseType) {
        if currentNoise == noise && isPlaying {
            stop()
        } else {
            play(noise: noise)
        }
    }
    
    func setVolume(_ newVolume: Float) {
        volume = max(0, min(1, newVolume))
        audioPlayer?.volume = volume
        saveSettings()
    }
    
    // MARK: - 持久化
    
    private func saveSettings() {
        UserDefaults.standard.set(volume, forKey: "whiteNoiseVolume")
        if let noise = currentNoise {
            UserDefaults.standard.set(noise.rawValue, forKey: "currentNoise")
        } else {
            UserDefaults.standard.removeObject(forKey: "currentNoise")
        }
        UserDefaults.standard.set(isPlaying, forKey: "whiteNoiseIsPlaying")
    }
    
    private func loadSettings() {
        volume = UserDefaults.standard.float(forKey: "whiteNoiseVolume")
        if volume == 0 { volume = 0.5 }
    }
    
    // MARK: - 调试：列出所有音频文件
    
    func listAllAudioFiles() {
        print("\n📁 Checking for audio files:")
        
        if let resourcePath = Bundle.main.resourcePath {
            print("Resource path: \(resourcePath)")
            
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                let audioFiles = contents.filter { $0.hasSuffix(".mp3") || $0.hasSuffix(".m4a") || $0.hasSuffix(".wav") }
                
                if audioFiles.isEmpty {
                    print("⚠️ No audio files found in main bundle")
                } else {
                    print("✅ Found audio files:")
                    audioFiles.forEach { print("  - \($0)") }
                }
                
                let soundsPath = resourcePath + "/Sounds"
                if FileManager.default.fileExists(atPath: soundsPath) {
                    let soundsContents = try FileManager.default.contentsOfDirectory(atPath: soundsPath)
                    let soundsFiles = soundsContents.filter { $0.hasSuffix(".mp3") || $0.hasSuffix(".m4a") || $0.hasSuffix(".wav") }
                    
                    if !soundsFiles.isEmpty {
                        print("✅ Found audio files in Sounds folder:")
                        soundsFiles.forEach { print("  - \($0)") }
                    }
                } else {
                    print("⚠️ Sounds folder not found")
                }
            } catch {
                print("❌ Error listing files: \(error)")
            }
        }
        
        print("\n")
    }
}
