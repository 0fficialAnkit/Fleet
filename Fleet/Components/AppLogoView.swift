import SwiftUI

struct AppLogoView: View {
    var size: CGFloat = 80
    var cornerRadius: CGFloat = 22
    
    var body: some View {
        Group {
            if let uiImage = getAppIcon() {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 1, x: 0, y: 1)
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 8)
                    .shadow(color: Color.black.opacity(0.05), radius: 24, x: 0, y: 16)
            } else {
                // Fallback
                ZStack {
                    Color.teal
                    Image(systemName: "truck.box.fill")
                        .font(.system(size: size * 0.45))
                        .foregroundStyle(Color(.systemBackground))
                }
                .frame(width: size, height: size)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color(.systemBackground))
                )
                // 3D Glass Sheen
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.05),
                            Color.clear,
                            Color.black.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                )
                // Metallic Glass Border
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.7),
                                    Color.white.opacity(0.2),
                                    Color.clear,
                                    Color.black.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.8
                        )
                )
                // Layered 3D Shadows
                .shadow(color: Color.black.opacity(0.06), radius: 1, x: 0, y: 1)
                .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 8)
                .shadow(color: Color.black.opacity(0.05), radius: 24, x: 0, y: 16)
            }
        }
    }
    
    private func getAppIcon() -> UIImage? {
        if let image = UIImage(named: "AppIcon") {
            return image
        }
        if let image = UIImage(named: "appicon") {
            return image
        }
        return nil
    }
}

#Preview {
    AppLogoView()
}
