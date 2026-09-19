import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @StateObject var libraryManager = LibraryManager.shared
    @State private var selectedTab: Int = 0
    @State private var searchText = ""
    @State private var selectedApp: SignedApp?
    @State private var installApp: SignedApp?
    @State private var showSignSheet = false
    @State private var signIPAURL: URL?
    @State private var showImportMenu = false
    @State private var showFileImporter = false
    @State private var showURLAlert = false
    @State private var urlInput = ""
    @State private var editMode: EditMode = .inactive
    @State private var selectedApps: Set<UUID> = []
    @State private var showActionSheetFor: SignedApp?
    
    var apps: [SignedApp] {
        let list = libraryManager.apps
        if searchText.isEmpty { return list }
        return list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text("Downloaded Apps").tag(0)
                    Text("Signed Apps").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                if apps.isEmpty {
                    emptyState
                } else {
                    listContent
                }
            }
            .navigationTitle("Library")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showFileImporter = true
                        } label: {
                            Label("Import from Files", systemImage: "folder")
                        }
                        Button {
                            urlInput = ""
                            showURLAlert = true
                        } label: {
                            Label("Import from URL", systemImage: "globe")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .environment(\.editMode, $editMode)
            .sheet(item: $selectedApp) { app in
                LibraryInfoSheet(app: app)
            }
            .sheet(item: $installApp) { app in
                InstallSheet(app: app)
            }
            .sheet(isPresented: $showSignSheet) {
                if let url = signIPAURL {
                    SigningView(ipaURL: url)
                }
            }
            .sheet(isPresented: $showFileImporter) {
                DocumentPickerView { url in
                    importIPA(url)
                }
            }
            .alert("Import from URL", isPresented: $showURLAlert) {
                TextField("https://example.com/app.ipa", text: $urlInput)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                Button("Cancel", role: .cancel) { }
                Button("OK") {
                    downloadAndImport()
                }
            } message: {
                Text("Enter the URL of the IPA file")
            }
            .confirmationDialog(
                showActionSheetFor?.name ?? "",
                isPresented: Binding(
                    get: { showActionSheetFor != nil },
                    set: { if !$0 { showActionSheetFor = nil } }
                ),
                titleVisibility: .visible
            ) {
                if let app = showActionSheetFor {
                    actionSheetButtons(for: app)
                }
            }
        }
    }
    
    var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "questionmark.app.fill")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text("No Apps")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Get started by importing your first IPA file.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button {
                showFileImporter = true
            } label: {
                Text("Import")
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
            Section {
                ForEach(apps) { app in
                    Button {
                        showActionSheetFor = app
                    } label: {
                        HStack(spacing: 12) {
                            if let icon = libraryManager.iconImage(for: app) {
                                Image(uiImage: icon)
                                    .resizable()
                                    .frame(width: 57, height: 57)
                                    .clipShape(RoundedRectangle(cornerRadius: 13))
                            } else {
                                RoundedRectangle(cornerRadius: 13)
                                    .fill(Color(.systemGray5))
                                    .frame(width: 57, height: 57)
                                    .overlay(
                                        Image(systemName: "app.fill")
                                            .foregroundColor(.purple)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(app.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("\(app.version) • \(app.bundleID)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            if editMode == .active {
                                Image(systemName: selectedApps.contains(app.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedApps.contains(app.id) ? .purple : .secondary)
                            } else {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.footnote)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .contextMenu {
                        contextMenuItems(for: app)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            libraryManager.delete(app)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            } header: {
                HStack {
                    Text(selectedTab == 0 ? "Downloaded Apps" : "Signed Apps")
                    Spacer()
                    Text("\(apps.count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    @ViewBuilder
    func contextMenuItems(for app: SignedApp) -> some View {
        Button {
            installApp = app
        } label: {
            Label("Install", systemImage: "square.and.arrow.down")
        }
        Button {
            signIPAURL = URL(fileURLWithPath: app.ipaPath)
            showSignSheet = true
        } label: {
            Label("Re-sign", systemImage: "signature")
        }
        Button {
            exportApp(app)
        } label: {
            Label("Export", systemImage: "square.and.arrow.up")
        }
        Button {
            selectedApp = app
        } label: {
            Label("Get Info", systemImage: "info.circle")
        }
        Divider()
        Button(role: .destructive) {
            libraryManager.delete(app)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    @ViewBuilder
    func actionSheetButtons(for app: SignedApp) -> some View {
        Button("Install") {
            installApp = app
            showActionSheetFor = nil
        }
        Button("Re-sign") {
            signIPAURL = URL(fileURLWithPath: app.ipaPath)
            showSignSheet = true
            showActionSheetFor = nil
        }
        Button("Export") {
            exportApp(app)
            showActionSheetFor = nil
        }
        Button("Get Info") {
            selectedApp = app
            showActionSheetFor = nil
        }
        Button("Delete", role: .destructive) {
            libraryManager.delete(app)
            showActionSheetFor = nil
        }
        Button("Cancel", role: .cancel) { }
    }
    
    func importIPA(_ url: URL) {
        // read metadata
        let metadata = IPAReader.read(from: url.path)
        
        // copy IPA to Documents
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dest = docs.appendingPathComponent(url.lastPathComponent)
        try? FileManager.default.removeItem(at: dest)
        try? FileManager.default.copyItem(at: url, to: dest)
        
        // add to library as "Downloaded"
        libraryManager.add(
            name: metadata?.name ?? url.lastPathComponent.replacingOccurrences(of: ".ipa", with: ""),
            bundleID: metadata?.bundleID ?? "com.unknown.app",
            version: metadata?.version ?? "1.0",
            ipaPath: dest.path,
            iconData: metadata?.iconData
        )
    }
    
    func downloadAndImport() {
        guard let url = URL(string: urlInput), !urlInput.isEmpty else { return }
        
        URLSession.shared.downloadTask(with: url) { tempURL, _, error in
            guard let tempURL = tempURL, error == nil else { return }
            
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let dest = docs.appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.removeItem(at: dest)
            try? FileManager.default.moveItem(at: tempURL, to: dest)
            
            DispatchQueue.main.async {
                importIPA(dest)
                urlInput = ""
            }
        }.resume()
    }
    
    func exportApp(_ app: SignedApp) {
        let url = URL(fileURLWithPath: app.ipaPath)
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(vc, animated: true)
        }
    }
}
