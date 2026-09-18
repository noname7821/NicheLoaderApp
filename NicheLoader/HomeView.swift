import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @State private var selectedIPA: URL?
    @State private var p12File: URL?
    @State private var provisionFile: URL?
    @State private var password: String = ""
    @State private var statusText: String = "Ready"
    @State private var isSigning: Bool = false
    @State private var showIPAImporter: Bool = false
    @State private var showP12Importer: Bool = false
    @State private var showProvisionImporter: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Files") {
                    Button {
                        DispatchQueue.main.async {
                            showIPAImporter = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "doc.fill")
                            Text(selectedIPA?.lastPathComponent ?? "Select IPA")
                                .foregroundColor(selectedIPA != nil ? .purple : .primary)
                        }
                    }
                    
                    Button {
                        DispatchQueue.main.async {
                            showP12Importer = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "lock.fill")
                            Text(p12File?.lastPathComponent ?? "Select Certificate (.p12)")
                                .foregroundColor(p12File != nil ? .purple : .primary)
                        }
                    }
                    
                    Button {
                        DispatchQueue.main.async {
                            showProvisionImporter = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.fill")
                            Text(provisionFile?.lastPathComponent ?? "Select Provision (.mobileprovision)")
                                .foregroundColor(provisionFile != nil ? .purple : .primary)
                        }
                    }
                }
                
                Section("Certificate Password") {
                    SecureField("Password", text: $password)
                }
                
                Section {
                    Button {
                        startSigning()
                    } label: {
                        HStack {
                            Spacer()
                            if isSigning {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                Text("Signing...")
                                    .padding(.leading, 8)
                            } else {
                                Image(systemName: "signature")
                                Text("Sign & Install")
                                    .fontWeight(.bold)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .disabled(selectedIPA == nil || isSigning)
                    .listRowBackground(Color.purple.opacity(0.2))
                }
                
                Section("Status") {
                    Text(statusText)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("NicheLoader")
            .sheet(isPresented: $showIPAImporter) {
                DocumentPickerView { url in
                    selectedIPA = url
                }
            }
            .sheet(isPresented: $showP12Importer) {
                DocumentPickerView { url in
                    p12File = url
                }
            }
            .sheet(isPresented: $showProvisionImporter) {
                DocumentPickerView { url in
                    provisionFile = url
                }
            }
        }
    }
    
    func startSigning() {
        guard let ipa = selectedIPA else { return }
        isSigning = true
        statusText = "Uploading IPA..."
        
        Task {
            do {
                try await ServerAPI.uploadIPA(ipa)
                statusText = "IPA uploaded ✓"
                
                if let p12 = p12File, let prov = provisionFile {
                    statusText = "Uploading certificate..."
                    try await ServerAPI.uploadP12(p12)
                    
                    statusText = "Uploading provision..."
                    try await ServerAPI.uploadProvision(prov)
                    
                    statusText = "Sending password..."
                    try await ServerAPI.sendPassword(password)
                }
                
                statusText = "Signing on server..."
                try await ServerAPI.sign()
                
                statusText = "Installing..."
                await MainActor.run {
                    ServerAPI.install()
                }
                
                statusText = "Done ✓"
            } catch {
                statusText = "Error: \(error.localizedDescription)"
            }
            isSigning = false
        }
    }
}

// document picker
struct DocumentPickerView: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}
