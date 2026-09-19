import SwiftUI

struct DownloadsView: View {
    @State private var downloads: [URL] = []
    @State private var showAdd = false
    @State private var urlInput = ""
    @State private var isDownloading = false
    @State private var downloadName = ""
    
    var body: some View {
        NavigationView {
            Group {
                if downloads.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)
                        Text("No downloaded IPAs")
                            .font(.title3).fontWeight(.semibold)
                        Text("Get started by downloading your first IPA file.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button {
                            showAdd = true
                        } label: {
                            Text("Add Download")
                                .fontWeight(.semibold)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color(.systemGray6))
                                .foregroundColor(.purple)
                                .clipShape(Capsule())
                        }
                        Spacer()
                    }
                } else {
                    List {
                        Section("Downloaded") {
                            ForEach(downloads, id: \.self) { url in
                                HStack(spacing: 12) {
                                    Image(systemName: "doc.fill")
                                        .foregroundColor(.purple)
                                        .font(.title2)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(url.lastPathComponent)
                                            .font(.body)
                                        if let size = fileSize(url) {
                                            Text(size)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
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
            }
            .navigationTitle("Downloads")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
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
                Button("Cancel", role: .cancel) { urlInput = "" }
                Button("Okay") { startDownload() }
            } message: {
                Text("Enter the URL of the IPA file")
            }
            .onAppear { loadDownloads() }
        }
    }
    
    func fileSize(_ url: URL) -> String? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int64 else { return nil }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    func loadDownloads() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Downloads")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
            downloads = files.sorted { $0.lastPathComponent < $1.lastPathComponent }
        }
    }
    
    func startDownload() {
        guard let url = URL(string: urlInput), !urlInput.isEmpty else { return }
        
        URLSession.shared.downloadTask(with: url) { tempURL, _, error in
            guard let tempURL = tempURL, error == nil else { return }
            
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let dir = docs.appendingPathComponent("Downloads")
            let dest = dir.appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.removeItem(at: dest)
            try? FileManager.default.moveItem(at: tempURL, to: dest)
            
            DispatchQueue.main.async {
                urlInput = ""
                loadDownloads()
            }
        }.resume()
    }
}
