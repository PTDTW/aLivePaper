import Foundation

struct WallpaperRecord: Identifiable {
    let id: Int64
    let path: String
    let fileName: String
    let lastUsed: Date
    let volume: Float
}
