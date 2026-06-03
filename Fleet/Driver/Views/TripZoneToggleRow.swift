import SwiftUI

/// A native iOS Toggle row for pickup / drop-off confirmation.
/// Locked (disabled, lock icon) when the driver is outside the zone.
/// Stays ON permanently once confirmed — cannot be untoggled.
struct TripZoneToggleRow: View {

    let label:    String
    let locked:   Bool          // true  → toggle disabled, shows lock icon
    let done:     Bool          // true  → toggle is ON, greyed-out permanently
    let tint:     Color
    let lockHint: String        // shown while locked
    let doneHint: String        // shown after confirmation
    let onConfirm: () -> Void

    var body: some View {
        HStack(spacing: 14) {

            // Leading icon
            Image(systemName: done    ? "checkmark.circle.fill"
                              : locked ? "lock.circle.fill"
                                       : "circle.dotted")
                .font(.title3)
                .foregroundStyle(done ? tint : (locked ? Color.secondary : tint))
                .frame(width: 28)
                .contentTransition(.symbolEffect(.replace))

            // Label + hint
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(done ? tint : .primary)
                Text(done ? doneHint : (locked ? lockHint : "Tap to confirm \(label.lowercased())"))
                    .font(.caption)
                    .foregroundStyle(done ? tint.opacity(0.7) : .secondary)
            }

            Spacer()

            // Toggle — binding prevents toggling back OFF
            Toggle("", isOn: Binding(
                get: { done },
                set: { newVal in
                    guard newVal, !done, !locked else { return }
                    onConfirm()
                }
            ))
            .toggleStyle(.switch)
            .tint(tint)
            .disabled(locked || done)
            .labelsHidden()
        }
        .padding(.vertical, 6)
        .animation(.spring(response: 0.35), value: done)
        .animation(.spring(response: 0.35), value: locked)
    }
}

#Preview {
    List {
        Section {
            TripZoneToggleRow(label: "Pickup",   locked: true,  done: false, tint: .green,
                              lockHint: "Enter pickup zone",  doneHint: "Pickup confirmed")  { }
            TripZoneToggleRow(label: "Pickup",   locked: false, done: false, tint: .green,
                              lockHint: "Enter pickup zone",  doneHint: "Pickup confirmed")  { }
            TripZoneToggleRow(label: "Drop-off", locked: false, done: true,  tint: .indigo,
                              lockHint: "Enter drop-off zone", doneHint: "Drop-off confirmed") { }
        }
    }
    .listStyle(.insetGrouped)
}
