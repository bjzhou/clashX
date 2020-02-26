
import Alamofire
import AppKit
import Foundation
import CommonCrypto

class ClashResourceManager {
    static let kProxyConfigFolder = (NSHomeDirectory() as NSString).appendingPathComponent("/.config/clash")

    static func check() -> Bool {
        checkConfigDir()
        checkMMDB()
        upgardeYmlExtensionName()
        checkAndRemoveOldErrorConfig()
        return true
    }

    static func checkConfigDir() {
        var isDir: ObjCBool = true

        if !FileManager.default.fileExists(atPath: kProxyConfigFolder, isDirectory: &isDir) {
            do {
                try FileManager.default.createDirectory(atPath: kProxyConfigFolder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                showCreateConfigDirFailAlert()
            }
        }
    }

    static func checkMMDB() {
        let fileManage = FileManager.default
        let destMMDBPath = "\(kProxyConfigFolder)/Country.mmdb"

        // Remove old mmdb file after version update.
        if fileManage.fileExists(atPath: destMMDBPath) {
            if AppVersionUtil.hasVersionChanged || AppVersionUtil.isFirstLaunch {
                try? fileManage.removeItem(atPath: destMMDBPath)
            }
        }

        if !fileManage.fileExists(atPath: destMMDBPath) {
            if let mmdbPath = Bundle.main.path(forResource: "Country", ofType: "mmdb") {
                try? fileManage.copyItem(at: URL(fileURLWithPath: mmdbPath), to: URL(fileURLWithPath: destMMDBPath))
            }
        }
    }

    static func checkAndRemoveOldErrorConfig() {
        if FileManager.default.fileExists(atPath: kDefaultConfigFilePath) {
            do {
                let defaultConfigData = try Data(contentsOf: URL(fileURLWithPath: kDefaultConfigFilePath))
                Logger.log("config file md5: \(defaultConfigData.md5)")
                if defaultConfigData.md5 != "913162c2ba44981a4db8fbc5fb8c48e6" {
                    // old error config
                    Logger.log("removing old config.yaml")
                    try FileManager.default.removeItem(atPath: kDefaultConfigFilePath)
                }
            } catch let err {
                Logger.log("removing old config.yaml fail: \(err.localizedDescription)")
            }
        }
    }

    static func upgardeYmlExtensionName() {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: kConfigFolderPath, isDirectory: true), includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants])

            for upgradeUrl in fileURLs.filter({ $0.pathExtension == "yml" }) {
                let dest = upgradeUrl.deletingPathExtension().appendingPathExtension("yaml")
                try FileManager.default.moveItem(at: upgradeUrl, to: dest)
            }

        } catch let err {
            Logger.log(err.localizedDescription)
        }
    }

    static func showCreateConfigDirFailAlert() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("ClashX fail to create ~/.config/clash folder. Please check privileges or manually create folder and restart ClashX.", comment: "")
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("Quit", comment: ""))
        alert.runModal()
        NSApplication.shared.terminate(nil)
    }
}

extension ClashResourceManager {
    static func addUpdateMMDBMenuItem(_ menu: inout NSMenu) {
        let item = NSMenuItem(title: NSLocalizedString("Update GEOIP Database", comment: ""), action: #selector(updateGeoIP), keyEquivalent: "")
        item.target = self
        menu.addItem(item)
    }

    @objc private static func updateGeoIP() {
        let url = "https://static.clash.to/GeoIP2/GeoIP2-Country.mmdb"
        AF.download(url) { (_, _) -> (destinationURL: URL, options: DownloadRequest.Options) in
            let path = ClashResourceManager.kProxyConfigFolder.appending("/Country.mmdb")
            return (URL(fileURLWithPath: path), .removePreviousFile)
        }.response { res in
            let title = NSLocalizedString("Update GEOIP Database", comment: "")
            let info: String
            switch res.result {
            case .success:
                info = NSLocalizedString("Success!", comment: "")
            case let .failure(err):
                info = NSLocalizedString("Fail:", comment: "") + err.localizedDescription
            }
            NSUserNotificationCenter.default.post(title: title, info: info)
        }
    }
}

extension Data {
    var md5: String {
        let hash = self.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            CC_MD5(bytes.baseAddress, CC_LONG(self.count), &hash)
            return hash
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
