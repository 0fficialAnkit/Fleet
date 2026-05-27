import SwiftUI
import UIKit

// ============================================================
// MARK: - Maintenance Blue Design System
// Supports Light Mode & Dark Mode automatically.
// All colors are UIColor-backed so they update live with
// the system appearance without any @Environment plumbing.
// ============================================================

enum MBlue {

    // MARK: - Private helper
    /// Returns a SwiftUI Color that switches between two RGB values based on
    /// the current UIUserInterfaceStyle — fully automatic, no @Environment needed.
    private static func adaptive(
        light l: (r: Int, g: Int, b: Int),
        dark  d: (r: Int, g: Int, b: Int),
        alpha a: CGFloat = 1.0
    ) -> Color {
        Color(UIColor { trait in
            let c = trait.userInterfaceStyle == .dark ? d : l
            return UIColor(
                red:   CGFloat(c.r) / 255,
                green: CGFloat(c.g) / 255,
                blue:  CGFloat(c.b) / 255,
                alpha: a
            )
        })
    }

    // MARK: - Backgrounds
    //  Light: Very pale blue-white  |  Dark: Deep navy
    static let bg         = adaptive(light: (245, 248, 255), dark: (10,  15,  30 ))
    //  Light: Slightly deeper blue  |  Dark: Charcoal navy
    static let surface    = adaptive(light: (235, 243, 255), dark: (17,  24,  39 ))
    //  Light: Pure white cards      |  Dark: Elevated navy card
    static let card       = adaptive(light: (255, 255, 255), dark: (22,  29,  47 ))
    //  Light: Light-blue hairline   |  Dark: Subtle navy border
    static let cardBorder = adaptive(light: (209, 225, 255), dark: (30,  45,  74 ))
    //  Drop-shadow: blue-tinted in light, near-invisible in dark
    static let cardShadow = adaptive(light: (59,  130, 246), dark: (0,   0,   0  ), alpha: 0.08)

    // MARK: - Blue Accent Palette
    // Uses adaptive colors to make them pop brightly in dark mode
    static let accent       = adaptive(light: (37, 99, 235),   dark: (96, 165, 250))  // Light: blue-600, Dark: blue-400
    static let accentLight  = adaptive(light: (59, 130, 246),  dark: (147, 197, 253)) // Light: blue-500, Dark: blue-300
    static let accentBright = adaptive(light: (96, 165, 250),  dark: (191, 219, 254)) // Light: blue-400, Dark: blue-200
    static let accentSky    = adaptive(light: (147, 197, 253), dark: (219, 234, 254)) // Light: blue-300, Dark: blue-100

    //  Soft tinted fill for banners / AI cards
    static let accentSoft   = adaptive(light: (239, 246, 255), dark: (26,  39,  68 ))
    //  Border for accent panels
    static let accentBorder = adaptive(light: (147, 197, 253), dark: (59,  130, 246))

    // MARK: - Status / Semantic
    static let pending    = adaptive(light: (29, 78, 216), dark: (96, 165, 250))    // blue-800 to blue-400
    static let inProgress = adaptive(light: (2, 132, 199), dark: (56, 189, 248))    // sky-600 to sky-400
    static let completed  = adaptive(light: (30, 64, 175), dark: (129, 140, 248))   // blue-800 to indigo-400
    static let critical   = adaptive(light: (109, 40, 217), dark: (167, 139, 250))  // violet-700 to violet-400

    // MARK: - Text  (richer blue-tinted hierarchy)
    //  Light: Deep indigo-navy  |  Dark: Ice white
    static let textPrimary   = adaptive(light: (15,  23,  42 ), dark: (235, 245, 255))
    //  Light: Blue-slate        |  Dark: Soft blue-gray
    static let textSecondary = adaptive(light: (51,  88,  143), dark: (125, 155, 195))
    //  Light: Muted blue-gray   |  Dark: Dark slate
    static let textMuted     = adaptive(light: (120, 144, 175), dark: (65,  88,  118))

    // MARK: - Structural
    static let divider = adaptive(light: (210, 228, 255), dark: (26,  37,  64 ))
}

// ============================================================
// MARK: - Card Modifier  (iOS 26 native .glassEffect)
// ============================================================

extension View {
    /// Plain iOS 26 glass card — no tint, just pure frosted glass + hairline border.
    func mCard() -> some View {
        self
            .glassEffect(
                .regular,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.55),
                                Color("#93C5FD").opacity(0.25),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
    }

    /// Smaller plain glass variant for nested/compact cards.
    func mCardSM() -> some View {
        self
            .glassEffect(
                .regular,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.50),
                                Color("#93C5FD").opacity(0.20),
                                Color.white.opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
    }
}

// ============================================================
// MARK: - Shared Reusable Components
// Used across Driver, FleetManager and Maintenance role views.
// ============================================================

/// Generic metric card — used on multiple dashboards.
/// Accepts any tint color so each role can use its own accent.
struct SummaryCard: View {
    let title: String
    let count: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Text(count)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(MBlue.textPrimary)
            }
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(MBlue.textSecondary)
        }
        .padding(12)
        .mCard()
    }
}

// ============================================================
// MARK: - Ambient Background
// Provides a subtle colorful mesh behind glass elements
// ============================================================
struct AmbientBackground: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            // Subtle blur blobs to refract through the glass cards
            Circle()
                .fill(MBlue.accentLight.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -100, y: -200)
                
            Circle()
                .fill(MBlue.inProgress.opacity(0.12))
                .frame(width: 250, height: 250)
                .blur(radius: 90)
                .offset(x: 150, y: 300)
                
            Circle()
                .fill(MBlue.critical.opacity(0.1))
                .frame(width: 350, height: 350)
                .blur(radius: 100)
                .offset(x: -50, y: 600)
        }
    }
}
