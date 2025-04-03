import SwiftUI
import AVFoundation

struct HistoryView: View {
    @State private var wallpapers: [WallpaperRecord] = []
    @State private var thumbnailCache: [String: NSImage] = [:]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("最近使用")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
                .padding(.top, 15)
            
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 130, maximum: 150), spacing: 20)],
                    spacing: 20
                ) {
                    ForEach(wallpapers) { wallpaper in
                        VStack(spacing: 8) {
                            Image(nsImage: getThumbnail(from: wallpaper.path))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(.quaternary, lineWidth: 1)
                                )
                            
                            Text(wallpaper.fileName)
                                .font(.callout)
                                .lineLimit(1)
                                .padding(.horizontal, 5)
                            
                            Text("音量: \(Int(wallpaper.volume * 100))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(.quaternary, lineWidth: 1)
                        )
                        .onTapGesture {
                            let url = URL(fileURLWithPath: wallpaper.path)
                            withAnimation {
                                LiveWallpaperController.shared.setWallpaper(
                                    with: url,
                                    volume: wallpaper.volume
                                )
                                
                                DatabaseManager.shared.saveWallpaper(
                                    path: wallpaper.path,
                                    fileName: wallpaper.fileName,
                                    volume: wallpaper.volume
                                )
                                
                                // 發送通知以更新主介面
                                NotificationCenter.default.post(
                                    name: .wallpaperSelected,
                                    object: nil,
                                    userInfo: [
                                        "url": url,
                                        "volume": wallpaper.volume
                                    ]
                                )
                            }
                        }
                    }
                }
                .padding(15)
            }
            .padding(.bottom, 15)
        }
        .onAppear(perform: loadWallpapers)
        .onReceive(NotificationCenter.default.publisher(for: .wallpaperAdded)) { _ in
            loadWallpapers()
        }
    }
    
    private func loadWallpapers() {
        wallpapers = DatabaseManager.shared.getWallpapers().filter { wallpaper in
            // 嘗試恢復安全作用域存取權限
            if SecurityScopeManager.shared.restoreSecurityScopeAccess(for: wallpaper.path) {
                return FileManager.default.fileExists(atPath: wallpaper.path)
            }
            return false
        }
    }
    
    private func getThumbnail(from path: String) -> NSImage {
        // 確保有權限存取
        guard SecurityScopeManager.shared.restoreSecurityScopeAccess(for: path) else {
            return NSImage(named: "defaultThumbnail") ?? NSImage()
        }
        
        // Return cached thumbnail if available
        if let cachedImage = thumbnailCache[path] {
            return cachedImage
        }
        
        // Verify file exists
        guard FileManager.default.fileExists(atPath: path) else {
            print("File does not exist at path: \(path)")
            return NSImage(named: "defaultThumbnail") ?? NSImage()
        }
        
        let url = URL(fileURLWithPath: path)
        let asset = AVURLAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        // Set maximum size to improve performance
        imageGenerator.maximumSize = CGSize(width: 200, height: 200)
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            let thumbnail = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            // Cache the thumbnail
            thumbnailCache[path] = thumbnail
            return thumbnail
        } catch {
            print("Error generating thumbnail for \(path): \(error)")
            return NSImage(named: "defaultThumbnail") ?? NSImage()
        }
    }
}

extension Notification.Name {
    static let wallpaperAdded = Notification.Name("wallpaperAdded")
    static let wallpaperSelected = Notification.Name("wallpaperSelected")
}
