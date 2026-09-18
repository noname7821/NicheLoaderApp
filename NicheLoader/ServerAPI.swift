import Foundation
import UIKit

struct ServerAPI {
    static let baseURL = "https://nicheloader.onrender.com"
    
    static func uploadIPA(_ url: URL) async throws {
        let data = try Data(contentsOf: url)
        var request = URLRequest(url: URL(string: "\(baseURL)/input.ipa")!)
        request.httpMethod = "PUT"
        request.httpBody = data
        request.timeoutInterval = 600
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "ServerAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "IPA upload failed"])
        }
    }
    
    static func uploadP12(_ url: URL) async throws {
        let data = try Data(contentsOf: url)
        var request = URLRequest(url: URL(string: "\(baseURL)/cert.p12")!)
        request.httpMethod = "PUT"
        request.httpBody = data
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "ServerAPI", code: 2, userInfo: [NSLocalizedDescriptionKey: "P12 upload failed"])
        }
    }
    
    static func uploadProvision(_ url: URL) async throws {
        let data = try Data(contentsOf: url)
        var request = URLRequest(url: URL(string: "\(baseURL)/cert.mobileprovision")!)
        request.httpMethod = "PUT"
        request.httpBody = data
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "ServerAPI", code: 3, userInfo: [NSLocalizedDescriptionKey: "Provision upload failed"])
        }
    }
    
    static func sendPassword(_ password: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/password")!)
        request.httpMethod = "POST"
        request.httpBody = password.data(using: .utf8)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "ServerAPI", code: 4, userInfo: [NSLocalizedDescriptionKey: "Password send failed"])
        }
    }
    
    static func sign() async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/sign")!)
        request.httpMethod = "PUT"
        request.timeoutInterval = 600
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "unknown"
            throw NSError(domain: "ServerAPI", code: 5, userInfo: [NSLocalizedDescriptionKey: "Sign failed: \(errorText)"])
        }
    }
    
    static func install() {
        let manifestURL = "itms-services://?action=download-manifest&url=\(baseURL)/manifest.plist"
        if let url = URL(string: manifestURL) {
            UIApplication.shared.open(url)
        }
    }
}
