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
                        AppIconView()
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
                        SigningOptionsView()
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
                
                // Reset
                Section {
                    NavigationLink {
                        ResetView()
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

// MARK: - About

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    if let icon = Bundle.main.icon {
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
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.4")")
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
                        AsyncImage(url: URL(string: "https://avatars.githubusercontent.com/u/210064350?s=400&u=539b1b1eb9554c4654472d091675d6804f0ff3df&v=4")) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().aspectRatio(contentMode: .fill)
                            default:
                                Color.gray
                            }
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
                        AsyncImage(url: URL(string: "https://p16-common-sign.tiktokcdn-eu.com/tos-no1a-avt-0068c001-no/55493ade73a29ea3c127a707d9383110~tplv-tiktokx-cropcenter:100:100.jpeg")) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().aspectRatio(contentMode: .fill)
                            default:
                                Color.purple.opacity(0.3)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.white)
                                    )
                            }
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

// MARK: - App Icon

struct AppIconView: View {
    @State private var selectedIcon = "AppIcon"
    
    let icons: [(String, String)] = [
        ("AppIcon", "Default"),
        ("AppIconPurple", "Purple"),
        ("AppIconDark", "Dark")
    ]
    
    var body: some View {
        List {
            Section("Available Icons") {
                ForEach(icons, id: \.0) { iconName, title in
                    Button {
                        selectIcon(iconName)
                    } label: {
                        HStack(spacing: 12) {
                            if let icon = UIImage(named: iconName) {
                                Image(uiImage: icon)
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 13))
                            } else {
                                RoundedRectangle(cornerRadius: 13)
                                    .fill(Color.purple)
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "app.fill")
                                            .foregroundColor(.white)
                                            .font(.title2)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("NicheLoader")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedIcon == iconName {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func selectIcon(_ name: String) {
        selectedIcon = name
        if UIApplication.shared.supportsAlternateIcons {
            UIApplication.shared.setAlternateIconName(name == "AppIcon" ? nil : name) { _ in }
        }
    }
}

// MARK: - Appearance

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
                HStack {
                    Circle()
                        .fill(currentColor())
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading) {
                        Text("Accent Color")
                            .font(.headline)
                        Text("This is the current accent color")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Section {
                ForEach(colors, id: \.0) { name, color in
                    Button {
                        appColor = name.lowercased()
                    } label: {
                        HStack(spacing: 12) {
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
            } header: {
                Text("Available Colors")
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func currentColor() -> Color {
        colors.first { $0.0.lowercased() == appColor }?.1 ?? .purple
    }
}

// MARK: - Logs

struct LogsView: View {
    @State private var logs: [String] = []
    
    var body: some View {
        List {
            if logs.isEmpty {
                Text("No logs yet")
                    .foregroundColor(.secondary)
            } else {
                ForEach(logs, id: \.self) { log in
                    Text(log)
                        .font(.system(.caption, design: .monospaced))
                }
            }
        }
        .navigationTitle("Logs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    logs.removeAll()
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
    }
}

// MARK: - Signing Options

struct SigningOptionsView: View {
    @AppStorage("removeAppAfterSigned") private var removeApp = false
    @AppStorage("doAdhocSigning") private var adhoc = false
    @AppStorage("fileSharing") private var fileSharing = false
    
    var body: some View {
        List {
            Section("General") {
                Toggle("Remove app after signed", isOn: $removeApp)
                Toggle("Adhoc Signing", isOn: $adhoc)
            }
            
            Section("App Features") {
                Toggle("File Sharing", isOn: $fileSharing)
            }
        }
        .navigationTitle("Signing Options")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Reset

struct ResetView: View {
    @State private var showConfirm = false
    @State private var resetType = ""
    
    var body: some View {
        List {
            Section {
                Button {
                    resetType = "Work Cache"
                    showConfirm = true
                } label: {
                    Label("Reset Work Cache", systemImage: "xmark.square")
                        .foregroundColor(.purple)
                }
                Button {
                    resetType = "Network Cache"
                    showConfirm = true
                } label: {
                    Label("Reset Network Cache", systemImage: "xmark.square")
                        .foregroundColor(.purple)
                }
            }
            
            Section {
                Button {
                    resetType = "Signed Apps"
                    showConfirm = true
                } label: {
                    Label("Reset Signed Apps", systemImage: "xmark.circle")
                        .foregroundColor(.purple)
                }
                Button {
                    resetType = "Imported Apps"
                    showConfirm = true
                } label: {
                    Label("Reset Imported Apps", systemImage: "xmark.circle")
                        .foregroundColor(.purple)
                }
                Button {
                    resetType = "Certificates"
                    showConfirm = true
                } label: {
                    Label("Reset Certificates", systemImage: "xmark.circle")
                        .foregroundColor(.purple)
                }
            }
            
            Section {
                Button(role: .destructive) {
                    resetType = "Settings"
                    showConfirm = true
                } label: {
                    Label("Reset Settings", systemImage: "xmark.circle")
                }
                Button(role: .destructive) {
                    resetType = "All"
                    showConfirm = true
                } label: {
                    Label("Reset All", systemImage: "xmark.circle")
                }
            }
        }
        .navigationTitle("Reset")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Reset \(resetType)?", isPresented: $showConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                performReset()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    func performReset() {
        switch resetType {
        case "Signed Apps":
            LibraryManager.shared.apps.removeAll()
            LibraryManager.shared.save()
        case "Certificates":
            CertificateManager.shared.certificates.removeAll()
            CertificateManager.shared.save()
        case "Imported Apps":
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let appsDir = docs.appendingPathComponent("Apps")
            try? FileManager.default.removeItem(at: appsDir)
        case "All":
            LibraryManager.shared.apps.removeAll()
            LibraryManager.shared.save()
            CertificateManager.shared.certificates.removeAll()
            CertificateManager.shared.save()
        default:
            break
        }
    }
}

// MARK: - Certificates Settings

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
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.purple)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(cert.name).font(.headline)
                                Text(cert.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            if certManager.selectedID == cert.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.purple)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            certManager.selectedID = cert.id
                            certManager.save()
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

// MARK: - Bundle Icon Helper

extension Bundle {
    var icon: UIImage? {
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let files = primary["CFBundleIconFiles"] as? [String],
           let last = files.last {
            return UIImage(named: last)
        }
        return nil
    }
}
