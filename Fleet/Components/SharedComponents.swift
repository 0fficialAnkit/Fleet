import SwiftUI

// ======================================================
// MARK: - Status Badge
// Colored pill with icon + text
// ======================================================

struct StatusBadge: View {

    let text: String
    let color: Color
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 8, weight: .bold))
            }
            Text(text)
                .font(.caption.weight(.medium))
                .fontWeight(.semibold)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// ======================================================
// MARK: - Filter Button
// Capsule button for horizontal filters
// ======================================================

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.teal : Color(.tertiarySystemBackground))
                .foregroundColor(isSelected ? .white : Color.secondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// ======================================================
// MARK: - Metric Card
// KPI display with icon, value, and label
// ======================================================

struct MetricCard: View {

    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Spacer()
            }

            Text(value)
                .font(.title3.bold())
                .foregroundStyle(Color.primary)

            Text(label)
                .font(.footnote)
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .padding(16)
        .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
        )
    }
}

// ======================================================
// MARK: - Info Row
// Icon + label + value row for detail views
// ======================================================

struct InfoRow: View {

    let icon: String
    let label: String
    let value: String
    var iconColor: Color = Color(.tertiaryLabel)
    var valueColor: Color? = nil

    var body: some View {
        HStack(spacing: 8 + 4) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(iconColor)
                .frame(width: 22)

            Text(label)
                .font(.body)
                .foregroundStyle(Color.secondary)

            Spacer()

            Text(value)
                .font(.body.weight(.medium))
                .foregroundStyle(valueColor ?? Color.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 6)
    }
}

// ======================================================
// MARK: - Action Row
// Tappable settings/navigation row with chevron
// ======================================================

struct ActionRow: View {

    let icon: String
    let title: String
    var iconColor: Color = Color(.tertiaryLabel)
    var isDestructive: Bool = false

    var body: some View {
        HStack(spacing: 8 + 4) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(isDestructive ? Color.red : iconColor)
                .frame(width: 22)

            Text(title)
                .font(.body)
                .foregroundStyle(isDestructive ? Color.red : Color.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(.quaternaryLabel))
        }
        .padding(.vertical, 8)
    }
}

// ======================================================
// MARK: - Section Header
// Consistent section title with optional trailing action
// ======================================================

struct SectionHeader: View {

    let title: String
    var action: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.primary)

            Spacer()

            if let action = action {
                Button(action: { onAction?() }) {
                    Text(action)
                        .font(.footnote)
                        .foregroundStyle(Color.teal)
                }
            }
        }
    }
}

// ======================================================
// MARK: - Profile Header
// Reusable profile header with avatar icon, name, and role
// ======================================================

struct ProfileHeader: View {

    let icon: String
    let name: String
    let role: String
    let accentColor: Color

    var body: some View {
        VStack(spacing: 8 + 4) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(accentColor)
                .frame(width: 100, height: 100)
                .background(accentColor.opacity(0.1))
                .clipShape(Circle())

            Text(name)
                .font(.title3.bold())
                .foregroundStyle(Color.primary)

            Text(role)
                .font(.body.weight(.medium))
                .foregroundStyle(accentColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(accentColor.opacity(0.1))
                .clipShape(Capsule())
        }
    }
}