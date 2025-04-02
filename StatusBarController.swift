import Cocoa
import SwiftUI
import Sparkle

// 自定義視窗類，增加關閉行為控制
class MainWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    
    override func close() {
        // 關閉時只隱藏視窗
        self.orderOut(nil)
    }
}

// 讓 StatusBarController 繼承 NSObject 並符合 NSWindowDelegate 協議
class StatusBarController: NSObject, ObservableObject, NSWindowDelegate {
    private var statusItem: NSStatusItem!
    private var mainWindow: MainWindow?
    private var updater = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil).updater
    
    override init() {
//        sparkle = SparkleController()
        super.init()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "star.fill", accessibilityDescription: "Live Wallpaper")
        }
        statusItem.menu = createStatusMenu()
    }

    func createStatusMenu() -> NSMenu {
        let menu = NSMenu()

        // 打開應用程式選項
        let openAppItem = NSMenuItem(title: "打開應用程式", action: #selector(openApp), keyEquivalent: "O")
        openAppItem.target = self
        menu.addItem(openAppItem)

        // 更新 Sparkle 選項
        let checkUpdateItem = NSMenuItem(title: "檢查更新...", action: #selector(checkForUpdates), keyEquivalent: "U")
        checkUpdateItem.target = self
        menu.addItem(checkUpdateItem)
        
        menu.addItem(NSMenuItem.separator())

        // 退出選項
        let quitItem = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "Q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    @objc func openApp() {
        if let existingWindow = mainWindow {
            // 如果視窗已存在，則顯示它
            existingWindow.makeKeyAndOrderFront(nil)
        } else {
            // 創建新視窗
            let window = MainWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
                styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            
            let contentView = ContentView()
            let hostingView = NSHostingView(rootView: contentView)
            window.contentView = hostingView
            
            window.center()
            window.title = ""
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
            
            window.minSize = NSSize(width: 1200, height: 800)
            window.maxSize = NSSize(width: 1200, height: 800)
            window.setContentSize(NSSize(width: 1200, height: 800))
            
            // 設置代理以處理視窗關閉事件
            window.delegate = self
            
            window.makeKeyAndOrderFront(nil)
            window.level = .normal
            
            // 保存視窗引用
            mainWindow = window
        }
        
        NSApp.activate(ignoringOtherApps: true)
    }

    // 更新檢查方法
    @objc func checkForUpdates() {
        updater.checkForUpdates()
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(self)
    }
    
    // NSWindowDelegate 方法：視窗將要關閉時僅隱藏視窗
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            window.orderOut(nil)
        }
    }
}
