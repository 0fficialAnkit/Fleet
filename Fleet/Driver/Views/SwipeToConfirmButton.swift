import SwiftUI

/// iOS-native "slide to confirm" control — like Slide to Power Off.
/// Disabled state is fully inert (no gesture, grayed out).
struct SwipeToConfirmButton: View {

    let label:   String
    let tint:    Color
    let enabled: Bool
    let action:  () -> Void

    @State private var dragX:     CGFloat = 0
    @State private var confirmed: Bool    = false

    private let height:    CGFloat = 60
    private let thumbSize: CGFloat = 52

    var body: some View {
        GeometryReader { geo in
            let trackWidth = geo.size.width
            let maxDrag    = trackWidth - thumbSize - 8
            let progress   = enabled ? min(dragX / maxDrag, 1.0) : 0

            ZStack(alignment: .leading) {

                // ── Track ─────────────────────────────────────────────────
                Capsule()
                    .fill(enabled ? tint.opacity(0.12) : Color(.systemGray5))

                // ── Progress fill ─────────────────────────────────────────
                Capsule()
                    .fill(tint.opacity(0.18 + 0.25 * progress))
                    .frame(width: thumbSize / 2 + dragX + thumbSize / 2)
                    .animation(.interactiveSpring(), value: dragX)

                // ── Label ─────────────────────────────────────────────────
                Text(confirmed ? "✓" : label)
                    .font(.headline)
                    .foregroundStyle(enabled ? tint : Color(.systemGray3))
                    .opacity(confirmed ? 1.0 : max(0.0, 1.0 - progress * 2.0))
                    .frame(maxWidth: .infinity)

                // ── Thumb ─────────────────────────────────────────────────
                Circle()
                    .fill(enabled ? tint : Color(.systemGray4))
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: enabled ? tint.opacity(0.25) : .clear,
                            radius: 4, y: 2)
                    .overlay {
                        Image(systemName: confirmed ? "checkmark"
                              : enabled ? "chevron.right.2" : "lock.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .offset(x: 4 + dragX)
                    .animation(.interactiveSpring(), value: dragX)
                    .gesture(
                        enabled && !confirmed
                        ? DragGesture()
                            .onChanged { v in
                                dragX = min(max(0, v.translation.width), maxDrag)
                            }
                            .onEnded { _ in
                                if dragX > maxDrag * 0.82 {
                                    // Confirmed
                                    withAnimation(.spring(response: 0.25)) {
                                        dragX = maxDrag
                                        confirmed = true
                                    }
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                        action()
                                    }
                                } else {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                        dragX = 0
                                    }
                                }
                            }
                        : nil
                    )
            }
        }
        .frame(height: height)
        .onChange(of: enabled) { _, newVal in
            if !newVal { dragX = 0; confirmed = false }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SwipeToConfirmButton(label: "Slide to Start Trip",
                             tint: .green, enabled: true)  { }
        SwipeToConfirmButton(label: "Slide to Start Trip",
                             tint: .green, enabled: false) { }
        SwipeToConfirmButton(label: "Slide to End Trip",
                             tint: .red,   enabled: true)  { }
    }
    .padding()
}
