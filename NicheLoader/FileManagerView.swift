import SwiftUI
import QuickLook

struct FileItem: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool
    let size: Int64
}

struct FileManagerView: View {
    let directory: URL
    @State private var items: [FileItem] = []
    @State private var searchText = ""
    @State private var previewURL: URL?
    @State private var showContent = false
    
    init(directory: URL? = nil) {
        if let dir = directory {
            self.directory = dir
        } else {
            self.directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        }
    }
    
    var filteredItems: [FileItem] {
        if searchText.isEmpty { return items }
        return items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredItems) { item in
                    Button {
                        if item.isDirectory {
                            // navigate - for now use sheet
                        } else {
                            previewURL = item.url
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: item.isDirectory ? "folder.fill" : iconFor(item.name))
                                .font(.title2)
                                .foregroundColor(item.isDirectory ? .purple : .blue)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                Text(byteString(item.size))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            try? FileManager.default.removeItem(at: item.url)
                            loadItems()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            share(item.url)
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .tint(.blue)
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText)
            .navigationTitle(directory.lastPathComponent)
            .sheet(item: $previewURL) { url in
                QuickLookView(url: url)
            }
            .onAppear {
                loadItems()
                withAnimation { showContent = true }
            }
        }
    }
    
    func loadItems() {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            items = []
            return
        }
        
        items = contents.compactMap { url in
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
            return FileItem(
                url: url,
                name: url.lastPathComponent,
                isDirectory: values?.isDirectory ?? false,
                size: Int64(values?.fileSize ?? 0)
            )
        }.sorted { $0.name < $1.name }
    }
    
    func iconFor(_ name: String) -> String {
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "ipa", "tipa": return "shippingbox.fill"
        case "png", "jpg", "jpeg": return "photo.fill"
        case "plist": return "doc.text.fill"
        case "p12": return "lock.fill"
        case "mobileprovision": return "doc.badge.gearshape"
        case "zip", "tar", "gz": return "archivebox.fill"
        default: return "doc.fill"
        }
    }
    
    func byteString(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    func share(_ url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
    }
}

struct QuickLookView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        init(url: URL) { self.url = url }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return url as NSURL
        }
    }
}

extension URL: Identifiable {
    public var id: String { self.absoluteString }
}
