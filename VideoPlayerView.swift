import SwiftUI
import AVKit

struct VideoPlayerView: View {
    var videoURL: URL

    var body: some View {
        VideoPlayer(player: AVPlayer(url: videoURL))
            .onAppear {
                let player = AVPlayer(url: videoURL)
                player.play()
            }
    }
}
