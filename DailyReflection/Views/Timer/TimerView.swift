import SwiftUI

struct TimerView: View {
    @StateObject private var timerManager = TimerManager.shared
    @StateObject private var whiteNoiseManager = WhiteNoiseManager.shared
    @State private var selectedMinutes = 25
    @State private var showWhiteNoise = true // 控制是否展开白噪音区域
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // 计时器部分
                    timerSection
                    
                    // 白噪音部分 - 可折叠
                    whiteNoiseSection
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("专注时间")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - 计时器部分
    
    private var timerSection: some View {
        VStack(spacing: 20) {
            // 圆形进度计时器
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 250, height: 250)
                
                Circle()
                    .trim(from: 0, to: timerManager.progress)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 250, height: 250)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timerManager.progress)
                
                VStack(spacing: 8) {
                    Text(timerManager.formattedTime)
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                    
                    if timerManager.isPaused {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 8, height: 8)
                            Text("已暂停")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    } else if timerManager.isRunning {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("专注中")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .padding(.vertical)
            
            // 时间选择器（未运行时显示）
            if !timerManager.isRunning {
                timeSelector
            }
            
            // 控制按钮
            controlButtons
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private var timeSelector: some View {
        VStack(spacing: 15) {
            Text("选择专注时长")
                .font(.headline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach([5, 10, 15, 25, 30, 45, 60, 90], id: \.self) { minutes in
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedMinutes = minutes
                        }
                    }) {
                        VStack(spacing: 4) {
                            Text("\(minutes)")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                            Text("分钟")
                                .font(.caption2)
                        }
                        .foregroundColor(selectedMinutes == minutes ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    selectedMinutes == minutes ?
                                    LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                    LinearGradient(colors: [Color.gray.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedMinutes == minutes ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var controlButtons: some View {
        HStack(spacing: 15) {
            if timerManager.isRunning {
                // 暂停/继续按钮
                Button(action: {
                    withAnimation {
                        if timerManager.isPaused {
                            timerManager.resumeTimer()
                        } else {
                            timerManager.pauseTimer()
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: timerManager.isPaused ? "play.fill" : "pause.fill")
                            .font(.title3)
                        Text(timerManager.isPaused ? "继续" : "暂停")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color.orange.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                }
                
                // 停止按钮
                Button(action: {
                    withAnimation {
                        timerManager.stopTimer()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "stop.fill")
                            .font(.title3)
                        Text("停止")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.red, Color.red.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                }
            } else {
                // 开始按钮
                Button(action: {
                    withAnimation {
                        timerManager.startTimer(
                            duration: TimeInterval(selectedMinutes * 60)
                        )
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.title3)
                        Text("开始专注")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
        }
    }
    
    // MARK: - 白噪音部分
    struct FloatingWhiteNoiseControl: View {
        @StateObject private var noiseManager = WhiteNoiseManager.shared
        @State private var isExpanded = false
        
        var body: some View {
            VStack {
                if isExpanded {
                    expandedView
                } else {
                    compactView
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .padding()
        }
        
        private var compactView: some View {
            Button(action: {
                withAnimation(.spring()) {
                    isExpanded = true
                }
            }) {
                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(.blue)
                    
                    if noiseManager.isPlaying, let noise = noiseManager.currentNoise {
                        Text(noise.displayName)
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("白噪音")
                            .font(.caption)
                    }
                    
                    Image(systemName: "chevron.up")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
        
        private var expandedView: some View {
            VStack(spacing: 15) {
                // 标题栏
                HStack {
                    Text("白噪音")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            isExpanded = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                
                // 白噪音选项
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 10) {
                    ForEach(WhiteNoiseType.allCases, id: \.self) { noise in
                        Button(action: {
                            noiseManager.toggle(noise: noise)
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: noise.icon)
                                    .font(.title3)
                                Text(noise.displayName)
                                    .font(.caption2)
                            }
                            .foregroundColor(
                                noiseManager.currentNoise == noise && noiseManager.isPlaying ? .white : .primary
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                noiseManager.currentNoise == noise && noiseManager.isPlaying ?
                                Color.blue : Color.gray.opacity(0.1)
                            )
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)
                
                // 音量控制
                if noiseManager.isPlaying {
                    VStack {
                        HStack {
                            Image(systemName: "speaker.fill")
                            Slider(
                                value: Binding(
                                    get: { noiseManager.volume },
                                    set: { noiseManager.setVolume($0) }
                                ),
                                in: 0...1
                            )
                            Image(systemName: "speaker.wave.3.fill")
                        }
                        .font(.caption)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    private var whiteNoiseSection: some View {
        VStack(spacing: 0) {
            // 白噪音标题栏（可点击折叠）
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showWhiteNoise.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                    
                    Text("白噪音")
                        .font(.headline)
                    
                    Spacer()
                    
                    // 当前播放状态
                    if whiteNoiseManager.isPlaying, let noise = whiteNoiseManager.currentNoise {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            
                            Text(noise.displayName)
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // 展开/折叠图标
                    Image(systemName: showWhiteNoise ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16, corners: showWhiteNoise ? [.topLeft, .topRight] : .allCorners)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 白噪音内容（可折叠）
            if showWhiteNoise {
                VStack(spacing: 20) {
                    // 白噪音选择网格
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(WhiteNoiseType.allCases, id: \.self) { noise in
                            CompactNoiseButton(
                                noise: noise,
                                isSelected: whiteNoiseManager.currentNoise == noise && whiteNoiseManager.isPlaying
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    whiteNoiseManager.toggle(noise: noise)
                                }
                            }
                        }
                    }
                    
                    // 音量控制
                    if whiteNoiseManager.isPlaying {
                        volumeControl
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private var volumeControl: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "speaker.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text("音量")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(whiteNoiseManager.volume * 100))%")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .monospacedDigit()
            }
            
            HStack(spacing: 12) {
                Image(systemName: "speaker.fill")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Slider(
                    value: Binding(
                        get: { whiteNoiseManager.volume },
                        set: { whiteNoiseManager.setVolume($0) }
                    ),
                    in: 0...1
                )
                .tint(.blue)
                
                Image(systemName: "speaker.wave.3.fill")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - 紧凑的白噪音按钮

struct CompactNoiseButton: View {
    let noise: WhiteNoiseType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
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
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: noise.icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .white : .blue)
                }
                
                Text(noise.displayName)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(noise.color.start).opacity(0.08) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color(noise.color.start).opacity(0.5) : Color.gray.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 自定义圆角扩展

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Color Extension (如果之前没有添加)

