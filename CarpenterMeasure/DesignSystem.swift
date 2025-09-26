import SwiftUI

// MARK: - Shadcn Dark Mode Color Palette (Always Dark)
extension Color {
    // MARK: - Core Colors (Dark Theme - Always Used)
    static let appBackground = Color(red: 0.047, green: 0.039, blue: 0.035)     // #0c0a09 (Dark brown)
    static let appForeground = Color(red: 0.980, green: 0.980, blue: 0.976)     // #fafaf9 (Off-white text)
    static let appCard = Color(red: 0.047, green: 0.039, blue: 0.035)           // #0c0a09 (Dark brown cards)
    static let appCardForeground = Color(red: 0.980, green: 0.980, blue: 0.976) // #fafaf9 (Light text on cards)
    
    // MARK: - Primary Colors
    static let appPrimary = Color(red: 0.918, green: 0.702, blue: 0.031)        // #eab308 (Yellow - stays same)
    static let appPrimaryForeground = Color(red: 0.047, green: 0.039, blue: 0.035) // #0c0a09 (Dark text on yellow)
    
    // MARK: - Secondary Colors
    static let appSecondary = Color(red: 0.161, green: 0.145, blue: 0.141)      // #292524 (Dark gray)
    static let appSecondaryForeground = Color(red: 0.980, green: 0.980, blue: 0.976) // #fafaf9 (Light text)
    
    // MARK: - Muted Colors
    static let appMuted = Color(red: 0.161, green: 0.145, blue: 0.141)          // #292524 (Dark gray)
    static let appMutedForeground = Color(red: 0.659, green: 0.635, blue: 0.620) // #a8a29e (Medium gray text)
    
    // MARK: - Accent Colors
    static let appAccent = Color(red: 0.161, green: 0.145, blue: 0.141)         // #292524 (Dark gray)
    static let appAccentForeground = Color(red: 0.980, green: 0.980, blue: 0.976) // #fafaf9 (Light text)
    
    // MARK: - Destructive Colors
    static let appDestructive = Color(red: 0.498, green: 0.114, blue: 0.114)    // #7f1d1d (Dark red)
    static let appDestructiveForeground = Color(red: 0.980, green: 0.980, blue: 0.980) // #fafafa (White text)
    
    // MARK: - Border & Input
    static let appBorder = Color(red: 0.161, green: 0.145, blue: 0.141)         // #292524 (Dark gray borders)
    static let appInput = Color(red: 0.161, green: 0.145, blue: 0.141)          // #292524 (Dark gray inputs)
    static let appRing = Color(red: 1.0, green: 0.918, blue: 0.137)             // #ffea23 (Bright yellow ring)
    
    // MARK: - Chart Colors
    static let appChart1 = Color(red: 1.0, green: 0.918, blue: 0.137)           // #ffea23
    static let appChart2 = Color(red: 0.984, green: 0.749, blue: 0.141)         // #fbbf24
    static let appChart3 = Color(red: 0.961, green: 0.620, blue: 0.043)         // #f59e0b
    static let appChart4 = Color(red: 0.851, green: 0.467, blue: 0.024)         // #d97706
    static let appChart5 = Color(red: 0.706, green: 0.325, blue: 0.035)         // #b45309
    
    // MARK: - Sidebar Colors (Dark Theme)
    static let appSidebar = Color(red: 0.110, green: 0.098, blue: 0.090)        // #1c1917 (Darker brown)
    static let appSidebarForeground = Color(red: 0.980, green: 0.980, blue: 0.976) // #fafaf9 (Light text)
    static let appSidebarPrimary = Color(red: 1.0, green: 0.918, blue: 0.137)   // #ffea23 (Bright yellow)
    static let appSidebarPrimaryForeground = Color(red: 0.047, green: 0.039, blue: 0.035) // #0c0a09 (Dark text on yellow)
    
