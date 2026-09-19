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
    @State private var showContent = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // header
                    VStack(spacing: 12) {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 70))
                            .foregroundStyle(
                                LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                        Text("NicheLoader")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Sign and install IPAs")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 30)
                    
                    // IPA card
                    card(title: "IPA File", icon: "doc.fill") {
                        Button {
                            showIPAImporter = true
                        } label: {
                            HStack {
                                Text(selectedIPA?.lastPathComponent ?? "Select IPA")
                                    .foregroundColor(selectedIPA != nil ? .purple : .secondary)
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.footnote)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Certificate card
                    card(title: "Certificate", icon: "lock.fill") {
                        if let cert = certManager.selected() {
                            Button {
                                showCertPicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.green)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(cert.name)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        Text("Tap to change")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.footnote)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        } else {
                            Button {
                                showCertPicker = true
                            } label: {
                                HStack {
                                    Text("Add Certificate")
                                        .foregroundColor(.purple)
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.purple)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    // Sign button
                    if isSigning {
                        VStack(spacing: 12) {
                            ProgressView(value: progress)
                                .progressViewStyle(.linear)
                                .tint(.purple)
                            Text(statusText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    } else {
                        Button {
                            startSigning()
                        } label: {
                            HStack {
                                Image(systemName: "signature")
                                Text("Sign & Install")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(15)
                        }
                        .padding(.horizontal)
                        .disabled(selectedIPA == nil || certManager.selected() == nil)
                        .opacity((selectedIPA == nil || certManager.selected() == nil) ? 0.5 : 1)
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showIPAImporter) {
                DocumentPickerView { url in selectedIPA = url }
            }
            .sheet(isPresented: $showCertPicker) {
                CertificatePickerView()
            }
            .onAppear {
                withAnimation { showContent = true }
            }
        }
    }
    
    func card<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.purple)
                Text(title)
                    .font(.headline)
            }
            content()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        .padding(.horizontal)
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
                    errorMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func updateProgress(_ value: Double, _ text: String) async {
        await MainActor.run {
            withAnimation { progress = value }
            statusText = text
        }
        try? await Task.sleep(nanoseconds: 300_000_000)
    }
}

// document picker
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
