import SwiftUI

struct DownloadsView: View {
    @State private var downloads: [URL] = []
    @State private var showAdd = false
    @State private var urlInput = ""
    @State private var isDownloading = false
    @State private var progress: Double = 0
    @State private var downloadName = ""
    
    var body: some View {
        NavigationView {
            Group {
                if downloads.isEmpty {
                    emptyState
                } else {
                    listContent
                }
            }
            .navigationTitle("Downloads")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        urlInput = ""
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Enter URL", isPresented: $showAdd) {
                TextField("https://example.com/app.ipa", text: $urlInput)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                Button("Cancel", role: .cancel) { }
                Button("Okay") { startDownload() }
            } message: {
                Text("Enter the URL of the IPA file")
            }
            .onAppear { loadDownloads() }
        }
    }
    
    var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "square.and.arrow.down.fill")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text("No downloaded IPAs")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Get started by downloading your first IPA file.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button {
                urlInput = ""
                showAdd = true
            } label: {
                Text("Add Download")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .foregroundColor(.purple)
                    .clipShape(Capsule())
            }
            Spacer()
        }
    }
    
    var listContent: some View {
        List {
            Section("Downloaded") {
                ForEach(downloads, id: \.self) { url in
                    HStack(spacing: 12) {
                        Image(systemName: "shippingbox.fill")
                            .font(.title2)
                            .foregroundColor(.purple)
                            .frame(width: 40)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(url.lastPathComponent)
                                .font(.body)
                            Text(byteString(url))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .contextMenu {
                        Button {
                            importToLibrary(url)
                        } label: {
                            Label("Import to Library", systemImage: "square.and.arrow.down")
                        }
                        Button {
                            share(url)
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        Divider()
                        Button(role: .destructive) {
                            try? FileManager.default.removeItem(at: url)
                            loadDownloads()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onDelete { idx in
                    for i in idx {
                        try? FileManager.default.removeItem(at: downloads[i])
                    }
                    loadDownloads()
                }
            }
        }
    }
    
    func loadDownloads() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Downloads")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
            downloads = files.sorted { $0.lastPathComponent < $1.lastPathComponent }
        }
    }
    
    func byteString(_ url: URL) -> String {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int64 else { return "0 KB" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    func startDownload() {
        guard let url = URL(string: urlInput), !urlInput.isEmpty else { return }
        isDownloading = true
        
        URLSession.shared.downloadTask(with: url) { tempURL, _, error in
            DispatchQueue.main.async {
                isDownloading = false
                
                guard let tempURL = tempURL, error == nil else { return }
                
                let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let dir = docs.appendingPathComponent("Downloads")
                let dest = dir.appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.removeItem(at: dest)
                try? FileManager.default.moveItem(at: tempURL, to: dest)
                
                urlInput = ""
                loadDownloads()
            }
        }.resume()
    }
    
    func importToLibrary(_ url: URL) {
        let metadata = IPAReader.read(from: url.path)
        LibraryManager.shared.add(
            name: metadata?.name ?? url.lastPathComponent.replacingOccurrences(of: ".ipa", with: ""),
            bundleID: metadata?.bundleID ?? "com.unknown.app",
            version: metadata?.version ?? "1.0",
            ipaPath: url.path,
            iconData: metadata?.iconData
        )
    }
    
    func share(_ url: URL) {
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(vc, animated: true)
        }
    }
}