    // MARK: - Convenience Aliases
    static let appSurface = Color.appCard
    static let appTextPrimary = Color.appForeground
    static let appTextSecondary = Color.appMutedForeground
    static let appTextTertiary = Color.appMutedForeground.opacity(0.7)
    static let appTextOnPrimary = Color.appPrimaryForeground
    static let appError = Color.appDestructive
    static let appSuccess = Color.appChart3
    static let appWarning = Color.appChart2
    static let appInfo = Color.appPrimary
    
    // MARK: - Measurement Specific Colors (Dark Theme Optimized)
    static let measurementLine = Color(red: 0.937, green: 0.267, blue: 0.267)   // #ef4444 (Bright red for visibility)
    static let measurementLabel = Color(red: 0.937, green: 0.267, blue: 0.267)  // #ef4444 (Bright red labels)
    static let measurementBackground = Color.appCard                            // Dark brown for measurement backgrounds
    static let magnifierBorder = Color.appForeground                            // Light color for magnifier border
    
    // MARK: - Interactive Colors
    static let buttonPrimary = Color.appPrimary                             // Yellow for primary buttons
    static let buttonSecondary = Color.appSecondary                         // Light gray for secondary buttons
    static let buttonDanger = Color.appDestructive                          // Red for destructive actions
    static let buttonSurface = Color.appSurface                             // White for surface buttons
    static let buttonMuted = Color.appMuted                                 // Muted for disabled/inactive buttons
}

// MARK: - App Typography
extension Font {
    // MARK: - Display Fonts
    static let appDisplayLarge = Font.system(size: 32, weight: .bold, design: .default)
    static let appDisplayMedium = Font.system(size: 28, weight: .bold, design: .default)
    static let appDisplaySmall = Font.system(size: 24, weight: .semibold, design: .default)
    
    // MARK: - Headline Fonts
    static let appHeadlineLarge = Font.system(size: 22, weight: .semibold, design: .default)
    static let appHeadlineMedium = Font.system(size: 18, weight: .semibold, design: .default)
    static let appHeadlineSmall = Font.system(size: 16, weight: .semibold, design: .default)
    
    // MARK: - Body Fonts
    static let appBodyLarge = Font.system(size: 16, weight: .regular, design: .default)
    static let appBodyMedium = Font.system(size: 14, weight: .regular, design: .default)
    static let appBodySmall = Font.system(size: 12, weight: .regular, design: .default)
    
    // MARK: - Label Fonts
    static let appLabelLarge = Font.system(size: 14, weight: .medium, design: .default)
    static let appLabelMedium = Font.system(size: 12, weight: .medium, design: .default)
    static let appLabelSmall = Font.system(size: 10, weight: .medium, design: .default)
    
    // MARK: - Specialized Fonts
    static let appMeasurementValue = Font.system(size: 14, weight: .semibold, design: .monospaced)
    static let appButtonText = Font.system(size: 16, weight: .semibold, design: .default)
    static let appCaptionText = Font.system(size: 11, weight: .regular, design: .default)
}

// MARK: - App Spacing System
struct AppSpacing {
    // MARK: - Base Spacing (4pt grid system)
    static let xs: CGFloat = 4      // 4pt
    static let sm: CGFloat = 8      // 8pt
    static let md: CGFloat = 12     // 12pt
    static let lg: CGFloat = 16     // 16pt
    static let xl: CGFloat = 20     // 20pt
    static let xxl: CGFloat = 24    // 24pt
    static let xxxl: CGFloat = 32   // 32pt
    
    // MARK: - Component Spacing
    static let buttonPadding: CGFloat = 16
    static let cardPadding: CGFloat = 16
    static let screenPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 24
}

// MARK: - Shadcn Border Radius System
struct AppRadius {
    // Based on shadcn --radius: 0.5rem (8px)
    static let sm: CGFloat = 4      // calc(var(--radius) - 4px) = 4px
    static let md: CGFloat = 6      // calc(var(--radius) - 2px) = 6px  
    static let lg: CGFloat = 8      // var(--radius) = 8px (default)
    static let xl: CGFloat = 12     // calc(var(--radius) + 4px) = 12px
    static let circle: CGFloat = 50 // For circular elements
}

