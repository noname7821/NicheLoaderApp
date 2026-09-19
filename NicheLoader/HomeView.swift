import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @StateObject var certManager = CertificateManager.shared
    @StateObject var libraryManager = LibraryManager.shared
    
    @State private var selectedIPA: URL?
    @State private var showIPAImporter = false
    @State private var showCertPicker = false
    @State private var showAddCert = false
    @State private var isSigning = false
    @State private var progress: Double = 0
    @State private var statusText = "Ready"
    @State private var showContent = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // header
                    VStack(spacing: 8) {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                        Text("NicheLoader")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Sign and install IPAs with ease")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    .opacity(showContent ? 1 : 0)
                    
                    // ipa card
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
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.1), value: showContent)
                    
                    // certificate card
                    card(title: "Certificate", icon: "lock.fill") {
                        VStack(spacing: 10) {
                            if let cert = certManager.selected() {
                                HStack {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.green)
                                    VStack(alignment: .leading) {
                                        Text(cert.name)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text("Selected")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Button("Change") {
                                        showCertPicker = true
                                    }
                                    .font(.caption)
                                    .foregroundColor(.purple)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            } else {
                                Button {
                                    showAddCert = true
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
                    }
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.2), value: showContent)
                    
                    // sign button / progress
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
                        .disabled(selectedIPA == nil)
                        .opacity(selectedIPA == nil ? 0.5 : 1)
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
            .sheet(isPresented: $showAddCert) {
                AddCertificateView()
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
        guard let cert = certManager.selected() else {
            statusText = "No certificate selected"
            return
        }
        
        isSigning = true
        progress = 0
        
        Task {
            do {
                await updateProgress(0.1, "Uploading IPA...")
                try await ServerAPI.uploadIPA(ipa)
                
                await updateProgress(0.3, "Uploading certificate...")
                try await ServerAPI.uploadP12(URL(fileURLWithPath: cert.p12Path))
                
                await updateProgress(0.5, "Uploading provision...")
                try await ServerAPI.uploadProvision(URL(fileURLWithPath: cert.provisionPath))
                
                await updateProgress(0.6, "Sending password...")
                try await ServerAPI.sendPassword(cert.password)
                
                await updateProgress(0.7, "Signing on server...")
                try await ServerAPI.sign()
                
                await updateProgress(0.9, "Downloading signed IPA...")
                try await downloadSignedIPA(name: ipa.lastPathComponent)
                
                await updateProgress(1.0, "Installing...")
                ServerAPI.install()
                
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                
                await MainActor.run {
                    isSigning = false
                    statusText = "Done"
                }
            } catch {
                await MainActor.run {
                    isSigning = false
                    statusText = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func updateProgress(_ value: Double, _ text: String) async {
        await MainActor.run {
            withAnimation { progress = value }
            statusText = text
        }
        try? await Task.sleep(nanoseconds: 200_000_000)
    }
    
    func downloadSignedIPA(name: String) async throws {
        let url = URL(string: "\(ServerAPI.baseURL)/output.ipa")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let path = LibraryManager.shared.signedAppsPath() + "/" + name
        try data.write(to: URL(fileURLWithPath: path))
        
        let appName = name.replacingOccurrences(of: ".ipa", with: "")
        await MainActor.run {
            LibraryManager.shared.add(
                name: appName,
                bundleID: "com.signed.\(appName.lowercased())",
                version: "1.0",
                path: path
            )
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
