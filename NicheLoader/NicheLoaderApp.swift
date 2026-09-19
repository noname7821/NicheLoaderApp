import SwiftUI

@main
struct NicheLoaderApp: App {
    var body: some Scene {
        WindowGroup {
            TermsView()
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: Int = 0
    @State private var showUpdate: Bool = false
    @State private var updateMessage: String = ""
    @State private var updateBody: String = ""
    @State private var updateURL: String = ""
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FileManagerView()
                .tabItem { Label("Files", systemImage: "folder.fill") }
                .tag(0)
            LibraryView()
                .tabItem { Label("Library", systemImage: "square.grid.2x2.fill") }
                .tag(1)
            RepoView()
                .tabItem { Label("App Store", systemImage: "plus.app.fill") }
                .tag(2)
            DownloadsView()
                .tabItem { Label("Downloads", systemImage: "square.and.arrow.down.fill") }
                .tag(3)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.2.fill") }
                .tag(4)
        }
        .tint(.purple)
        .onChange(of: selectedTab) { _ in
            let g = UIImpactFeedbackGenerator(style: .light)
            g.impactOccurred()
        }
        .onAppear { checkUpdate() }
        .alert(isPresented: $showUpdate) {
            Alert(
                title: Text(updateMessage),
                message: Text(updateBody),
                primaryButton: .default(Text("Install")) {
                    if let url = URL(string: updateURL) {
                        UIApplication.shared.open(url)
                    }
                },
                secondaryButton: .cancel(Text("Continue"))
            )
        }
    }
    
    func checkUpdate() {
        UpdateChecker.checkForUpdates { version, url, message, body in
            if let _ = version, let url = url {
                DispatchQueue.main.async {
                    self.updateMessage = message ?? "A new version is out!"
                    self.updateBody = body ?? "Tap Install to download the latest IPA."
                    self.updateURL = url
                    self.showUpdate = true
                }
            }
        }
    }
}
