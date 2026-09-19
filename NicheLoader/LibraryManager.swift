import Foundation
import UIKit

struct SignedApp: Codable, Identifiable {
    let id: UUID
    let name: String
    let bundleID: String
    let version: String
    let ipaPath: String
    let iconFileName: String?
    let date: Date
}

class LibraryManager: ObservableObject {
    static let shared = LibraryManager()
    
    @Published var apps: [SignedApp] = []
    
    private let storageKey = "nicheloader.library"
    
    init() {
        load()
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([SignedApp].self, from: data) {
            apps = decoded
        }
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(apps) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    func add(name: String, bundleID: String, version: String, ipaPath: String, iconData: Data?) {
        let id = UUID()
        
        // move IPA into app dir
        let appDir = appDirectory(forID: id)
        let ipaFileName = (ipaPath as NSString).lastPathComponent
        let destIPA = appDir.appendingPathComponent(ipaFileName)
        try? FileManager.default.removeItem(at: destIPA)
        try? FileManager.default.copyItem(at: URL(fileURLWithPath: ipaPath), to: destIPA)
        
        // save icon
        var iconFileName: String? = nil
        if let iconData = iconData {
            let iconFile = appDir.appendingPathComponent("AppIcon.png")
            try? iconData.write(to: iconFile)
            iconFileName = "AppIcon.png"
        }
        
        let app = SignedApp(
            id: id,
            name: name,
            bundleID: bundleID,
            version: version,
            ipaPath: destIPA.path,
            iconFileName: iconFileName,
            date: Date()
        )
        apps.insert(app, at: 0)
        save()
    }
    
    func delete(_ app: SignedApp) {
        let appDir = appDirectory(forID: app.id)
        try? FileManager.default.removeItem(at: appDir)
        apps.removeAll { $0.id == app.id }
        save()
    }
    
    func appDirectory(forID id: UUID) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Apps").appendingPathComponent(id.uuidString)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    func appDirectory(for app: SignedApp) -> URL {
        return appDirectory(forID: app.id)
    }
    
    func iconImage(for app: SignedApp) -> UIImage? {
        guard let fileName = app.iconFileName else { return nil }
        let iconPath = appDirectory(for: app).appendingPathComponent(fileName)
        return UIImage(contentsOfFile: iconPath.path)
    }
}
