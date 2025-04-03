import Foundation

class SecurityScopeManager {
    static let shared = SecurityScopeManager()
    private let bookmarksKey = "securityScopeBookmarks"
    
    func saveSecurityScopeBookmark(for url: URL) {
        do {
            let bookmark = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            var bookmarks = UserDefaults.standard.dictionary(forKey: bookmarksKey) as? [String: Data] ?? [:]
            bookmarks[url.path] = bookmark
            UserDefaults.standard.set(bookmarks, forKey: bookmarksKey)
        } catch {
            print("Failed to save security scope bookmark: \(error)")
        }
    }
    
    func restoreSecurityScopeAccess(for path: String) -> Bool {
        guard let bookmarks = UserDefaults.standard.dictionary(forKey: bookmarksKey) as? [String: Data],
              let bookmark = bookmarks[path] else {
            return false
        }
        
        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: bookmark,
                            options: .withSecurityScope,
                            relativeTo: nil,
                            bookmarkDataIsStale: &isStale)
            
            if isStale {
                return false
            }
            
            return url.startAccessingSecurityScopedResource()
        } catch {
            print("Failed to restore security scope access: \(error)")
            return false
        }
    }

    /// ✅ **新增 `startAccessingSecurityScopedResource(at:)` 方法**
    func startAccessingSecurityScopedResource(at url: URL) -> Bool {
        if url.startAccessingSecurityScopedResource() {
            return true
        } else {
            // 如果無法存取，嘗試透過書籤還原
            return restoreSecurityScopeAccess(for: url.path)
        }
    }
}
