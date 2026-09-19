import SwiftUI

struct LibraryView: View {
    @StateObject var libraryManager = LibraryManager.shared
    @State private var selectedTab: Int = 0
    @State private var searchText = ""
    @State private var selectedApp: SignedApp?
    @State private var importURL = false
    @State private var importFiles = false
    @State private var showImportMenu = false
    
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
                    appList
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
                            importFiles = true
                        } label: {
                            Label("Import from Files", systemImage: "folder")
                        }
                        Button {
                            importURL = true
                        } label: {
                            Label("Import from URL", systemImage: "globe")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $selectedApp) { app in
                LibraryInfoSheet(app: app)
            }
            .sheet(isPresented: $importFiles) {
                DocumentPickerView { url in
                    importIPA(url)
                }
            }
            .alert("Import from URL", isPresented: $importURL) {
                TextField("URL", text: .constant(""))
                Button("Cancel", role: .cancel) { }
                Button("OK") { }
            }
            .onAppear { }
        }
    }
    
    var apps: [SignedApp] {
        let list = libraryManager.apps
        if searchText.isEmpty { return list }
        return list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "questionmark.app.fill")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text("No Apps")
                .font(.title3).fontWeight(.semibold)
            Text("Get started by signing your first IPA")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if selectedTab == 0 {
                Button {
                    importFiles = true
                } label: {
                    Text("Import")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .foregroundColor(.purple)
                        .clipShape(Capsule())
                }
            }
            Spacer()
        }
    }
    
    var appList: some View {
        List {
            Section {
                ForEach(apps) { app in
                    Button {
                        selectedApp = app
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
                            
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .contextMenu {
                        Button {
                            install(app)
                        } label: {
                            Label("Sign and Install", systemImage: "signature")
                        }
                        Button {
                            // re-sign
                        } label: {
                            Label("Sign", systemImage: "signature")
                        }
                        Button {
                            share(app)
                        } label: {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                        Button {
                            // show dylibs
                        } label: {
                            Label("Show Dylibs", systemImage: "list.bullet")
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
    
    func importIPA(_ url: URL) {
        // Copy to documents
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dest = docs.appendingPathComponent(url.lastPathComponent)
        try? FileManager.default.removeItem(at: dest)
        try? FileManager.default.copyItem(at: url, to: dest)
    }
    
    func install(_ app: SignedApp) {
        let url = URL(string: "\(ServerAPI.baseURL)/manifest.plist")!
        UIApplication.shared.open(URL(string: "itms-services://?action=download-manifest&url=\(url.absoluteString)")!)
    }
    
    func share(_ app: SignedApp) {
        let url = URL(fileURLWithPath: app.ipaPath)
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(vc, animated: true)
        }
    }
}

struct LibraryInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    let app: SignedApp
    @StateObject var libraryManager = LibraryManager.shared
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Spacer()
                        if let icon = libraryManager.iconImage(for: app) {
                            Image(uiImage: icon)
                                .resizable()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                
                Section("Info") {
                    row("Name", app.name)
                    row("Version", app.version)
                    row("Identifier", app.bundleID)
                    row("Date Added", app.date.formatted())
                }
                
                Section("Actions") {
                    Button {
                        install()
                    } label: {
                        Label("Install", systemImage: "square.and.arrow.down")
                            .foregroundColor(.purple)
                    }
                    Button {
                        share()
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                            .foregroundColor(.purple)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        libraryManager.delete(app)
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .navigationTitle(app.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundColor(.secondary)
        }
    }
    
    func install() {
        let url = URL(string: "\(ServerAPI.baseURL)/manifest.plist")!
        UIApplication.shared.open(URL(string: "itms-services://?action=download-manifest&url=\(url.absoluteString)")!)
    }
    
    func share() {
        let url = URL(fileURLWithPath: app.ipaPath)
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(vc, animated: true)
        }
    }
}
