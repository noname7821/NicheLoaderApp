import SwiftUI
import UniformTypeIdentifiers

struct CertificatePickerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var certManager = CertificateManager.shared
    @State private var showAdd = false
    
    var body: some View {
        NavigationView {
            Group {
                if certManager.certificates.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "questionmark.folder.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No Certificates")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Get started signing by importing your first certificate.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button {
                            showAdd = true
                        } label: {
                            Text("Import")
                                .fontWeight(.semibold)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color(.systemGray5))
                                .foregroundColor(.purple)
                                .clipShape(Capsule())
                        }
                    }
                } else {
                    List {
                        ForEach(certManager.certificates) { cert in
                            Button {
                                certManager.selectedID = cert.id
                                certManager.save()
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(certManager.selectedID == cert.id ? .purple : .secondary)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(cert.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text(cert.date.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if certManager.selectedID == cert.id {
                                        Image(systemName: "checkmark")
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
                }
            }
            .navigationTitle("Certificates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddCertificateView()
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
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Files") {
                    Button {
                        showP12Picker = true
                    } label: {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Import Certificate (.p12)")
                                .foregroundColor(.blue)
                            Spacer()
                            if p12URL != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    Button {
                        showProvisionPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Import Provision File")
                                .foregroundColor(.blue)
                            Spacer()
                            if provisionURL != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                Section("Password") {
                    SecureField("Enter password", text: $password)
                }
                Section {
                    Text("Enter the password linked to the private key. Leave empty if no password required.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Nickname (Optional)") {
                    TextField("Name", text: $name)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Certificate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        save()
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save").fontWeight(.bold)
                        }
                    }
                    .disabled(p12URL == nil || provisionURL == nil || isSaving)
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
    
    func save() {
        guard let p12 = p12URL, let prov = provisionURL else { return }
        isSaving = true
        
        let finalName = name.isEmpty ? "Certificate \(certManager.certificates.count + 1)" : name
        
        certManager.add(name: finalName, p12URL: p12, provisionURL: prov, password: password)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isSaving = false
            dismiss()
        }
    }
}
