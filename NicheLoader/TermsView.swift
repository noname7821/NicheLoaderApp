import SwiftUI

struct TermsView: View {
    @AppStorage("hasAcceptedTerms") private var hasAcceptedTerms: Bool = false
    @State private var termsText: String = "Loading terms..."
    @State private var isLoading: Bool = true
    @State private var showContent: Bool = false
    
    var body: some View {
        if hasAcceptedTerms {
            ContentView()
                .transition(.opacity)
        } else {
            termsScreen
        }
    }
    
    var termsScreen: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 70))
                .foregroundColor(.purple)
                .scaleEffect(showContent ? 1.0 : 0.5)
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showContent)
            
            Text("NicheLoader")
                .font(.largeTitle)
                .fontWeight(.bold)
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.4).delay(0.1), value: showContent)
            
            Text("Terms of Service")
                .font(.title3)
                .foregroundColor(.secondary)
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: showContent)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text(termsText)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            .frame(maxHeight: 320)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            .opacity(showContent ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.4).delay(0.3), value: showContent)
            
            Text("There is more text, please scroll down to see more")
                .font(.caption2)
                .foregroundColor(.purple)
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.4).delay(0.35), value: showContent)
            
            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    hasAcceptedTerms = true
                }
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
            .opacity(showContent ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.4).delay(0.4), value: showContent)
            
            Button {
                exit(0)
            } label: {
                Text("Decline")
                    .foregroundColor(.red)
            }
            .opacity(showContent ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.4).delay(0.5), value: showContent)
            
            Spacer()
        }
        .padding()
        .onAppear {
            loadTerms()
            withAnimation {
                showContent = true
            }
        }
    }
    
    func loadTerms() {
        let url = "https://raw.githubusercontent.com/noname7821/NicheLoaderApp/main/updates/terms.txt"
        UpdateChecker.fetchText(url) { text in
            DispatchQueue.main.async {
                self.termsText = text ?? "Failed to load terms."
                self.isLoading = false
            }
        }
    }
}
