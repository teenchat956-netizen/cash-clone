import SwiftUI

@main
struct CashApp: App {
    @StateObject private var wallet = Wallet()
    @StateObject private var auth = Auth()

    var body: some Scene {
        WindowGroup {
            ZStack {
                Ink.black.ignoresSafeArea()
                if auth.locked { LockView() } else { RootView() }
            }
            .environmentObject(wallet)
            .environmentObject(auth)
            .preferredColorScheme(.dark)
            .task { await auth.boot(wallet.settings) }
        }
    }
}
