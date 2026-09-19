import SwiftUI

struct LibraryInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    let app: SignedApp
    @StateObject var libraryManager = LibraryManager.shared
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
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
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                
                Section("Info") {
                    row("Name", app.name)
                    row("Version", app.version)
                    row("Identifier", app.bundleID)
                    row("Date Added", app.date.formatted(date: .abbreviated, time: .shortened))
                }
                
                Section("Actions") {
                    Button {
                        export()
                    } label: {
                        Label("Export IPA", systemImage: "square.and.arrow.up")
                            .foregroundColor(.purple)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        libraryManager.delete(app)
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .navigationTitle(app.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
    
    func export() {
        let url = URL(fileURLWithPath: app.ipaPath)
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(vc, animated: true)
        }
    }
}
