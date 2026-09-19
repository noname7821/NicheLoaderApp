import SwiftUI

struct RepoView: View {
    @StateObject var repoManager = RepoManager.shared
    @State private var showAddRepo = false
    @State private var showContent = false
    @State private var searchText = ""
    @State private var sortMode: SortMode = .default
    
    enum SortMode: String, CaseIterable {
        case `default` = "Default"
        case name = "Name"
        case date = "Date"
    }
    
    var allApps: [RepoApp] {
        repoManager.repos.flatMap { $0.apps }
    }
    
    var filteredApps: [RepoApp] {
        var apps = allApps
        if !searchText.isEmpty {
            apps = apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        switch sortMode {
        case .default: return apps
        case .name: return apps.sorted { $0.name < $1.name }
        case .date: return apps
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if repoManager.repos.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        // top buttons
                        HStack {
                            Button {
                                showAddRepo = true
                            } label: {
                                Text("Sources")
                                    .foregroundColor(.purple)
                            }
                            Spacer()
                            Button {
                                // refresh
                                reloadAll()
                            } label: {
                                Image(systemName: "arrow.clockwise")
                            }
                            Menu {
                                ForEach(SortMode.allCases, id: \.self) { mode in
                                    Button(mode.rawValue) { sortMode = mode }
                                }
                            } label: {
                                Image(systemName: "line.3.horizontal.decrease")
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        
                        if filteredApps.isEmpty {
                            VStack(spacing: 16) {
                                Spacer()
                                Image(systemName: "questionmark.app.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary)
                                Text("No Apps")
                                    .font(.title3).fontWeight(.semibold)
                                Spacer()
                            }
                        } else {
                            List {
                                Section("\(filteredApps.count) Apps") {
                                    ForEach(filteredApps) { app in
                                        NavigationLink(destination: RepoAppDetailView(app: app)) {
                                            RepoAppRow(app: app)
                                        }
                                    }
                                }
                            }
                            .listStyle(.plain)
                        }
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("App Store")
            .sheet(isPresented: $showAddRepo) {
                AddRepoView()
            }
            .onAppear {
                withAnimation { showContent = true }
            }
        }
    }
    
    var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "globe")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom)
                )
            Text("No Sources")
                .font(.title2)
                .fontWeight(.bold)
            Text("Add a repository to browse apps")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button {
                showAddRepo = true
            } label: {
                Text("Add Source")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray5))
                    .foregroundColor(.purple)
                    .clipShape(Capsule())
            }
            Spacer()
        }
        .opacity(showContent ? 1 : 0)
    }
    
    func reloadAll() {
        let urls = repoManager.repos.map { $0.url }
        repoManager.repos = []
        for url in urls {
            repoManager.addRepo(urlString: url) { _ in }
        }
    }
}

struct RepoAppRow: View {
    let app: RepoApp
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: app.iconURL ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Image(systemName: "app.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.purple)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGray5))
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            
            VStack(alignment: .leading, spacing: 3) {
                Text(app.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("\(app.version)\(app.localizedDescription != nil ? " • \(app.localizedDescription!)" : "")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text("Get")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.purple)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}

struct AddRepoView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var repoManager = RepoManager.shared
    @State private var url = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Repo URL") {
                    TextField("https://example.com/repo.json", text: $url)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                if let error = repoManager.error {
                    Section {
                        Text(error).foregroundColor(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("Add Source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        repoManager.addRepo(urlString: url) { success in
                            if success { dismiss() }
                        }
                    } label: {
                        if repoManager.isLoading {
                            ProgressView()
                        } else {
                            Text("Add").fontWeight(.bold)
                        }
                    }
                    .disabled(url.isEmpty || repoManager.isLoading)
                }
            }
        }
    }
}

struct RepoAppDetailView: View {
    let app: RepoApp
    @Environment(\.dismiss) var dismiss
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AsyncImage(url: URL(string: app.iconURL ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fit)
                    default:
                        Image(systemName: "app.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)
                    }
                }
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .padding(.top, 20)
                
                Text(app.name)
                    .font(.title).fontWeight(.bold)
                Text("Version \(app.version)")
                    .font(.subheadline).foregroundColor(.secondary)
                
                if let desc = app.localizedDescription {
                    Text(desc)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                if isDownloading {
                    VStack(spacing: 8) {
                        ProgressView(value: downloadProgress)
                            .tint(.purple)
                        Text("\(Int(downloadProgress * 100))%")
                            .font(.caption)
                    }
                    .padding(.horizontal)
                } else {
                    Button {
                        download()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Download IPA").fontWeight(.bold)
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
                }
                
                Spacer()
            }
        }
        .navigationTitle(app.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func download() {
        guard let url = URL(string: app.downloadURL) else { return }
        isDownloading = true
        
        URLSession.shared.downloadTask(with: url) { tempURL, _, error in
            DispatchQueue.main.async {
                isDownloading = false
                guard let tempURL = tempURL, error == nil else { return }
                
                let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let downloadsDir = docs.appendingPathComponent("Downloads")
                try? FileManager.default.createDirectory(at: downloadsDir, withIntermediateDirectories: true)
                
                let dest = downloadsDir.appendingPathComponent("\(app.name).ipa")
                try? FileManager.default.removeItem(at: dest)
                try? FileManager.default.moveItem(at: tempURL, to: dest)
            }
        }.resume()
    }
}
