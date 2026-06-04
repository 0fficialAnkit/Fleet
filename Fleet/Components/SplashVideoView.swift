import SwiftUI
import AVKit

struct SplashVideoView: View {
    @Binding var isActive: Bool
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            // Background color matching the video's light gray background
            Color(red: 0.91, green: 0.91, blue: 0.92).ignoresSafeArea()
            
            if let player = player {
                SplashPlayerUIView(player: player)
                    .frame(width: 450, height: 450) // Crops the bottom of the video, removing the Gemini logo
                    .mask(
                        // Smoothly fades the edges so it blends perfectly into the background
                        RadialGradient(
                            gradient: Gradient(colors: [.black, .black, .clear]),
                            center: .center,
                            startRadius: 160,
                            endRadius: 220
                        )
                    )
                    .scaleEffect(0.65) // Makes the centered logo small
                    .onAppear {
                        player.play()
                        
                        // Transition after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                isActive = false
                            }
                        }
                    }
            }
        }
        .onAppear {
            setupPlayer()
        }
    }

    private func setupPlayer() {
        if let asset = NSDataAsset(name: "SplashVideo") {
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent("splash.mp4")
            do {
                try asset.data.write(to: fileURL)
                let newPlayer = AVPlayer(url: fileURL)
                newPlayer.isMuted = true // Mute the video audio
                player = newPlayer
            } catch {
                print("Error writing splash video: \(error)")
                isActive = false
            }
        } else {
            print("SplashVideo asset not found")
            isActive = false
        }
    }
}

struct SplashPlayerUIView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.player = player
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        uiView.player = player
    }
}

class PlayerView: UIView {
    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    private var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        playerLayer.videoGravity = .resizeAspectFill
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        playerLayer.videoGravity = .resizeAspectFill
    }
}
