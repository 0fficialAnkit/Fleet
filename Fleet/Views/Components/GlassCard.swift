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

    }
}