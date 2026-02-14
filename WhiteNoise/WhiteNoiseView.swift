import SwiftUI

struct WhiteNoiseView: View {
    @StateObject private var noiseManager = WhiteNoiseManager.shared
    @State private var showVolumeControl = false
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题
            header
            
            // 白噪音选择网格
            noiseGrid
            
            // 音量控制
            if noiseManager.isPlaying {
                volumeControl
            }
            
            // 提示信息
            if !noiseManager.isPlaying {
                helpText
            }
        }
        .padding()
    }
    
    // MARK: - 标题部分
    
    private var header: some View {
        HStack {
            Image(systemName: "speaker.wave.2.fill")
                .font(.title2)
                .foregroundColor(.blue)
            
            Text("白噪音")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            if noiseManager.isPlaying {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    
                    Text("播放中")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - 白噪音网格
    
    private var noiseGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 15) {
            ForEach(WhiteNoiseType.allCases, id: \.self) { noise in
                NoiseButton(
                    noise: noise,
                    isSelected: noiseManager.currentNoise == noise && noiseManager.isPlaying
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        noiseManager.toggle(noise: noise)
                    }
                }
            }
        }
    }
    
    // MARK: - 音量控制
    
    private var volumeControl: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "speaker.fill")
                    .foregroundColor(.blue)
                
                Text("音量")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(noiseManager.volume * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .monospacedDigit()
            }
            
            HStack(spacing: 12) {
                Image(systemName: "speaker.fill")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Slider(
                    value: Binding(
                        get: { noiseManager.volume },
                        set: { noiseManager.setVolume($0) }
                    ),
                    in: 0...1
                )
                .tint(.blue)
                
                Image(systemName: "speaker.wave.3.fill")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(16)
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - 帮助文本
    
    private var helpText: some View {
        VStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.title3)
                .foregroundColor(.gray)
            
            Text("选择一种白噪音来帮助你集中注意力")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - 白噪音按钮

struct NoiseButton: View {
    let noise: WhiteNoiseType
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            action()
        }) {
            VStack(spacing: 12) {
                // 图标
                ZStack {
                    Circle()
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: [Color(noise.color.start), Color(noise.color.end)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.gray.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: noise.icon)
                        .font(.system(size: 28))
                        .foregroundColor(isSelected ? .white : .blue)
                }
                
                // 名称
                Text(noise.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color(noise.color.start).opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color(noise.color.start) : Color.gray.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Color Extension

extension Color {
    init(_ name: String) {
        switch name {
        case "blue": self = .blue
        case "cyan": self = .cyan
        case "teal": self = .teal
        case "green": self = .green
        case "mint": self = .mint
        case "orange": self = .orange
        case "red": self = .red
        case "brown": self = .brown
        case "gray": self = .gray
        default: self = .gray
        }
    }
}

#Preview {
    WhiteNoiseView()
}
