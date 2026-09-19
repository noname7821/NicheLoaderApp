import SwiftUI

struct LibraryView: View {
    @StateObject var libraryManager = LibraryManager.shared
    @State private var selectedTab: Int = 1
    @State private var showContent = false
    @State private var selectedApp: SignedApp?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text("Downloaded").tag(0)
                    Text("Signed").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if libraryManager.apps.isEmpty && selectedTab == 1 {
                    emptyState
                } else {
                    appList
                }
            }
            .navigationTitle("Library")
            .sheet(item: $selectedApp) { app in
                LibraryInfoView(app: app)
            }
            .onAppear {
                withAnimation { showContent = true }
            }
        }
    }
    
    var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "questionmark.app.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Apps")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Get started by signing your first IPA")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .opacity(showContent ? 1 : 0)
    }
    
    var appList: some View {
        List {
            ForEach(libraryManager.apps) { app in
                Button {
                    selectedApp = app
                } label: {
                    HStack(spacing: 12) {
                        if let icon = libraryManager.iconImage(for: app) {
                            Image(uiImage: icon)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 57, height: 57)
                                .clipShape(RoundedRectangle(cornerRadius: 13))
                        } else {
                            Image(systemName: "app.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.purple)
                                .frame(width: 57, height: 57)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 13))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
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
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                    .padding(.vertical, 4)
                }
                .swipeActions {
                    Button(role: .destructive) {
                        libraryManager.delete(app)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

struct LibraryInfoView: View {
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
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                        } else {
                            Image(systemName: "app.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.purple)
                                .frame(width: 100, height: 100)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                
                Section("Info") {
                    infoCell("Name", desc: app.name)
                    infoCell("Version", desc: app.version)
                    infoCell("Bundle ID", desc: app.bundleID)
                    infoCell("Date", desc: app.date.formatted())
                }
                
                Section {
                    Button {
                        install(app)
                    } label: {
                        Label("Install", systemImage: "square.and.arrow.down")
                    }
                    Button {
                        share(app)
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
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
    
    func infoCell(_ title: String, desc: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(desc)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
    
    func install(_ app: SignedApp) {
        let url = URL(string: "\(ServerAPI.baseURL)/manifest.plist")!
        UIApplication.shared.open(URL(string: "itms-services://?action=download-manifest&url=\(url.absoluteString)")!)
    }
    
    func share(_ app: SignedApp) {
        let url = URL(fileURLWithPath: app.ipaPath)
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
    }
}
