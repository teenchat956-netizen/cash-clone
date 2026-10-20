import SwiftUI

struct RootView: View {
    @EnvironmentObject private var wallet: Wallet
    @State private var selected: Tab = .home
    @State private var showAdd = false
    @State private var showSend = false
    @State private var showRequest = false
    @State private var showFamily = false
    @State private var amountText = ""
    @State private var toast: String?

    private var amount: Decimal { Fmt.parse(amountText) }

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selected {
                case .home: home
                case .pay: pay
                case .activity: activity
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            bottomBar
        }
        .background(Ink.sheet.ignoresSafeArea())
        .preferredColorScheme(.light)
        .sheet(isPresented: $showAdd) { amountSheet(title: "Add money", subtitle: "Demo balance", actionTitle: "Add money") { wallet.deposit(amount); toast = "Demo balance updated" } }
        .sheet(isPresented: $showSend) { sendSheet }
        .sheet(isPresented: $showRequest) { amountSheet(title: "Request money", subtitle: "Create a demo request", actionTitle: "Create request") { if let person = wallet.people.first { wallet.request(from: person, amount: amount, note: "Payment request") }; toast = "Demo request created" } }
        .sheet(isPresented: $showFamily) { familySheet }
        .alert("Cash Demo", isPresented: Binding(get: { toast != nil }, set: { if !$0 { toast = nil } })) { Button("OK") { toast = nil } } message: { Text(toast ?? "") }
    }

    private var home: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Good afternoon").font(.system(size: 14, weight: .medium)).foregroundStyle(.white.opacity(0.65))
                            Text(wallet.profile.name).font(.system(size: 24, weight: .bold)).foregroundStyle(.white)
                        }
                        Spacer()
                        Button { selected = .activity } label: {
                            Image(systemName: "bell.badge").font(.system(size: 19, weight: .semibold))
                                .foregroundStyle(.white).frame(width: 46, height: 46)
                                .background(.white.opacity(0.12), in: Circle())
                        }
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("AVAILABLE BALANCE").font(.system(size: 11, weight: .bold, design: .rounded)).tracking(1.4).foregroundStyle(.white.opacity(0.65))
                        Text(Fmt.money(wallet.balance)).font(.system(size: 42, weight: .bold, design: .rounded)).tracking(-1.5).foregroundStyle(.white)
                        Text("Demo balance · not real money").font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.6))
                    }
                    HStack(spacing: 10) {
                        actionPill("Add money", icon: "plus", fill: Ink.green, text: .black) { amountText = ""; showAdd = true }
                        actionPill("Pay", icon: "arrow.up.right", fill: .white.opacity(0.13), text: .white) { amountText = ""; showSend = true }
                        actionPill("Request", icon: "arrow.down.left", fill: .white.opacity(0.13), text: .white) { amountText = ""; showRequest = true }
                    }
                }
                .padding(22)
                .padding(.top, 12)
                .background(LinearGradient(colors: [Ink.black, Color(hex: 0x202124)], startPoint: .topLeading, endPoint: .bottomTrailing))

                VStack(spacing: 18) {
                    HStack {
                        Text("Your money").font(.system(size: 21, weight: .bold))
                        Spacer()
                        Button("See all") { selected = .activity }.font(.system(size: 14, weight: .semibold)).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 12) {
                        miniTile(icon: "creditcard.fill", title: "Cash Card", detail: "•• " + wallet.card.last4, tint: Ink.green) { toast = wallet.card.frozen ? "Your demo card is frozen" : "Your demo card is active" }
                        miniTile(icon: "chart.line.uptrend.xyaxis", title: "Investing", detail: "\(wallet.holdings.count) assets", tint: Color(hex: 0x6B65E8)) { toast = "Investing is a demo feature" }
                    }
                    HStack {
                        Text("Family").font(.system(size: 21, weight: .bold))
                        Spacer()
                        Button("Manage") { showFamily = true }.font(.system(size: 14, weight: .semibold)).foregroundStyle(.secondary)
                    }
                    WhiteTile {
                        if wallet.family.isEmpty {
                            HStack { Image(systemName: "person.2.fill").foregroundStyle(Ink.dim); Text("Add someone to your family").foregroundStyle(.secondary); Spacer(); Button("Add") { showFamily = true }.foregroundStyle(.black) }
                        } else {
                            ForEach(wallet.family) { member in
                                HStack(spacing: 12) {
                                    Monogram(text: String(member.name.prefix(1)).uppercased(), color: Color(hexString: member.hex) ?? Ink.green)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(member.name).font(.system(size: 15, weight: .bold))
                                        Text(member.role).font(.system(size: 13)).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundStyle(Ink.dim)
                                }
                            }
                        }
                    }
                    HStack {
                        Text("Recent activity").font(.system(size: 21, weight: .bold))
                        Spacer()
                        Button("View all") { selected = .activity }.font(.system(size: 14, weight: .semibold)).foregroundStyle(.secondary)
                    }
                    if wallet.txns.isEmpty {
                        EmptyBlock(icon: "clock", title: "Nothing yet", body_: "Your demo activity will appear here.")
                    } else {
                        WhiteTile(padding: 0) {
                            VStack(spacing: 0) {
                                ForEach(Array(wallet.txns.prefix(4))) { txn in transactionRow(txn); if txn.id != wallet.txns.prefix(4).last?.id { Hairline() } }
                            }
                        }
                    }
                    Text("Cash is an independent demo project. Transactions and balances are simulated.")
                        .font(.system(size: 11)).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 12).padding(.bottom, 12)
                }
                .padding(18)
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    private var pay: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Pay & request").font(.system(size: 30, weight: .bold))
                Text("Move through a simulated wallet. No real payments are processed.")
                    .font(.system(size: 14)).foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    IconTile(icon: "arrow.up.right", label: "Send money", tint: Ink.green) { amountText = ""; showSend = true }
                    IconTile(icon: "arrow.down.left", label: "Request money", tint: Color(hex: 0x5275E8)) { amountText = ""; showRequest = true }
                    IconTile(icon: "plus", label: "Add balance", tint: Color(hex: 0xE49A22)) { amountText = ""; showAdd = true }
                }
                SectionTitle(text: "People")
                ForEach(wallet.people) { person in
                    Button { amountText = ""; showSend = true } label: {
                        HStack(spacing: 12) {
                            Monogram(text: person.initials, color: Color(hexString: person.hex) ?? Ink.ghost)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(person.name).font(.system(size: 15, weight: .bold)).foregroundStyle(Ink.black)
                                Text("$\(person.cashtag)").font(.system(size: 13)).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right").foregroundStyle(Ink.dim)
                        }.padding(12).background(.white, in: RoundedRectangle(cornerRadius: 18))
                    }.buttonStyle(.plain)
                }
            }.padding(18)
        }.background(Ink.sheet).safeAreaPadding(.top, 12)
    }

    private var activity: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Activity").font(.system(size: 30, weight: .bold))
                Text("Your recent demo transactions").font(.system(size: 14)).foregroundStyle(.secondary)
                WhiteTile(padding: 0) {
                    if wallet.txns.isEmpty { EmptyBlock(icon: "clock", title: "No activity yet", body_: "Try adding demo money or creating a payment.") }
                    else {
                        VStack(spacing: 0) {
                            ForEach(Array(wallet.txns.sorted { $0.date > $1.date })) { txn in
                                transactionRow(txn)
                                if txn.id != wallet.txns.sorted { $0.date > $1.date }.last?.id { Hairline() }
                            }
                        }
                    }
                }
                Button("Reset demo data") { wallet.resetDemo(); toast = "Demo data reset" }
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(.red).frame(maxWidth: .infinity).padding(.top, 12)
            }.padding(18)
        }.background(Ink.sheet).safeAreaPadding(.top, 12)
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            tabButton(.home, label: "Home")
            tabButton(.pay, label: "Pay")
            tabButton(.activity, label: "Activity")
        }
        .padding(.top, 10).padding(.bottom, 6)
        .background(.white.shadow(.drop(color: .black.opacity(0.06), radius: 8, y: -3)))
    }

    private func tabButton(_ tab: Tab, label: String) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.18)) { selected = tab } } label: {
            VStack(spacing: 5) {
                Image(systemName: tab.icon).font(.system(size: 19, weight: .semibold))
                Text(label).font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(selected == tab ? Ink.black : Ink.dim)
            .frame(maxWidth: .infinity)
        }.buttonStyle(.plain)
    }

    private func actionPill(_ title: String, icon: String, fill: Color, text: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) { Image(systemName: icon); Text(title).lineLimit(1) }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(text).frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(fill, in: Capsule())
        }.buttonStyle(.plain)
    }

    private func miniTile(icon: String, title: String, detail: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon).font(.system(size: 18, weight: .bold)).foregroundStyle(tint)
                Text(title).font(.system(size: 15, weight: .bold)).foregroundStyle(Ink.black)
                Text(detail).font(.system(size: 13)).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading).padding(16)
                .background(.white, in: RoundedRectangle(cornerRadius: 20))
        }.buttonStyle(.plain)
    }

    private func transactionRow(_ txn: Txn) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(iconTint(txn.kind).opacity(0.13)).frame(width: 44, height: 44)
                Image(systemName: iconName(txn.kind)).font(.system(size: 16, weight: .semibold)).foregroundStyle(iconTint(txn.kind))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(txn.title).font(.system(size: 14, weight: .bold)).foregroundStyle(Ink.black)
                Text(txn.subtitle ?? txn.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(Fmt.money(txn.amount, signed: true)).font(.system(size: 14, weight: .bold)).foregroundStyle(txn.amount < 0 ? Ink.black : Color(hex: 0x008A27))
                if txn.pending { Text("Pending").font(.system(size: 10, weight: .semibold)).foregroundStyle(.orange) }
            }
        }.padding(14)
    }

    private func iconName(_ kind: Txn.Kind) -> String {
        switch kind {
        case .sent: return "arrow.up.right"
        case .received: return "arrow.down.left"
        case .request: return "clock"
        case .deposit: return "plus"
        case .withdrawal: return "arrow.up.right.square"
        case .card: return "creditcard"
        case .buy: return "chart.line.uptrend.xyaxis"
        case .sell: return "chart.line.downtrend.xyaxis"
        case .recurring: return "repeat"
        }
    }

    private func iconTint(_ kind: Txn.Kind) -> Color {
        switch kind {
        case .received, .deposit, .sell: return Color(hex: 0x008A27)
        case .request: return Color(hex: 0xC88719)
        default: return Ink.ghost
        }
    }

    private func amountSheet(title: String, subtitle: String, actionTitle: String, action: @escaping () -> Void) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 22) {
                Text(subtitle).font(.system(size: 15)).foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("$").font(.system(size: 30, weight: .bold))
                    TextField("0.00", text: $amountText).keyboardType(.decimalPad).font(.system(size: 42, weight: .bold, design: .rounded))
                }
                .padding(.vertical, 18)
                .overlay(alignment: .bottom) { Rectangle().fill(Ink.hairline).frame(height: 1) }
                Spacer()
                Button(actionTitle) {
                    guard amount > 0 else { return }
                    action()
                    amountText = ""
                    dismissSheet()
                }
                .font(.system(size: 16, weight: .bold)).foregroundStyle(.black)
                .frame(maxWidth: .infinity).padding(17).background(Ink.green, in: Capsule())
            }
            .padding(22)
            .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Close") { dismissSheet() } } }
        }
        .presentationDetents([.medium])
    }

    private var sendSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Send demo money to a contact").font(.system(size: 15)).foregroundStyle(.secondary)
                if wallet.people.isEmpty {
                    Text("Add a contact first.").foregroundStyle(.secondary)
                } else {
                    ForEach(wallet.people) { person in
                        Button {
                            guard amount > 0 else { toast = "Enter an amount first"; return }
                            wallet.send(to: person, amount: amount, note: "Demo payment")
                            amountText = ""
                            showSend = false
                            toast = "Demo payment recorded"
                        } label: {
                            HStack { Monogram(text: person.initials, color: Color(hexString: person.hex) ?? Ink.ghost); Text(person.name).foregroundStyle(Ink.black); Spacer(); Image(systemName: "arrow.up.right").foregroundStyle(Ink.dim) }
                        }.buttonStyle(.plain)
                    }
                }
                HStack { Text("$"); TextField("Amount to send", text: $amountText).keyboardType(.decimalPad).font(.system(size: 25, weight: .bold)) }
                    .padding().background(Ink.sheet, in: RoundedRectangle(cornerRadius: 14))
                Spacer()
                Text("Only simulated. No money leaves an account.").font(.system(size: 12)).foregroundStyle(.secondary)
            }.padding(22).navigationTitle("Send money").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Close") { showSend = false } } }
        }.presentationDetents([.medium, .large])
    }

    private var familySheet: some View {
        NavigationStack {
            List {
                ForEach(wallet.family) { member in
                    HStack {
                        Monogram(text: String(member.name.prefix(1)).uppercased(), color: Color(hexString: member.hex) ?? Ink.green)
                        VStack(alignment: .leading) { Text(member.name); Text(member.role).font(.caption).foregroundStyle(.secondary) }
                        Spacer()
                        Button(role: .destructive) { wallet.family.removeAll { $0.id == member.id } } label: { Image(systemName: "trash") }
                    }
                }
                .onDelete { wallet.family.remove(atOffsets: $0) }
                Button { let member = FamilyMember(name: "Family member", role: "Member", hex: "00A828", photo: "person.fill"); wallet.family.append(member) } label: {
                    Label("Add family member", systemImage: "plus")
                }
            }
            .navigationTitle("Family")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showFamily = false } } }
        }.presentationDetents([.medium, .large])
    }

    @Environment(\.dismiss) private var dismiss
    private func dismissSheet() { dismiss() }
}
