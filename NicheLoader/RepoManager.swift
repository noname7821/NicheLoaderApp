import Foundation

struct RepoApp: Codable, Identifiable {
    var id: String { bundleIdentifier + "|" + version }
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
    let iconURL: String?
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
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.setValue("NicheLoader/1.0", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, response, err in
            DispatchQueue.main.async {
                self.isLoading = false
                
                guard let data = data, err == nil else {
                    self.error = err?.localizedDescription ?? "Failed to load repo"
                    completion(false)
                    return
                }
                
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        self.error = "Invalid JSON"
                        completion(false)
                        return
                    }
                    
                    let name = json["name"] as? String ?? "Unknown Repo"
                    let repoIcon = json["iconURL"] as? String
                    
                    guard let appsArray = json["apps"] as? [[String: Any]] else {
                        self.error = "No apps in repo"
                        completion(false)
                        return
                    }
                    
                    var apps: [RepoApp] = []
                    for appDict in appsArray {
                        guard let appName = appDict["name"] as? String,
                              let bundleID = appDict["bundleIdentifier"] as? String else {
                            continue
                        }
                        
                        // version can be string or number
                        var version = "1.0"
                        if let v = appDict["version"] as? String {
                            version = v
                        } else if let v = appDict["version"] as? NSNumber {
                            version = "\(v)"
                        }
                        
                        // downloadURL - check both keys
                        var downloadURL: String? = appDict["downloadURL"] as? String
                        if downloadURL == nil, let versions = appDict["versions"] as? [[String: Any]], let first = versions.first {
                            downloadURL = first["downloadURL"] as? String
                            if let v = first["version"] as? String { version = v }
                        }
                        
                        guard let dlURL = downloadURL else { continue }
                        
                        // icon
                        var iconURL: String? = appDict["iconURL"] as? String
                        if iconURL == nil, let versions = appDict["versions"] as? [[String: Any]], let first = versions.first {
                            iconURL = first["iconURL"] as? String
                        }
                        
                        let desc = appDict["subtitle"] as? String ?? appDict["localizedDescription"] as? String
                        
                        apps.append(RepoApp(
                            name: appName,
                            bundleIdentifier: bundleID,
                            version: version,
                            downloadURL: dlURL,
                            iconURL: iconURL,
                            localizedDescription: desc,
                            size: appDict["size"] as? Int
                        ))
                    }
                    
                    let repo = Repo(url: urlString, name: name, iconURL: repoIcon, apps: apps)
                    
                    self.repos.removeAll { $0.url == urlString }
                    self.repos.append(repo)
                    self.save()
                    print("[RepoManager] Loaded \(apps.count) apps from \(name)")
                    completion(true)
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
