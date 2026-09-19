import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @StateObject var certManager = CertificateManager.shared
    @State private var selectedIPA: URL?
    @State private var showIPAImporter = false
    @State private var showSigningView = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.purple)
                
                Text("NicheLoader")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Sign and install IPAs with ease")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button {
                    showIPAImporter = true
                } label: {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                        Text("Select IPA")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 30)
                
                Text("Import an IPA to start signing")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 40)
            }
            .navigationTitle("Sign")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showIPAImporter) {
                DocumentPickerView { url in
                    selectedIPA = url
                    showSigningView = true
                }
            }
            .sheet(isPresented: $showSigningView) {
                if let ipa = selectedIPA {
                    SigningView(ipaURL: ipa)
                }
            }
        }
    }
}