// MARK: - Shadcn Shadow System
struct AppShadow {
    // Matches shadcn shadow system
    static let xs = Shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)      // --shadow-xs
    static let small = Shadow(color: Color.black.opacity(0.10), radius: 5, x: 0, y: 2)   // --shadow-sm
    static let medium = Shadow(color: Color.black.opacity(0.10), radius: 5, x: 0, y: 2)  // --shadow-md
    static let large = Shadow(color: Color.black.opacity(0.10), radius: 5, x: 0, y: 2)   // --shadow-lg
    static let xl = Shadow(color: Color.black.opacity(0.10), radius: 5, x: 0, y: 4)      // --shadow-xl
    static let xxl = Shadow(color: Color.black.opacity(0.25), radius: 5, x: 0, y: 2)     // --shadow-2xl
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Design System Components
extension View {
    // MARK: - Shadow Modifiers
    func appShadowSmall() -> some View {
        self.shadow(color: AppShadow.small.color, radius: AppShadow.small.radius, x: AppShadow.small.x, y: AppShadow.small.y)
    }
    
    func appShadowMedium() -> some View {
        self.shadow(color: AppShadow.medium.color, radius: AppShadow.medium.radius, x: AppShadow.medium.x, y: AppShadow.medium.y)
    }
    
    func appShadowLarge() -> some View {
        self.shadow(color: AppShadow.large.color, radius: AppShadow.large.radius, x: AppShadow.large.x, y: AppShadow.large.y)
    }
    
    // MARK: - Button Styles
    func primaryButtonStyle() -> some View {
        self
            .font(.appButtonText)
            .foregroundColor(.appPrimaryForeground)
            .padding(.horizontal, AppSpacing.buttonPadding)
            .padding(.vertical, AppSpacing.md)
            .background(Color.buttonPrimary)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .appShadowSmall()
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .font(.appButtonText)
            .foregroundColor(.appSecondaryForeground)
            .padding(.horizontal, AppSpacing.buttonPadding)
            .padding(.vertical, AppSpacing.md)
            .background(Color.buttonSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(Color.appBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .appShadowSmall()
    }
    
    func dangerButtonStyle() -> some View {
        self
            .font(.appButtonText)
            .foregroundColor(.appDestructiveForeground)
            .padding(.horizontal, AppSpacing.buttonPadding)
            .padding(.vertical, AppSpacing.md)
            .background(Color.buttonDanger)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .appShadowSmall()
    }
    
    // MARK: - Card Style
    func cardStyle() -> some View {
        self
            .padding(AppSpacing.cardPadding)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(Color.appBorder, lineWidth: 1)
            )
            .appShadowSmall()
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: AppSpacing.lg) {
        // Color Palette Preview
        VStack(spacing: AppSpacing.md) {
            Text("Color Palette")
                .font(.appHeadlineMedium)
                .foregroundColor(.appTextPrimary)
            
            HStack(spacing: AppSpacing.sm) {
                Circle().fill(Color.appPrimary).frame(width: 40, height: 40)
                Circle().fill(Color.appSecondary).frame(width: 40, height: 40)
                Circle().fill(Color.appDestructive).frame(width: 40, height: 40)
                Circle().fill(Color.appChart3).frame(width: 40, height: 40)
            }
        }
        
        // Typography Preview
        VStack(spacing: AppSpacing.sm) {
            Text("Typography")
                .font(.appHeadlineMedium)
                .foregroundColor(.appTextPrimary)
            
            Text("Display Large").font(.appDisplayLarge)
            Text("Headline Medium").font(.appHeadlineMedium)
            Text("Body Large").font(.appBodyLarge)
            Text("Label Medium").font(.appLabelMedium)
        }
        
        // Button Styles Preview
        VStack(spacing: AppSpacing.md) {
            Text("Primary Button").primaryButtonStyle()
            Text("Secondary Button").secondaryButtonStyle()
            Text("Danger Button").dangerButtonStyle()
        }
    }
    .padding(AppSpacing.screenPadding)
    .background(Color.appBackground)
}
