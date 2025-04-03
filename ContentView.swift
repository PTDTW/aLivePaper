import SwiftUI
import AVKit
import Cocoa
import AppKit

struct ContentView: View {
    @State private var videoURL: URL?
    @State private var volume: Double = 1.0
    @State private var thumbnail: NSImage?
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    var body: some View {
        VStack {
            HStack(spacing: 30) {
                VStack(spacing: 25) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.background)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(.quaternary, lineWidth: 1)
                            )
                        
                        if let videoURL = videoURL {
                            VStack(spacing: 10) {
                                if let thumbnail = thumbnail {
                                    Image(nsImage: thumbnail)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: 400, maxHeight: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                Text(videoURL.lastPathComponent)
                                    .lineLimit(1)
                                    .font(.system(size: 14))
                                VideoPlayer(player: AVPlayer(url: videoURL))
                                    .frame(maxWidth: 400, maxHeight: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .padding()
                        } else {
                            VStack {
                                Image(systemName: "film")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("請選擇影片")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .frame(maxWidth: 400, maxHeight: 300)
                    .padding(.top, 20)
                    
                    VStack(spacing: 20) {
                        Button(action: selectLocalVideo) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("選擇影片")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.horizontal, 25)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundStyle(.secondary)
                                Slider(value: $volume, in: 0...1, step: 0.1)
                                    .controlSize(.large)
                                Text("\(Int(volume * 100))%")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 40)
                            }
                            .padding(.vertical, 5)
                        }
                        .padding(.horizontal, 25)
                        
                        if videoURL != nil {
                            Button(action: startLiveWallpaper) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("設置成桌布")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .tint(.green)
                            .padding(.horizontal, 25)
                        }
                    }
                    .padding(.vertical, 20)
                }
                .frame(width: 450)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(20)
                
                HistoryView()
                    .frame(minWidth: 300, maxWidth: 350)
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(20)
            }
            .padding(15)
            .background(.clear)
            
            Text("Version \(appVersion) (\(buildNumber))")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
        }
        .onAppear {
            loadLastWallpaper()
            
            // 監聽歷史記錄選擇的通知
            NotificationCenter.default.addObserver(
                forName: .wallpaperSelected,
                object: nil,
                queue: .main
            ) { notification in
                if let url = notification.userInfo?["url"] as? URL,
                   let volume = notification.userInfo?["volume"] as? Float {
                    self.videoURL = url
                    self.volume = Double(volume)
                    generateThumbnail(from: url) { image in
                        DispatchQueue.main.async {
                            self.thumbnail = image
                        }
                    }
                }
            }
        }
    }

    func selectLocalVideo() {
        let panel = NSOpenPanel()
        panel.title = "選擇影片"
        panel.allowedContentTypes = [.movie]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK {
            guard let url = panel.url else { return }
            
            SecurityScopeManager.shared.saveSecurityScopeBookmark(for: url)
            
            videoURL = url
            generateThumbnail(from: url) { image in
                DispatchQueue.main.async {
                    self.thumbnail = image
                }
            }
        }
    }
    
    private func generateThumbnail(from videoURL: URL, completion: @escaping (NSImage?) -> Void) {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 1, preferredTimescale: 60)
        
        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, _, _ in
            if let cgImage = cgImage {
                let thumbnail = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                completion(thumbnail)
            } else {
                completion(nil)
            }
        }
    }
    
    func startLiveWallpaper() {
        guard let videoURL = videoURL else { return }
        
        // 清除舊的桌布
        LiveWallpaperController.shared.clearWallpaper()
        
        // 設置新的桌布
        LiveWallpaperController.shared.setWallpaper(with: videoURL, volume: Float(volume))
        
        // 儲存新設置
        DatabaseManager.shared.saveWallpaper(
            path: videoURL.path,
            fileName: videoURL.lastPathComponent,
            volume: Float(volume)
        )
        
        NotificationCenter.default.post(name: .wallpaperAdded, object: nil)
    }

    
    private func loadLastWallpaper() {
        if let lastRecord = DatabaseManager.shared.getLastWallpaper() {
            let url = URL(fileURLWithPath: lastRecord.path)
            if SecurityScopeManager.shared.startAccessingSecurityScopedResource(at: url) {
                self.videoURL = url
                self.volume = Double(lastRecord.volume)
                generateThumbnail(from: url) { image in
                    DispatchQueue.main.async {
                        self.thumbnail = image
                    }
                }
                // 自動設置最後一次的壁紙
                LiveWallpaperController.shared.setWallpaper(with: url, volume: lastRecord.volume)
            }
        }
    }
}

class LiveWallpaperWindow: NSWindow {
    var looper: AVPlayerLooper?

    init(videoURL: URL, volume: Float) {
        let screenSize = NSScreen.main?.frame ?? .zero
        super.init(
            contentRect: screenSize,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        self.isOpaque = false
        self.backgroundColor = .clear
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        let playerItem = AVPlayerItem(url: videoURL)
        let queuePlayer = AVQueuePlayer()
        queuePlayer.volume = volume
        self.looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        
        let playerView = AVPlayerView(frame: screenSize)
        playerView.translatesAutoresizingMaskIntoConstraints = true
        playerView.player = queuePlayer
        playerView.controlsStyle = .none
        self.contentView = playerView
        
        queuePlayer.play()
        self.makeKeyAndOrderFront(nil)
    }
    
    override var canBecomeKey: Bool {
        return true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

class LiveWallpaperController {
    static let shared = LiveWallpaperController()
    var wallpaperWindow: LiveWallpaperWindow?
    
    func clearWallpaper() {
        if let playerView = wallpaperWindow?.contentView as? AVPlayerView {
            playerView.player?.pause()
            playerView.player?.replaceCurrentItem(with: nil)
            playerView.player = nil
        }
        if let window = wallpaperWindow {
            window.looper?.disableLooping()
            window.looper = nil
        }
    }

    var lastWallpaperURL: URL? // 用於記錄上次的桌布圖片路徑

    func setSystemWallpaper(from videoURL: URL) {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 1, preferredTimescale: 60)

        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let preview = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))

            // 設定新圖片的存儲路徑
            let timestamp = Int(Date().timeIntervalSince1970)
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("wallpaper_preview_\(timestamp).jpg")

            // 轉換為 JPEG 並寫入
            if let imageData = preview.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: imageData),
               let jpegData = bitmap.representation(using: .jpeg, properties: [:]) {
                try jpegData.write(to: tempURL)

                // 刪除上次的桌布檔案（如果有的話）
                if let lastURL = lastWallpaperURL {
                    try? FileManager.default.removeItem(at: lastURL)
                }

                // 記錄新的桌布檔案路徑
                lastWallpaperURL = tempURL

                if let screen = NSScreen.main {
                    let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
                        .allowClipping: true,
                        .fillColor: NSColor.black,
                        .imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue
                    ]

                    try NSWorkspace.shared.setDesktopImageURL(tempURL, for: screen, options: options)

                    // 強制刷新桌布
                    DistributedNotificationCenter.default()
                        .post(name: Notification.Name("com.apple.desktop.didChange"), object: nil)
                }
            }
        } catch {
            print("設定系統桌布失敗: \(error)")
        }
    }


    func setWallpaper(with videoURL: URL, volume: Float) {
        clearWallpaper()
        setSystemWallpaper(from: videoURL)  // 先設定系統桌布
        wallpaperWindow = LiveWallpaperWindow(videoURL: videoURL, volume: volume)
    }
}



