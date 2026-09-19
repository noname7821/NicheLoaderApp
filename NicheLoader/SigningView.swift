import SwiftUI
import UniformTypeIdentifiers

struct SigningView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var certManager = CertificateManager.shared
    @StateObject var libraryManager = LibraryManager.shared
    
    let ipaURL: URL
    
    @State private var appName: String = ""
    @State private var bundleID: String = ""
    @State private var appVersion: String = ""
    @State private var iconData: Data?
    @State private var showCertPicker = false
    @State private var isSigning = false
    @State private var progress: Double = 0
    @State private var statusText = "Ready"
    @State private var errorMessage: String?
    @State private var showAdvanced = false
    @State private var isLoadingMetadata = true
    
    var body: some View {
        NavigationView {
            Form {
                // Anpassungen / Customization
                Section("Customization") {
                    HStack(spacing: 16) {
                        if let iconData = iconData, let uiImage = UIImage(data: iconData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 13))
                        } else {
                            RoundedRectangle(cornerRadius: 13)
                                .fill(Color(.systemGray5))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "app.fill")
                                        .foregroundColor(.purple)
                                        .font(.title2)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("App Icon")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Default")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    fieldRow("Name", value: $appName, placeholder: "App Name")
                    fieldRow("Identifier", value: $bundleID, placeholder: "com.example.app")
                    fieldRow("Version", value: $appVersion, placeholder: "1.0")
                }
                
                // Signierung / Signing
                Section("Signing") {
                    Button {
                        showCertPicker = true
                    } label: {
                        if let cert = certManager.selected() {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(cert.name)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                Text(cert.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 8) {
                                    pill("Valid", color: .green)
                                    pill("30 days", color: .purple)
                                }
                                .padding(.top, 4)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.purple)
                                Text("Select Certificate")
                                    .foregroundColor(.purple)
                                Spacer()
                            }
                        }
                    }
                }
                
                // Erweitert / Advanced
                Section("Advanced") {
                    DisclosureGroup("Modify", isExpanded: $showAdvanced) {
                        Text("Dylibs")
                            .foregroundColor(.secondary)
                        Text("Frameworks & PlugIns")
                            .foregroundColor(.secondary)
                        Text("Tweaks")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Properties")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }
                
                if isSigning {
                    Section {
                        VStack(spacing: 12) {
                            ProgressView(value: progress)
                                .tint(.purple)
                            Text(statusText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
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
            .navigationTitle(appName.isEmpty ? "Signing" : appName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset") {
                        loadMetadata()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    startSigning()
                } label: {
                    Text(isSigning ? "Signing..." : "Start Signing")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isSigning ? Color.gray : Color.purple)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isSigning || certManager.selected() == nil)
                .padding()
                .background(.ultraThinMaterial)
            }
            .sheet(isPresented: $showCertPicker) {
                CertificatePickerView()
            }
            .onAppear {
                loadMetadata()
            }
        }
    }
    
    func fieldRow(_ label: String, value: Binding<String>, placeholder: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField(placeholder, text: value)
                .multilineTextAlignment(.trailing)
                .foregroundColor(.secondary)
        }
    }
    
    func pill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
    
    func loadMetadata() {
        isLoadingMetadata = true
        let metadata = IPAReader.read(from: ipaURL.path)
        appName = metadata?.name ?? ipaURL.lastPathComponent.replacingOccurrences(of: ".ipa", with: "")
        bundleID = metadata?.bundleID ?? "com.unknown.app"
        appVersion = metadata?.version ?? "1.0"
        iconData = metadata?.iconData
        isLoadingMetadata = false
    }
    
    func startSigning() {
        guard let cert = certManager.selected() else { return }
        
        isSigning = true
        progress = 0
        errorMessage = nil
        
        Task {
            do {
                await updateProgress(0.15, "Uploading IPA...")
                try await ServerAPI.uploadIPA(ipaURL)
                
                await updateProgress(0.35, "Uploading certificate...")
                try await ServerAPI.uploadP12(certManager.p12URL(for: cert))
                
                await updateProgress(0.5, "Uploading provision...")
                try await ServerAPI.uploadProvision(certManager.provisionURL(for: cert))
                
                await updateProgress(0.6, "Sending password...")
                try await ServerAPI.sendPassword(cert.password)
                
                await updateProgress(0.7, "Signing on server...")
                try await ServerAPI.sign()
                
                await updateProgress(0.85, "Downloading signed IPA...")
                let signedData = try await ServerAPI.downloadSignedIPA()
                
                let tempPath = NSTemporaryDirectory() + "/" + ipaURL.lastPathComponent
                try signedData.write(to: URL(fileURLWithPath: tempPath))
                
                await updateProgress(0.95, "Saving to library...")
                await MainActor.run {
                    libraryManager.add(
                        name: appName,
                        bundleID: bundleID,
                        version: appVersion,
                        ipaPath: tempPath,
                        iconData: iconData
                    )
                }
                
                await updateProgress(1.0, "Installing...")
                ServerAPI.install()
                
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                
                await MainActor.run {
                    isSigning = false
                    dismiss()
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
