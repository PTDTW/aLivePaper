import SwiftUI

@main
struct aLivePaperApp: App {
    @StateObject private var statusBarController = StatusBarController()
    
    init() {
        // 检查系统版本
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        if osVersion.majorVersion < 12 {  // macOS 12 Monterey
            NSAlert.showWarning(
                title: "系統版本過低",
                message: "此應用程式需要 macOS 12.0 (Monterey) 或更新版本。"
            )
        }
        
        // 將應用設置為 accessory 模式，隱藏在 Dock 中
        NSApplication.shared.setActivationPolicy(.accessory)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1200, minHeight: 800)
                .onAppear {
                    // 確保狀態列圖示初始化
                    _ = statusBarController
                    
                    // 設置視窗大小限制
                    if let window = NSApplication.shared.windows.first {
                        // 可選：此處先插入再移除 .resizable 確保視窗無法縮放
                        window.styleMask.insert(.resizable)
                        window.styleMask.remove(.resizable)
                        
                        window.minSize = NSSize(width: 1200, height: 800)
                        window.maxSize = NSSize(width: 1200, height: 800)
                        window.setContentSize(NSSize(width: 1200, height: 800))
                    }
                }
                .onDisappear {
                    // 當視窗關閉時，保持應用以 accessory 模式運行
                    NSApplication.shared.setActivationPolicy(.accessory)
                }
        }
    }
}

extension NSAlert {
    static func showWarning(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }
}
