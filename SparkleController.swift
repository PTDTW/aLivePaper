//import Sparkle
//import Foundation
//import SwiftUI
//
//class SparkleController: NSObject, ObservableObject {
//    private var updater: SPUUpdater
//    private var automaticUpdateChecker: SPUAutomaticUpdateDriver
//
//    override init() {
//        // 獲取主應用程式的 Bundle
//        let hostBundle = Bundle.main
//        // 使用 Sparkle 的配置來設置 updater
//        let sparkleConfiguration = SPUStandardUpdaterConfiguration(hostBundle: hostBundle)
//        
//        // 配置 updater，並指定自動更新的驅動和隊列
//        updater = SPUUpdater(hostBundle: hostBundle, applicationBundle: hostBundle, userDriverDelegate: nil, delegateQueue: .main)
//        
//        // 嘗試啟動 updater
//        do {
//            try updater.start()
//        } catch {
//            print("Failed to start SPUUpdater:", error.localizedDescription)
//        }
//        
//        // 初始化自動更新驅動器
//        automaticUpdateChecker = SPUAutomaticUpdateDriver(updater: updater, configuration: sparkleConfiguration)
//
//        // 呼叫超類別初始化方法
//        super.init()
//    }
//    
//    // 檢查更新的方法
//    func checkForUpdates() {
//        updater.checkForUpdates()
//    }
//}
