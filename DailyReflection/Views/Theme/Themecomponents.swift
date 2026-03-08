import SwiftUI

// MARK: - Theme Settings Row (for settings screen)
struct ThemeSettingsRow: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingThemeStore = false
    
    var body: some View {
        Button {
            showingThemeStore = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [themeManager.currentTheme.primaryColor, themeManager.currentTheme.primaryColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("外观主题")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                    Text(themeManager.currentTheme.name)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    // Color preview dots
                    Circle()
                        .fill(themeManager.currentTheme.primaryColor)
                        .frame(width: 10, height: 10)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingThemeStore) {
            ThemeStoreView()
        }
    }
}

// MARK: - Mini Theme Picker (inline, for settings)
struct MiniThemePicker: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    let columns = [GridItem(.adaptive(minimum: 44, maximum: 52), spacing: 10)]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(ThemeConfiguration.allThemes) { theme in
                MiniThemeCircle(
                    theme: theme,
                    isSelected: themeManager.currentTheme.id == theme.id,
                    isUnlocked: themeManager.isThemeUnlocked(theme)
                ) {
                    if themeManager.isThemeUnlocked(theme) {
                        HapticManager.impact(.light)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            themeManager.selectTheme(theme)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Mini Theme Circle
struct MiniThemeCircle: View {
    let theme: AppTheme
    let isSelected: Bool
    let isUnlocked: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [theme.primaryColor, theme.primaryColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                    )
                    .overlay(
                        Circle()
                            .stroke(theme.primaryColor, lineWidth: isSelected ? 2 : 0)
                            .padding(-3)
                    )
                
                if !isUnlocked {
                    Color.black.opacity(0.4)
                        .clipShape(Circle())
                    
                    Image(systemName: theme.isPro ? "crown.fill" : "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .shadow(
            color: isSelected ? theme.primaryColor.opacity(0.4) : .clear,
            radius: 6, x: 0, y: 3
        )
    }
}

// MARK: - Theme Aware Button
struct ThemeButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(themeManager.currentTheme.primaryColor)
            .clipShape(Capsule())
            .shadow(color: themeManager.currentTheme.primaryColor.opacity(0.35), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Theme-Aware View Modifier
struct ThemeAwareModifier: ViewModifier {
    @ObservedObject var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .accentColor(themeManager.currentTheme.primaryColor)
            .tint(themeManager.currentTheme.primaryColor)
    }
}

extension View {
    func themeAware() -> some View {
        modifier(ThemeAwareModifier())
    }
}

// MARK: - Preview
struct ThemeComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ThemeSettingsRow()
                .padding()
                .background(Color(UIColor.systemGroupedBackground))
            
            MiniThemePicker()
                .padding()
            
            ThemeButton(title: "应用主题", icon: "paintpalette.fill") {}
        }
    }
}