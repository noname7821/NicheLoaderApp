import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            List {
                // info
                Section("Info") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Use Responsibly")
                            .font(.headline)
                            .foregroundColor(.purple)
                        Text("Do NOT use NicheLoader for pirated games, cracked apps, or any illegal software. Only sign apps you legally own.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No Data Collection")
                            .font(.headline)
                            .foregroundColor(.purple)
                        Text("NicheLoader does not collect, store, or share any personal data. Everything stays on your device.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                // credits
                Section("Credits") {
                    Link(destination: URL(string: "https://github.com/noname7821")!) {
                        HStack(spacing: 12) {
                            AsyncImage(url: URL(string: "https://avatars.githubusercontent.com/u/210064350?s=400&u=539b1b1eb9554c4654472d091675d6804f0ff3df&v=4")) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Mintoo")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Solo Developer")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Link(destination: URL(string: "https://www.tiktok.com/@filmeacc?is_from_webapp=1&sender_device=pc")!) {
                        HStack(spacing: 12) {
                            AsyncImage(url: URL(string: "https://p16-common-sign.tiktokcdn-eu.com/tos-no1a-avt-0068c001-no/55493ade73a29ea3c127a707d9383110~tplv-tiktokx-cropcenter:100:100.jpeg?dr=10399&refresh_token=ab1696dd&x-expires=1789934400&x-signature=0JUqM61yKILyekGKeGJkVlJ3bgk%3D&t=4d5b0474&ps=13740610&shp=a5d48078&shcp=81f88b70&idc=no1a")) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Filmeacc")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Just my TikTok account")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // about
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Server")
                        Spacer()
                        Text("nicheloader.onrender.com")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
