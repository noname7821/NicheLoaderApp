import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @StateObject var certManager = CertificateManager.shared
    @StateObject var libraryManager = LibraryManager.shared
    
    @State private var selectedIPA: URL?
    @State private var showIPAImporter = false
    @State private var showCertPicker = false
    @State private var isSigning = false
    @State private var progress: Double = 0
    @State private var statusText = "Ready"
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            List {
                // IPA Section
                Section("IPA File") {
                    Button {
                        showIPAImporter = true
                    } label: {
                        HStack {
                            Text(selectedIPA?.lastPathComponent ?? "Select IPA")
                                .foregroundColor(.blue)
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Certificate Section
                Section("Certificate") {
                    if let cert = certManager.selected() {
                        Button {
                            showCertPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading) {
                                    Text(cert.name)
                                        .foregroundColor(.primary)
                                    Text(cert.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        Button {
                            showCertPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Import Certificate")
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                        }
                    }
                }
                
                // Sign Section
                Section {
                    if isSigning {
                        VStack(spacing: 8) {
                            ProgressView(value: progress)
                                .tint(.blue)
                            Text(statusText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    } else {
                        Button {
                            startSigning()
                        } label: {
                            HStack {
                                Image(systemName: "signature")
                                Text("Sign & Install")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.blue)
                        }
                        .disabled(selectedIPA == nil || certManager.selected() == nil)
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Sign")
            .sheet(isPresented: $showIPAImporter) {
                DocumentPickerView { url in selectedIPA = url }
            }
            .sheet(isPresented: $showCertPicker) {
                CertificatePickerView()
            }
        }
    }
    
    func startSigning() {
        guard let ipa = selectedIPA else { return }
        guard let cert = certManager.selected() else { return }
        
        isSigning = true
        progress = 0
        errorMessage = nil
        
        Task {
            do {
                await updateProgress(0.1, "Reading metadata...")
                let metadata = IPAReader.read(from: ipa.path) ?? IPAMetadata(bundleID: "unknown", name: ipa.lastPathComponent, version: "1.0", iconData: nil)
                
                await updateProgress(0.2, "Uploading IPA...")
                try await ServerAPI.uploadIPA(ipa)
                
                await updateProgress(0.4, "Uploading certificate...")
                try await ServerAPI.uploadP12(certManager.p12URL(for: cert))
                
                await updateProgress(0.5, "Uploading provision...")
                try await ServerAPI.uploadProvision(certManager.provisionURL(for: cert))
                
                await updateProgress(0.6, "Sending password...")
                try await ServerAPI.sendPassword(cert.password)
                
                await updateProgress(0.7, "Signing...")
                try await ServerAPI.sign()
                
                await updateProgress(0.85, "Downloading...")
                let signedData = try await ServerAPI.downloadSignedIPA()
                
                let tempPath = NSTemporaryDirectory() + "/" + ipa.lastPathComponent
                try signedData.write(to: URL(fileURLWithPath: tempPath))
                
                await updateProgress(0.95, "Saving...")
                await MainActor.run {
                    libraryManager.add(
                        name: metadata.name,
                        bundleID: metadata.bundleID,
                        version: metadata.version,
                        ipaPath: tempPath,
                        iconData: metadata.iconData
                    )
                }
                
                await updateProgress(1.0, "Installing...")
                ServerAPI.install()
                
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                
                await MainActor.run {
                    isSigning = false
                    statusText = "Done"
                }
            } catch {
                await MainActor.run {
                    isSigning = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func updateProgress(_ value: Double, _ text: String) async {
        await MainActor.run {
            progress = value
            statusText = text
        }
        try? await Task.sleep(nanoseconds: 300_000_000)
    }
}

struct DocumentPickerView: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
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
