import SwiftUI

// MARK: - Toast View
struct ToastView: View {
    let message: String
    let type: ToastType
    
    enum ToastType {
        case success, error, info
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .info: return .blue
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: type.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(type.color)
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
        )
    }
}

// MARK: - Toast Modifier
struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    let type: ToastView.ToastType
    let duration: Double
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if isShowing {
                ToastView(message: message, type: type)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                isShowing = false
                            }
                        }
                    }
                    .zIndex(999)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isShowing)
    }
}

extension View {
    func toast(
        isShowing: Binding<Bool>,
        message: String,
        type: ToastView.ToastType = .success,
        duration: Double = 2.5
    ) -> some View {
        modifier(ToastModifier(isShowing: isShowing, message: message, type: type, duration: duration))
    }
}

// MARK: - Theme Change Success Animation
struct ThemeChangedOverlay: View {
    let theme: AppTheme
    @Binding var isShowing: Bool
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        if isShowing {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(theme.primaryColor.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(theme.primaryColor)
                    }
                    
                    Text("已切换到「\(theme.name)」")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                )
                .scaleEffect(scale)
                .opacity(opacity)
            }
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                    scale = 1
                    opacity = 1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        opacity = 0
                        scale = 0.9
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isShowing = false
                    }
                }
            }
        }
    }
}