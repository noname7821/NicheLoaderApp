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
    @State private var showContent: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Files") {
                    Button {
                        showIPAImporter = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.fill")
                            Text(selectedIPA?.lastPathComponent ?? "Select IPA")
                                .foregroundColor(selectedIPA != nil ? .purple : .primary)
                        }
                    }
                    
                    Button {
                        showP12Importer = true
                    } label: {
                        HStack {
                            Image(systemName: "lock.fill")
                            Text(p12File?.lastPathComponent ?? "Select Certificate (.p12)")
                                .foregroundColor(p12File != nil ? .purple : .primary)
                        }
                    }
                    
                    Button {
                        showProvisionImporter = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.fill")
                            Text(provisionFile?.lastPathComponent ?? "Select Provision (.mobileprovision)")
                                .foregroundColor(provisionFile != nil ? .purple : .primary)
                        }
                    }
                }
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.4).delay(0.05), value: showContent)
                
                Section("Certificate Password") {
                    SecureField("Password", text: $password)
                }
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.4).delay(0.1), value: showContent)
                
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
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.4).delay(0.15), value: showContent)
                
                Section("Status") {
                    Text(statusText)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: showContent)
            }
            .navigationTitle("NicheLoader")
            .sheet(isPresented: $showIPAImporter) {
                DocumentPickerView { url in selectedIPA = url }
            }
            .sheet(isPresented: $showP12Importer) {
                DocumentPickerView { url in p12File = url }
            }
            .sheet(isPresented: $showProvisionImporter) {
                DocumentPickerView { url in provisionFile = url }
            }
            .onAppear {
                withAnimation {
                    showContent = true
                }
            }
        }
    }
    
    func startSigning() {
        guard let ipa = selectedIPA else { return }
        isSigning = true
        
        withAnimation {
            statusText = "Uploading IPA..."
        }
        
        Task {
            do {
                try await ServerAPI.uploadIPA(ipa)
                await MainActor.run {
                    withAnimation { statusText = "IPA uploaded" }
                }
                
                if let p12 = p12File, let prov = provisionFile {
                    await MainActor.run {
                        withAnimation { statusText = "Uploading certificate..." }
                    }
                    try await ServerAPI.uploadP12(p12)
                    
                    await MainActor.run {
                        withAnimation { statusText = "Uploading provision..." }
                    }
                    try await ServerAPI.uploadProvision(prov)
                    
                    await MainActor.run {
                        withAnimation { statusText = "Sending password..." }
                    }
                    try await ServerAPI.sendPassword(password)
                }
                
                await MainActor.run {
                    withAnimation { statusText = "Signing on server..." }
                }
                try await ServerAPI.sign()
                
                await MainActor.run {
                    withAnimation { statusText = "Installing..." }
                    ServerAPI.install()
                }
                
                await MainActor.run {
                    withAnimation { statusText = "Done" }
                }
            } catch {
                await MainActor.run {
                    withAnimation { statusText = "Error: \(error.localizedDescription)" }
                }
            }
            await MainActor.run {
                isSigning = false
            }
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
