import SwiftUI

struct LibraryView: View {
    @StateObject var libraryManager = LibraryManager.shared
    @State private var showContent = false
    
    var body: some View {
        NavigationView {
            Group {
                if libraryManager.apps.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "tray")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No signed apps yet")
                            .font(.headline)
                        Text("Sign an IPA to see it here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .opacity(showContent ? 1 : 0)
                } else {
                    List {
                        ForEach(libraryManager.apps) { app in
                            HStack(spacing: 12) {
                                Image(systemName: "app.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(
                                        LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom)
                                    )
                                    .frame(width: 50)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(app.name)
                                        .font(.headline)
                                    Text("v\(app.version)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(app.date, style: .date)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button {
                                    install(app)
                                } label: {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.purple)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    libraryManager.delete(app)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .onAppear {
                withAnimation { showContent = true }
            }
        }
    }
    
    func install(_ app: SignedApp) {
        // trigger install via server
        // for now: just show toast or open
        let url = URL(string: "\(ServerAPI.baseURL)/manifest.plist")!
        UIApplication.shared.open(URL(string: "itms-services://?action=download-manifest&url=\(url.absoluteString)")!)
    }
}
