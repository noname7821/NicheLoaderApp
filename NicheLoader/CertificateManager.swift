import Foundation

struct Certificate: Codable, Identifiable {
    let id: UUID
    let name: String
    let p12Path: String
    let provisionPath: String
    let password: String
    let date: Date
}

class CertificateManager: ObservableObject {
    static let shared = CertificateManager()
    
    @Published var certificates: [Certificate] = []
    @Published var selectedID: UUID?
    
    private let storageKey = "nicheloader.certificates"
    private let selectedKey = "nicheloader.selectedCert"
    
    init() {
        load()
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Certificate].self, from: data) {
            certificates = decoded
        }
        if let idString = UserDefaults.standard.string(forKey: selectedKey),
           let id = UUID(uuidString: idString) {
            selectedID = id
        }
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(certificates) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        UserDefaults.standard.set(selectedID?.uuidString, forKey: selectedKey)
    }
    
    func add(name: String, p12Path: String, provisionPath: String, password: String) {
        let cert = Certificate(
            id: UUID(),
            name: name,
            p12Path: p12Path,
            provisionPath: provisionPath,
            password: password,
            date: Date()
        )
        certificates.append(cert)
        if selectedID == nil { selectedID = cert.id }
        save()
    }
    
    func delete(_ cert: Certificate) {
        certificates.removeAll { $0.id == cert.id }
        if selectedID == cert.id {
            selectedID = certificates.first?.id
        }
        save()
    }
    
    func selected() -> Certificate? {
        certificates.first { $0.id == selectedID }
    }
}
