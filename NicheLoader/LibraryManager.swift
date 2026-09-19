import Foundation

struct SignedApp: Codable, Identifiable {
    let id: UUID
    let name: String
    let bundleID: String
    let version: String
    let path: String
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
    
    func add(name: String, bundleID: String, version: String, path: String) {
        let app = SignedApp(id: UUID(), name: name, bundleID: bundleID, version: version, path: path, date: Date())
        apps.insert(app, at: 0)
        save()
    }
    
    func delete(_ app: SignedApp) {
        try? FileManager.default.removeItem(atPath: app.path)
        apps.removeAll { $0.id == app.id }
        save()
    }
    
    func documentsPath() -> String {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.path()
    }
    
    func signedAppsPath() -> String {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let signed = docs.appendingPathComponent("Signed")
        try? FileManager.default.createDirectory(at: signed, withIntermediateDirectories: true)
        return signed.path()
    }
}
