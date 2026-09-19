import Foundation
import UIKit
import ZIPFoundation

struct IPAMetadata {
    let bundleID: String
    let name: String
    let version: String
    let iconData: Data?
}

class IPAReader {
    static func read(from ipaPath: String) -> IPAMetadata? {
        guard let archive = try? Archive(url: URL(fileURLWithPath: ipaPath), accessMode: .read) else {
            print("[IPAReader] Failed to open archive")
            return nil
        }
        
        var infoPlistData: Data?
        var bundlePath = ""
        var iconNames: [String] = []
        
        for entry in archive {
            if entry.path.contains("Payload/") && entry.path.hasSuffix(".app/Info.plist") {
                var data = Data()
                _ = try? archive.extract(entry) { chunk in data.append(chunk) }
                infoPlistData = data
                bundlePath = entry.path.replacingOccurrences(of: "Info.plist", with: "")
                break
            }
        }
        
        guard let plistData = infoPlistData,
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
            print("[IPAReader] Failed to read Info.plist")
            return nil
        }
        
        let bundleID = plist["CFBundleIdentifier"] as? String ?? "unknown"
        let name = (plist["CFBundleDisplayName"] as? String) ?? (plist["CFBundleName"] as? String) ?? "Unknown"
        let version = plist["CFBundleShortVersionString"] as? String ?? "1.0"
        
        if let icons = plist["CFBundleIcons"] as? [String: Any],
           let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let files = primary["CFBundleIconFiles"] as? [String] {
            iconNames = files
        } else if let files = plist["CFBundleIconFiles"] as? [String] {
            iconNames = files
        }
        
        var iconData: Data?
        var bestSize: Int = 0
        
        for entry in archive {
            guard entry.path.hasPrefix(bundlePath) else { continue }
            let filename = (entry.path as NSString).lastPathComponent
            
            for iconName in iconNames {
                if filename.hasPrefix(iconName) && filename.hasSuffix(".png") {
                    var data = Data()
                    _ = try? archive.extract(entry) { chunk in data.append(chunk) }
                    if let img = UIImage(data: data), data.count > bestSize {
                        iconData = img.pngData()
                        bestSize = data.count
                    }
                }
            }
        }
        
        if iconData == nil {
            for entry in archive {
                guard entry.path.hasPrefix(bundlePath) else { continue }
                let filename = (entry.path as NSString).lastPathComponent
                if (filename.hasPrefix("AppIcon") || filename.contains("60x60") || filename.contains("1024")) && filename.hasSuffix(".png") {
                    var data = Data()
                    _ = try? archive.extract(entry) { chunk in data.append(chunk) }
                    if let img = UIImage(data: data) {
                        iconData = img.pngData()
                        break
                    }
                }
            }
        }
        
        print("[IPAReader] \(name) - \(bundleID) - v\(version) - icon: \(iconData != nil)")
        
        return IPAMetadata(bundleID: bundleID, name: name, version: version, iconData: iconData)
    }
}
