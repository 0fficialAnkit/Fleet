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
                .font(themeModel.small())
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
// MARK: - Metric Card
// KPI display with icon, value, and label
// ======================================================

struct MetricCard: View {

    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingSM) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusXS, style: .continuous))

                Spacer()
            }

            Text(value)
                .font(themeModel.title(22))
                .foregroundStyle(themeModel.textPrimary)

            Text(label)
                .font(themeModel.caption())
                .foregroundStyle(themeModel.textTertiary)
        }
        .padding(themeModel.spacingMD)
        .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
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
    var iconColor: Color = themeModel.textTertiary
    var valueColor: Color? = nil

    var body: some View {
        HStack(spacing: themeModel.spacingSM + 4) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(iconColor)
                .frame(width: 22)

            Text(label)
                .font(themeModel.body())
                .foregroundStyle(themeModel.textSecondary)

            Spacer()

            Text(value)
                .font(themeModel.bodyMedium())
                .foregroundStyle(valueColor ?? themeModel.textPrimary)
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
    var iconColor: Color = themeModel.textTertiary
    var isDestructive: Bool = false

    var body: some View {
        HStack(spacing: themeModel.spacingSM + 4) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(isDestructive ? themeModel.danger : iconColor)
                .frame(width: 22)

            Text(title)
                .font(themeModel.body())
                .foregroundStyle(isDestructive ? themeModel.danger : themeModel.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(themeModel.textDisabled)
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
                .font(themeModel.headline())
                .foregroundStyle(themeModel.textPrimary)

            Spacer()

            if let action = action {
                Button(action: { onAction?() }) {
                    Text(action)
                        .font(themeModel.caption())
                        .foregroundStyle(themeModel.accent)
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
        VStack(spacing: themeModel.spacingSM + 4) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(accentColor)
                .frame(width: 100, height: 100)
                .background(accentColor.opacity(0.1))
                .clipShape(Circle())

            Text(name)
                .font(themeModel.title(24))
                .foregroundStyle(themeModel.textPrimary)

            Text(role)
                .font(themeModel.bodyMedium())
                .foregroundStyle(accentColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(accentColor.opacity(0.1))
                .clipShape(Capsule())
        }
    }
}
