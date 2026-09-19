import SwiftUI
import UniformTypeIdentifiers

struct CertificatePickerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var certManager = CertificateManager.shared
    
    var body: some View {
        NavigationView {
            List {
                ForEach(certManager.certificates) { cert in
                    Button {
                        certManager.selectedID = cert.id
                        certManager.save()
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(cert.name)
                                    .font(.headline)
                                Text(cert.date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if certManager.selectedID == cert.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            certManager.delete(cert)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Select Certificate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct AddCertificateView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var certManager = CertificateManager.shared
    
    @State private var name = ""
    @State private var password = ""
    @State private var p12URL: URL?
    @State private var provisionURL: URL?
    @State private var showP12Picker = false
    @State private var showProvisionPicker = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Name") {
                    TextField("Certificate Name", text: $name)
                }
                
                Section("Files") {
                    Button {
                        showP12Picker = true
                    } label: {
                        HStack {
                            Image(systemName: "lock.fill")
                            Text(p12URL?.lastPathComponent ?? "Select .p12 File")
                                .foregroundColor(p12URL != nil ? .purple : .primary)
                        }
                    }
                    
                    Button {
                        showProvisionPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.fill")
                            Text(provisionURL?.lastPathComponent ?? "Select .mobileprovision")
                                .foregroundColor(provisionURL != nil ? .purple : .primary)
                        }
                    }
                }
                
                Section("Password") {
                    SecureField("P12 Password", text: $password)
                }
                
                Section {
                    Button {
                        saveCert()
                    } label: {
                        Text("Save Certificate")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(name.isEmpty || p12URL == nil || provisionURL == nil)
                }
            }
            .navigationTitle("Add Certificate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showP12Picker) {
                DocumentPickerView { url in p12URL = url }
            }
            .sheet(isPresented: $showProvisionPicker) {
                DocumentPickerView { url in provisionURL = url }
            }
        }
    }
    
    func saveCert() {
        guard let p12 = p12URL, let prov = provisionURL else { return }
        
        // copy files to documents
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let certDir = docs.appendingPathComponent("Certificates")
        try? FileManager.default.createDirectory(at: certDir, withIntermediateDirectories: true)
        
        let p12Dest = certDir.appendingPathComponent("\(name).p12")
        let provDest = certDir.appendingPathComponent("\(name).mobileprovision")
        
        try? FileManager.default.removeItem(at: p12Dest)
        try? FileManager.default.removeItem(at: provDest)
        try? FileManager.default.copyItem(at: p12, to: p12Dest)
        try? FileManager.default.copyItem(at: prov, to: provDest)
        
        certManager.add(
            name: name,
            p12Path: p12Dest.path,
            provisionPath: provDest.path,
            password: password
        )
        
        dismiss()
    }
}
