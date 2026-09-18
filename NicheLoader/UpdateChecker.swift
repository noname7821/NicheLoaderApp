import Foundation
import UIKit

class UpdateChecker {
    static let versionURL = "https://raw.githubusercontent.com/noname7821/NicheLoaderApp/main/updates/version.txt"
    static let urlURL = "https://raw.githubusercontent.com/noname7821/NicheLoaderApp/main/updates/url.txt"
    static let messageURL = "https://raw.githubusercontent.com/noname7821/NicheLoaderApp/main/updates/message.txt"
    static let bodyURL = "https://raw.githubusercontent.com/noname7821/NicheLoaderApp/main/updates/body.txt"
    
    static func checkForUpdates(completion: @escaping (String?, String?, String?, String?) -> Void) {
        let localVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let group = DispatchGroup()
        var remoteVersion: String?
        var remoteURL: String?
        var remoteMessage: String?
        var remoteBody: String?
        
        group.enter()
        fetchText(versionURL) { text in
            remoteVersion = text?.trimmingCharacters(in: .whitespacesAndNewlines)
            group.leave()
        }
        group.enter()
        fetchText(urlURL) { text in
            remoteURL = text?.trimmingCharacters(in: .whitespacesAndNewlines)
            group.leave()
        }
        group.enter()
        fetchText(messageURL) { text in
            remoteMessage = text?.trimmingCharacters(in: .whitespacesAndNewlines)
            group.leave()
        }
        group.enter()
        fetchText(bodyURL) { text in
            remoteBody = text?.trimmingCharacters(in: .whitespacesAndNewlines)
            group.leave()
        }
        
        group.notify(queue: .main) {
            guard let remote = remoteVersion else {
                completion(nil, nil, nil, nil)
                return
            }
            if isNewer(remote: remote, local: localVersion) {
                completion(remoteVersion, remoteURL, remoteMessage, remoteBody)
            } else {
                completion(nil, nil, nil, nil)
            }
        }
    }
    
    static func fetchText(_ urlString: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let text = String(data: data, encoding: .utf8) {
                completion(text)
            } else {
                completion(nil)
            }
        }.resume()
    }
    
    static func isNewer(remote: String, local: String) -> Bool {
        let r = remote.split(separator: ".").compactMap { Int($0) }
        let l = local.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(r.count, l.count) {
            let rv = i < r.count ? r[i] : 0
            let lv = i < l.count ? l[i] : 0
            if rv > lv { return true }
            if rv < lv { return false }
        }
        return false
    }
}
