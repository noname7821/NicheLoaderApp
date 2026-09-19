import Foundation
import UIKit

struct ServerAPI {
    static let baseURL = "https://nicheloader.onrender.com"
    
    static func uploadIPA(_ url: URL) async throws {
        let data = try Data(contentsOf: url)
        try await put(url: "/input.ipa", data: data)
    }
    
    static func uploadP12(_ url: URL) async throws {
        let data = try Data(contentsOf: url)
        try await put(url: "/cert.p12", data: data)
    }
    
    static func uploadProvision(_ url: URL) async throws {
        let data = try Data(contentsOf: url)
        try await put(url: "/cert.mobileprovision", data: data)
    }
    
    static func sendPassword(_ password: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/password")!)
        request.httpMethod = "POST"
        request.httpBody = password.data(using: .utf8)
        request.timeoutInterval = 60
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let text = String(data: data, encoding: .utf8) ?? "unknown"
            throw NSError(domain: "Server", code: (response as? HTTPURLResponse)?.statusCode ?? 0, userInfo: [NSLocalizedDescriptionKey: "Password: \(text)"])
        }
    }
    
    static func sign() async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/sign")!)
        request.httpMethod = "PUT"
        request.timeoutInterval = 600
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let text = String(data: data, encoding: .utf8) ?? "unknown"
            throw NSError(domain: "Server", code: (response as? HTTPURLResponse)?.statusCode ?? 0, userInfo: [NSLocalizedDescriptionKey: "Sign: \(text)"])
        }
    }
    
    static func downloadSignedIPA() async throws -> Data {
        let url = URL(string: "\(baseURL)/output.ipa")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NSError(domain: "Server", code: (response as? HTTPURLResponse)?.statusCode ?? 0, userInfo: [NSLocalizedDescriptionKey: "Download failed"])
        }
        return data
    }
    
    static func install() {
        let manifestURL = "itms-services://?action=download-manifest&url=\(baseURL)/manifest.plist"
        if let url = URL(string: manifestURL) {
            UIApplication.shared.open(url)
        }
    }
    
    static func reset() async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/reset")!)
        request.httpMethod = "POST"
        _ = try await URLSession.shared.data(for: request)
    }
    
    private static func put(url: String, data: Data) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)\(url)")!)
        request.httpMethod = "PUT"
        request.httpBody = data
        request.timeoutInterval = 600
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let text = String(data: responseData, encoding: .utf8) ?? "unknown"
            throw NSError(domain: "Server", code: (response as? HTTPURLResponse)?.statusCode ?? 0, userInfo: [NSLocalizedDescriptionKey: "Upload failed: \(text)"])
        }
    }
}
