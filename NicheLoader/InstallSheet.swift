import SwiftUI

struct InstallSheet: View {
    @Environment(\.dismiss) var dismiss
    let app: SignedApp
    @StateObject var libraryManager = LibraryManager.shared
    @State private var isInstalling = false
    @State private var progress: Double = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                if let icon = libraryManager.iconImage(for: app) {
                    Image(uiImage: icon)
                        .resizable()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                } else {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color(.systemGray5))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "app.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.purple)
                        )
                }
                
                Text(app.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(app.version) • \(app.bundleID)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if isInstalling {
                    VStack(spacing: 8) {
                        ProgressView(value: progress)
                            .tint(.purple)
                        Text("Installing...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                Button {
                    install()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Install")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .disabled(isInstalling)
                
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    func install() {
        isInstalling = true
        progress = 0.3
        
        Task {
            do {
                // Upload the app for installation
                try await ServerAPI.uploadIPA(URL(fileURLWithPath: app.ipaPath))
                try await ServerAPI.sign()
                
                await MainActor.run {
                    progress = 1.0
                    ServerAPI.install()
                }
                
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                
                await MainActor.run {
                    isInstalling = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isInstalling = false
                }
            }
        }
    }
}
