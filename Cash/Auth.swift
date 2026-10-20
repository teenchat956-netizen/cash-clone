import SwiftUI

@MainActor
final class Auth: ObservableObject {
    @Published var locked = false
    func boot(_ settings: Settings) async { locked = false }
    func unlock() { locked = false }
}

struct LockView: View {
    @EnvironmentObject private var auth: Auth
    @State private var pin = ""
    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "lock.fill").font(.system(size: 34, weight: .semibold)).foregroundStyle(Ink.green)
            Text("Welcome back").font(.system(size: 30, weight: .bold))
            Text("Enter your demo PIN").foregroundStyle(.secondary)
            SecureField("4-digit PIN", text: $pin).keyboardType(.numberPad).multilineTextAlignment(.center).font(.system(size: 24, weight: .bold)).padding().background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
            Button("Unlock") { auth.unlock() }.font(.system(size: 17, weight: .bold)).foregroundStyle(.black).frame(maxWidth: .infinity).padding().background(Ink.green, in: Capsule())
            Text("Demo wallet only — no real money moves.").font(.footnote).foregroundStyle(.secondary)
        }.padding(28).frame(maxWidth: .infinity, maxHeight: .infinity).background(Ink.black.ignoresSafeArea()).preferredColorScheme(.dark)
    }
}
