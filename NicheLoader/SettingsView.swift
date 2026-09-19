import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            List {
                // About Section
                Section("About") {
                    NavigationLink {
                        InfoView()
                    } label: {
                        Label {
                            Text("About")
                        } icon: {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Features Section
                Section("Features") {
                    NavigationLink {
                        InfoView()
                    } label: {
                        Label {
                            Text("Logs")
                        } icon: {
                            Image(systemName: "apple.terminal")
                                .foregroundColor(.blue)
                        }
                    }
                    NavigationLink {
                        InfoView()
                    } label: {
                        Label {
                            Text("App Features")
                        } icon: {
                            Image(systemName: "sparkles")
                                .foregroundColor(.blue)
                        }
                    }
                    NavigationLink {
                        CertificatePickerView()
                    } label: {
                        Label {
                            Text("Certificates")
                        } icon: {
                            Image(systemName: "signature")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Misc Section
                Section("Misc") {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label {
                            Text("Open Settings")
                                .foregroundColor(.blue)
                        } icon: {
                            Image(systemName: "gear")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Info text
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Use Responsibly")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("Do NOT use NicheLoader for pirated apps or illegal software. Only sign apps you legally own.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("No Data Collection")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("Nothing leaves your device. No analytics. No tracking.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Version
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.3")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct InfoView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    Text("NicheLoader")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Version 1.0.3")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .listRowBackground(Color.clear)
            }
            
            Section("Credits") {
                Link(destination: URL(string: "https://github.com/noname7821")!) {
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: "https://avatars.githubusercontent.com/u/210064350?s=400&u=539b1b1eb9554c4654472d091675d6804f0ff3df&v=4")) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Mintoo")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Solo Developer")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }
                
                Link(destination: URL(string: "https://www.tiktok.com/@filmeacc")!) {
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: "https://p16-common-sign.tiktokcdn-eu.com/tos-no1a-avt-0068c001-no/55493ade73a29ea3c127a707d9383110~tplv-tiktokx-cropcenter:100:100.jpeg")) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Filmeacc")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Just my TikTok account")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }
            }
            
            Section("Built with") {
                HStack {
                    Text("SwiftUI")
                    Spacer()
                    Text("Python + zsign")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
