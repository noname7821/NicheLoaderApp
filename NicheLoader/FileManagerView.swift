import SwiftUI
import QuickLook

struct FileItem: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool
    let size: Int64
    let date: Date?
}

struct FileManagerView: View {
    @State private var items: [FileItem] = []
    @State private var searchText = ""
    @State private var previewURL: URL?
    @State private var showImport = false
    @State private var showNewFolder = false
    @State private var showNewText = false
    @State private var newName = ""
    @State private var selectedItem: FileItem?
    @State private var showActions = false
    @State private var editMode: EditMode = .inactive
    @State private var navigateTo: URL?
    
    let rootURL: URL
    
    init() {
        self.rootURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    init(directory: URL) {
        self.rootURL = directory
    }
    
    var filtered: [FileItem] {
        if searchText.isEmpty { return items }
        return items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filtered) { item in
                    Button {
                        if item.isDirectory {
                            navigateTo = item.url
                        } else {
                            selectedItem = item
                            showActions = true
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: item.isDirectory ? "folder.fill" : iconFor(item.name))
                                .font(.title3)
                                .foregroundColor(.purple)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                HStack(spacing: 4) {
                                    if !item.isDirectory {
                                        Text(byteString(item.size))
                                    }
                                    if let date = item.date {
                                        Text("•")
                                        Text(date.formatted(date: .abbreviated, time: .omitted))
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if editMode == .active {
                                Image(systemName: "circle")
                                    .foregroundColor(.secondary)
                            } else {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.footnote)
                            }
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
                        .tint(.purple)
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle(rootURL.lastPathComponent)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showImport = true
                        } label: {
                            Label("Import Files", systemImage: "doc.badge.plus")
                        }
                        Button {
                            showNewFolder = true
                        } label: {
                            Label("New Folder", systemImage: "folder.badge.plus")
                        }
                        Button {
                            showNewText = true
                        } label: {
                            Label("New Text File", systemImage: "doc.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $previewURL) { url in
                QuickLookView(url: url)
            }
            .sheet(isPresented: $showImport) {
                DocumentPickerView { url in
                    importFile(url)
                }
            }
            .alert("New Folder", isPresented: $showNewFolder) {
                TextField("Folder name", text: $newName)
                Button("Cancel", role: .cancel) { newName = "" }
                Button("Create") { createFolder() }
            }
            .alert("New Text File", isPresented: $showNewText) {
                TextField("File name", text: $newName)
                Button("Cancel", role: .cancel) { newName = "" }
                Button("Create") { createTextFile() }
            }
            .confirmationDialog(
                selectedItem?.name ?? "",
                isPresented: $showActions,
                titleVisibility: .visible
            ) {
                if let item = selectedItem {
                    Button("Preview") {
                        previewURL = item.url
                    }
                    Button("Hex Editor") { }
                    if item.name.hasSuffix(".ipa") || item.name.hasSuffix(".tipa") {
                        Button("Import to Library") {
                            importToLibrary(item.url)
                        }
                    }
                    Button("Extract") { }
                    Button("Move") { }
                    Button("Rename") { }
                    Button("Share") {
                        share(item.url)
                    }
                    Button("Delete", role: .destructive) {
                        try? FileManager.default.removeItem(at: item.url)
                        loadItems()
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .background(
                NavigationLink(
                    isActive: Binding(
                        get: { navigateTo != nil },
                        set: { if !$0 { navigateTo = nil } }
                    ),
                    destination: {
                        if let url = navigateTo {
                            FileManagerView(directory: url)
                        }
                    },
                    label: { EmptyView() }
                )
            )
            .environment(\.editMode, $editMode)
            .onAppear { loadItems() }
        }
    }
    
    func loadItems() {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            items = []
            return
        }
        
        items = contents.compactMap { url in
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
            return FileItem(
                url: url,
                name: url.lastPathComponent,
                isDirectory: values?.isDirectory ?? false,
                size: Int64(values?.fileSize ?? 0),
                date: values?.contentModificationDate
            )
        }.sorted { a, b in
            if a.isDirectory != b.isDirectory { return a.isDirectory }
            return a.name < b.name
        }
    }
    
    func iconFor(_ name: String) -> String {
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "ipa", "tipa": return "shippingbox.fill"
        case "png", "jpg", "jpeg", "gif", "webp": return "photo.fill"
        case "plist": return "doc.text.fill"
        case "p12": return "lock.fill"
        case "mobileprovision": return "doc.badge.gearshape"
        case "zip", "tar", "gz": return "archivebox.fill"
        case "txt", "md": return "doc.text"
        default: return "doc.fill"
        }
    }
    
    func byteString(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    func share(_ url: URL) {
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(vc, animated: true)
        }
    }
    
    func importFile(_ url: URL) {
        let dest = rootURL.appendingPathComponent(url.lastPathComponent)
        try? FileManager.default.removeItem(at: dest)
        try? FileManager.default.copyItem(at: url, to: dest)
        loadItems()
    }
    
    func importToLibrary(_ url: URL) {
        let metadata = IPAReader.read(from: url.path)
        LibraryManager.shared.add(
            name: metadata?.name ?? url.lastPathComponent,
            bundleID: metadata?.bundleID ?? "unknown",
            version: metadata?.version ?? "1.0",
            ipaPath: url.path,
            iconData: metadata?.iconData
        )
    }
    
    func createFolder() {
        guard !newName.isEmpty else { return }
        let dest = rootURL.appendingPathComponent(newName)
        try? FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true)
        newName = ""
        loadItems()
    }
    
    func createTextFile() {
        guard !newName.isEmpty else { return }
        let dest = rootURL.appendingPathComponent(newName.hasSuffix(".txt") ? newName : newName + ".txt")
        try? "".write(to: dest, atomically: true, encoding: .utf8)
        newName = ""
        loadItems()
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
    public var id: String { absoluteString }
}
