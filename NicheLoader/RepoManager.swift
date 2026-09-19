import Foundation

struct RepoApp: Codable, Identifiable {
    var id: String { bundleIdentifier + version }
    let name: String
    let bundleIdentifier: String
    let version: String
    let downloadURL: String
    let iconURL: String?
    let localizedDescription: String?
    let size: Int?
}

struct Repo: Codable, Identifiable {
    var id: String { url }
    let url: String
    let name: String
    let apps: [RepoApp]
}

class RepoManager: ObservableObject {
    static let shared = RepoManager()
    
    @Published var repos: [Repo] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let storageKey = "nicheloader.repos"
    
    init() {
        load()
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Repo].self, from: data) {
            repos = decoded
        }
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(repos) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    func addRepo(urlString: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: urlString) else {
            error = "Invalid URL"
            completion(false)
            return
        }
        
        isLoading = true
        error = nil
        
        URLSession.shared.dataTask(with: url) { data, _, err in
            DispatchQueue.main.async {
                self.isLoading = false
                
                guard let data = data, err == nil else {
                    self.error = "Failed to load repo"
                    completion(false)
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let name = json["name"] as? String,
                       let appsArray = json["apps"] as? [[String: Any]] {
                        
                        var apps: [RepoApp] = []
                        for appDict in appsArray {
                            if let appName = appDict["name"] as? String,
                               let bundleID = appDict["bundleIdentifier"] as? String,
                               let version = appDict["version"] as? String,
                               let downloadURL = appDict["downloadURL"] as? String {
                                
                                let app = RepoApp(
                                    name: appName,
                                    bundleIdentifier: bundleID,
                                    version: version,
                                    downloadURL: downloadURL,
                                    iconURL: appDict["iconURL"] as? String,
                                    localizedDescription: appDict["localizedDescription"] as? String,
                                    size: appDict["size"] as? Int
                                )
                                apps.append(app)
                            }
                        }
                        
                        let repo = Repo(url: urlString, name: name, apps: apps)
                        
                        // remove old if exists
                        self.repos.removeAll { $0.url == urlString }
                        self.repos.append(repo)
                        self.save()
                        completion(true)
                    } else {
                        self.error = "Invalid repo format"
                        completion(false)
                    }
                } catch {
                    self.error = "Parse error: \(error.localizedDescription)"
                    completion(false)
                }
            }
        }.resume()
    }
    
    func delete(_ repo: Repo) {
        repos.removeAll { $0.url == repo.url }
        save()
    }
}
