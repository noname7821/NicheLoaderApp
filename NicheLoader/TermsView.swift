import SwiftUI

struct TermsView: View {
    @AppStorage("hasAcceptedTerms") private var hasAcceptedTerms: Bool = false
    @State private var showDetails = false
    
    var body: some View {
        if hasAcceptedTerms {
            ContentView()
        } else {
            termsScreen
        }
    }
    
    var termsScreen: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.purple)
            
            Text("NicheLoader")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Terms of Service")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Text("Last updated: 2026")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    termSection(
                        title: "1. LEGAL USE ONLY",
                        text: "You agree to use NicheLoader only for legal purposes.\n\nDo NOT use this app to install:\n• Pirated/cracked apps\n• Software you don't own\n• Apps that violate Apple's ToS\n• Any illegal content"
                    )
                    
                    termSection(
                        title: "2. NO DATA COLLECTION",
                        text: "NicheLoader does not collect, store, or share your personal data.\n\nYour IPAs and certificates are processed locally and on your own server (nicheloader.onrender.com).\n\nNo analytics, no tracking, no telemetry."
                    )
                    
                    termSection(
                        title: "3. NO WARRANTY",
                        text: "This app is provided \"as is\" without warranty.\n\nThe developers are not responsible for:\n• Account bans from Apple\n• App crashes\n• Data loss\n• Legal issues from misuse"
                    )
                    
                    termSection(
                        title: "4. YOUR RESPONSIBILITY",
                        text: "You are 100% responsible for:\n• The IPAs you sign\n• Your certificates\n• Your actions with this app"
                    )
                }
                .padding()
            }
            .frame(maxHeight: 350)
            
            Button {
                hasAcceptedTerms = true
            } label: {
                Text("I Agree")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            .padding(.horizontal, 30)
            
            Button {
                exit(0)
            } label: {
                Text("Decline")
                    .foregroundColor(.red)
            }
            
            Spacer()
        }
        .padding()
    }
    
    func termSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundColor(.purple)
            Text(text)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }
}
