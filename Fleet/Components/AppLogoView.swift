import SwiftUI

struct AppLogoView: View {
    var size: CGFloat = 80
    var cornerRadius: CGFloat = 22
    
    var body: some View {
        Group {
            if let uiImage = getAppIcon() {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                // Fallback
                ZStack {
                    Color.teal
                    Image(systemName: "truck.box.fill")
                        .font(.system(size: size * 0.45))
                        .foregroundStyle(Color(.systemBackground))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    private func getAppIcon() -> UIImage? {
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        return UIImage(named: "AppIcon")
    }
}

#Preview {
    AppLogoView()
}
