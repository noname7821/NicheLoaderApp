import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            List {
                // About
                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label {
                            Text("About")
                        } icon: {
                            Image(systemName: "info.circle")
                                .foregroundColor(.purple)
                        }
                    }
                }
                
                // Appearance
                Section {
                    NavigationLink {
                        AppearanceView()
                    } label: {
                        Label {
                            Text("App Icon")
                        } icon: {
                            Image(systemName: "app.badge")
                                .foregroundColor(.purple)
                        }
                    }
                    NavigationLink {
                        AppearanceView()
                    } label: {
                        Label {
                            Text("Appearance")
                        } icon: {
                            Image(systemName: "paintbrush")
                                .foregroundColor(.purple)
                        }
                    }
                }
                
                // Features
                Section("Features") {
                    NavigationLink {
                        LogsView()
                    } label: {
                        Label {
                            Text("Logs")
                        } icon: {
                            Image(systemName: "apple.terminal")
                                .foregroundColor(.purple)
                        }
                    }
                    NavigationLink {
                        CertificatesSettingsView()
                    } label: {
                        Label {
                            Text("Certificates")
                        } icon: {
                            Image(systemName: "signature")
                                .foregroundColor(.purple)
                        }
                    }
                    NavigationLink {
                        Text("Signing Options")
                    } label: {
                        Label {
                            Text("Signing Options")
                        } icon: {
                            Image(systemName: "gear")
                                .foregroundColor(.purple)
                        }
                    }
                }
                
                // Misc
                Section("Misc") {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label {
                            Text("Open Settings")
                                .foregroundColor(.purple)
                        } icon: {
                            Image(systemName: "gear")
                                .foregroundColor(.purple)
                        }
                    }
                }
                
                Section {
                    NavigationLink {
                        Text("Reset")
                    } label: {
                        Label {
                            Text("Reset")
                                .foregroundColor(.red)
                        } icon: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    if let icon = UIImage(named: "AppIcon") {
                        Image(uiImage: icon)
                            .resizable()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    } else {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.purple)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "shippingbox.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 40))
                            )
                    }
                    Text("NicheLoader")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.3")")
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
                            image.resizable()
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Mintoo")
                                .font(.headline).foregroundColor(.primary)
                            Text("Solo Developer")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.footnote).foregroundColor(.secondary)
                    }
                }
                
                Link(destination: URL(string: "https://www.tiktok.com/@filmeacc")!) {
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: "https://p16-common-sign.tiktokcdn-eu.com/tos-no1a-avt-0068c001-no/55493ade73a29ea3c127a707d9383110~tplv-tiktokx-cropcenter:100:100.jpeg")) { image in
                            image.resizable()
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Filmeacc")
                                .font(.headline).foregroundColor(.primary)
                            Text("Just my TikTok account")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.footnote).foregroundColor(.secondary)
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

struct AppearanceView: View {
    @AppStorage("appColor") private var appColor: String = "purple"
    
    let colors: [(String, Color)] = [
        ("Default", .purple),
        ("Cherry", Color(red: 1.0, green: 0.4, blue: 0.5)),
        ("Red", .red),
        ("Orange", .orange),
        ("Yellow", .yellow),
        ("Green", .green),
        ("Blue", .blue),
        ("Purple", .purple),
        ("Pink", .pink),
        ("Indigo", .indigo),
        ("Mint", .mint),
        ("Cyan", .cyan),
        ("Teal", .teal)
    ]
    
    var body: some View {
        List {
            Section("Accent Color") {
                ForEach(colors, id: \.0) { name, color in
                    Button {
                        appColor = name.lowercased()
                    } label: {
                        HStack {
                            Circle()
                                .fill(color)
                                .frame(width: 24, height: 24)
                            Text(name)
                                .foregroundColor(.primary)
                            Spacer()
                            if appColor == name.lowercased() {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LogsView: View {
    var body: some View {
        List {
            Text("No logs yet")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Logs")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CertificatesSettingsView: View {
    @StateObject var certManager = CertificateManager.shared
    @State private var showAdd = false
    
    var body: some View {
        Group {
            if certManager.certificates.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "questionmark.folder.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("No Certificates")
                        .font(.title3).fontWeight(.semibold)
                    Text("Get started signing by importing your first certificate.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button {
                        showAdd = true
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
                .navigationTitle("Certificates")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showAdd = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            } else {
                List {
                    ForEach(certManager.certificates) { cert in
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.purple)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(cert.name).font(.headline)
                                Text(cert.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                certManager.delete(cert)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .navigationTitle("Certificates")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showAdd = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddCertificateView()
        }
    }
}
