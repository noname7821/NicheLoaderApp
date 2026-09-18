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
    @State private var updateURL: String = ""
    
    var body: some View {
        ZStack {
            if selectedTab == 0 {
                HomeView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                SettingsView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedTab)
        .safeAreaInset(edge: .bottom) {
            customTabBar
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            checkUpdate()
        }
        .alert(isPresented: $showUpdate) {
            Alert(
                title: Text(updateMessage),
                message: Text("A new version of NicheLoader is available."),
                primaryButton: .default(Text("Install")) {
                    if let url = URL(string: updateURL) {
                        UIApplication.shared.open(url)
                    }
                },
                secondaryButton: .cancel(Text("Continue"))
            )
        }
    }
    
    var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(title: "Home", icon: "house.fill", index: 0)
            tabButton(title: "Settings", icon: "gearshape.fill", index: 1)
        }
        .padding(.horizontal, 40)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, y: -4)
        )
    }
    
    func tabButton(title: String, icon: String, index: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedTab = index
            }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(selectedTab == index ? .purple : .secondary)
            .frame(maxWidth: .infinity)
        }
    }
    
    func checkUpdate() {
        UpdateChecker.checkForUpdates { version, url, message in
            if let _ = version, let url = url {
                DispatchQueue.main.async {
                    self.updateMessage = message ?? "A new version is out!"
                    self.updateURL = url
                    self.showUpdate = true
                }
            }
        }
    }
}
