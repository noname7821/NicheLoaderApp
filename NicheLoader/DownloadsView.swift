import SwiftUI

struct DownloadsView: View {
    @State private var downloads: [URL] = []
    @State private var showAddDownload = false
    @State private var urlInput = ""
    
    var body: some View {
        NavigationView {
            Group {
                if downloads.isEmpty {
                    emptyState
                } else {
                    List {
                        Section("Downloaded") {
                            ForEach(downloads, id: \.self) { url in
                                HStack {
                                    Image(systemName: "doc.fill")
                                        .foregroundColor(.blue)
                                    Text(url.lastPathComponent)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Downloads")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddDownload = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Enter URL", isPresented: $showAddDownload) {
                TextField("https://example.com/app.ipa", text: $urlInput)
                Button("Cancel", role: .cancel) { urlInput = "" }
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
                .font(.system(size: 60))
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
                showAddDownload = true
            } label: {
                Text("Add Download")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray5))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
            }
            Spacer()
        }
    }
    
    func loadDownloads() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let downloadsDir = docs.appendingPathComponent("Downloads")
        try? FileManager.default.createDirectory(at: downloadsDir, withIntermediateDirectories: true)
        
        if let files = try? FileManager.default.contentsOfDirectory(at: downloadsDir, includingPropertiesForKeys: nil) {
            downloads = files
        }
    }
    
    func startDownload() {
        guard let url = URL(string: urlInput) else { return }
        
        URLSession.shared.downloadTask(with: url) { tempURL, _, error in
            guard let tempURL = tempURL, error == nil else { return }
            
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let downloadsDir = docs.appendingPathComponent("Downloads")
            let dest = downloadsDir.appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.moveItem(at: tempURL, to: dest)
            
            DispatchQueue.main.async {
                urlInput = ""
                loadDownloads()
            }
        }.resume()
    }
}
