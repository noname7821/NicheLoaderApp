import SwiftUI

struct RepoView: View {
    @StateObject var repoManager = RepoManager.shared
    @State private var showAddRepo = false
    @State private var repoURL = ""
    @State private var showContent = false
    
    var body: some View {
        NavigationView {
            Group {
                if repoManager.repos.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "globe")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom)
                            )
                        Text("No repos yet")
                            .font(.headline)
                        Text("Add an AltStore repo to browse apps")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button {
                            showAddRepo = true
                        } label: {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add Repo")
                                    .fontWeight(.bold)
                            }
                            .padding()
                            .background(
                                LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    .opacity(showContent ? 1 : 0)
                } else {
                    List {
                        ForEach(repoManager.repos) { repo in
                            Section(repo.name) {
                                ForEach(repo.apps) { app in
                                    NavigationLink(destination: RepoAppDetailView(app: app)) {
                                        HStack(spacing: 12) {
                                            AsyncImage(url: URL(string: app.iconURL ?? "")) { image in
                                                image.resizable().aspectRatio(contentMode: .fill)
                                            } placeholder: {
                                                Image(systemName: "app.fill")
                                                    .foregroundColor(.purple)
                                            }
                                            .frame(width: 44, height: 44)
                                            .cornerRadius(10)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(app.name)
                                                    .font(.headline)
                                                Text("v\(app.version)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { idx in
                                repoManager.delete(repoManager.repos[idx])
                            }
                        }
                    }
                }
            }
            .navigationTitle("Repos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddRepo = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddRepo) {
                AddRepoView()
            }
            .onAppear {
                withAnimation { showContent = true }
            }
        }
    }
}

struct AddRepoView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var repoManager = RepoManager.shared
    @State private var url = ""
    @State private var isLoading = false
    
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
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Repo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isLoading = true
                        repoManager.addRepo(urlString: url) { success in
                            isLoading = false
                            if success { dismiss() }
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Add").fontWeight(.bold)
                        }
                    }
                    .disabled(url.isEmpty || isLoading)
                }
            }
        }
    }
}

struct RepoAppDetailView: View {
    let app: RepoApp
    @State private var isDownloading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AsyncImage(url: URL(string: app.iconURL ?? "")) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Image(systemName: "app.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.purple)
                }
                .frame(width: 120, height: 120)
                .cornerRadius(24)
                .padding(.top, 20)
                
                Text(app.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("v\(app.version)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let desc = app.localizedDescription {
                    Text(desc)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button {
                    isDownloading = true
                    downloadIPA()
                } label: {
                    HStack {
                        if isDownloading {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                        }
                        Text(isDownloading ? "Downloading..." : "Download IPA")
                            .fontWeight(.bold)
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
                .disabled(isDownloading)
                
                Spacer()
            }
        }
        .navigationTitle(app.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func downloadIPA() {
        guard let url = URL(string: app.downloadURL) else { return }
        
        URLSession.shared.downloadTask(with: url) { tempURL, _, error in
            DispatchQueue.main.async {
                isDownloading = false
                
                guard let tempURL = tempURL, error == nil else { return }
                
                let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let dest = docs.appendingPathComponent("\(app.name).ipa")
                try? FileManager.default.removeItem(at: dest)
                try? FileManager.default.moveItem(at: tempURL, to: dest)
                
                // TODO: auto sign or open in home
            }
        }.resume()
    }
}
