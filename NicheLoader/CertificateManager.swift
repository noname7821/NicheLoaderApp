import Foundation

struct Certificate: Codable, Identifiable {
    let id: UUID
    let name: String
    let p12FileName: String
    let provisionFileName: String
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
    
    func add(name: String, p12URL: URL, provisionURL: URL, password: String) {
        let id = UUID()
        let certDir = certDirectory(forID: id)
        try? FileManager.default.createDirectory(at: certDir, withIntermediateDirectories: true)
        
        let p12Name = "cert.p12"
        let provName = "cert.mobileprovision"
        
        let p12Dest = certDir.appendingPathComponent(p12Name)
        let provDest = certDir.appendingPathComponent(provName)
        
        try? FileManager.default.removeItem(at: p12Dest)
        try? FileManager.default.removeItem(at: provDest)
        
        // copy from temp
        if let data = try? Data(contentsOf: p12URL) {
            try? data.write(to: p12Dest)
        }
        if let data = try? Data(contentsOf: provisionURL) {
            try? data.write(to: provDest)
        }
        
        let cert = Certificate(
            id: id,
            name: name,
            p12FileName: p12Name,
            provisionFileName: provName,
            password: password,
            date: Date()
        )
        certificates.append(cert)
        if selectedID == nil { selectedID = cert.id }
        save()
    }
    
    func delete(_ cert: Certificate) {
        let dir = certDirectory(forID: cert.id)
        try? FileManager.default.removeItem(at: dir)
        certificates.removeAll { $0.id == cert.id }
        if selectedID == cert.id {
            selectedID = certificates.first?.id
        }
        save()
    }
    
    func selected() -> Certificate? {
        certificates.first { $0.id == selectedID }
    }
    
    func p12URL(for cert: Certificate) -> URL {
        return certDirectory(forID: cert.id).appendingPathComponent(cert.p12FileName)
    }
    
    func provisionURL(for cert: Certificate) -> URL {
        return certDirectory(forID: cert.id).appendingPathComponent(cert.provisionFileName)
    }
    
    private func certDirectory(forID id: UUID) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("Certificates").appendingPathComponent(id.uuidString)
    }
}
