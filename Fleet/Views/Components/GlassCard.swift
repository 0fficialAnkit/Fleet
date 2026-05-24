import SwiftUI

/// A reusable glassmorphic card component with optional corner radius.
struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let content: () -> Content
    var body: some View {
        content()
            .padding()
            .background(.ultraThinMaterial) // iOS glass effect
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}
