import Foundation
import AVFoundation
import Combine

final class AudioManager: ObservableObject {
    static let shared = AudioManager()

    @Published var isPlaying = false
    @Published var currentSound: WhiteNoiseType?
    @Published var volume: Float = 0.5

    private var audioPlayer: AVAudioPlayer?

    private init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("❌ 音频会话设置失败: \(error)")
        }
    }

    /// 播放白噪音
    func play(_ sound: WhiteNoiseType) {
        // 如果正在播放相同音效 -> 点击就停止
        if currentSound == sound && isPlaying {
            stop()
            return
        }

        // 停止当前播放
        stop()

        // ✅ 支持多个后缀，避免你文件不是 mp3 就找不到
        let supportedExtensions = ["mp3", "m4a", "wav"]

        var foundURL: URL? = nil

        for ext in supportedExtensions {
            if let url = Bundle.main.url(forResource: sound.displayName, withExtension: ext) {
                foundURL = url
                break
            }
        }

        guard let url = foundURL else {
            print("❌ 找不到音频文件：\(sound.displayName).(mp3/m4a/wav)")
            print("👉 检查：文件是否加入了 App Target（Target Membership）")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1          // 无限循环
            audioPlayer?.volume = volume
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

            currentSound = sound
            isPlaying = true

            print("✅ 开始播放: \(sound.rawValue) -> \(url.lastPathComponent)")
        } catch {
            print("❌ 播放失败: \(error)")
            stop()
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentSound = nil
        print("⏹ 停止播放")
    }

    func setVolume(_ newVolume: Float) {
        volume = newVolume
        audioPlayer?.volume = newVolume
    }

    func fadeIn(duration: TimeInterval = 2.0) {
        audioPlayer?.setVolume(volume, fadeDuration: duration)
    }

    func fadeOut(duration: TimeInterval = 2.0) {
        audioPlayer?.setVolume(0, fadeDuration: duration)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.stop()
        }
    }
}
