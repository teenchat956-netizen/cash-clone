import Foundation
import Combine
import SwiftUI

enum Tab: String, CaseIterable, Identifiable {
    case home, pay, activity
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .pay: return "dollarsign"
        case .activity: return "clock"
        }
    }
}

enum AssetKind: String, Codable { case stock, crypto }
enum Side: String, Codable { case buy, sell }

struct Profile: Codable, Equatable {
    var name = "Alex Rivera"
    var cashtag = "alexrivera"
    var initials = "AR"
    var avatarHex = "1C1C1E"
    var phone = "+1 (555) 010-2288"
}

struct Txn: Codable, Identifiable, Hashable {
    enum Kind: String, Codable {
        case sent, received, request, deposit, withdrawal, card, buy, sell, recurring
    }
    var id = UUID()
    var kind: Kind
    var title: String
    var subtitle: String?
    var amount: Decimal
    var note: String?
    var person: String?
    var symbol: String?
    var qty: Decimal?
    var pending = false
    var date = Date()
    var ref: String { String(id.uuidString.prefix(8)).uppercased() }
}

struct Person: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var cashtag: String
    var hex: String
    var favorite = false
    var initials: String {
        name.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined().uppercased()
    }
}

struct FamilyMember: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var role: String
    var hex: String
    var photo: String
}

enum Finish: String, Codable, CaseIterable, Identifiable {
    case matte, gloss, metal, holo
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum Pattern: String, Codable, CaseIterable, Identifiable {
    case plain, dollars, stars, marble, grid
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

struct CardDesign: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var hex: String
    var finish: Finish = .matte
    var pattern: Pattern = .dollars
    var holder = "ALEX RIVERA"
}

struct CashCard: Codable {
    var designs: [CardDesign]
    var activeID: UUID
    var number = "4821 0039 7714 4821"
    var expiry = "09/29"
    var cvv = "314"
    var frozen = false
    var shipped = true
    var active: CardDesign {
        get { designs.first { $0.id == activeID } ?? designs[0] }
        set { if let i = designs.firstIndex(where: { $0.id == activeID }) { designs[i] = newValue } }
    }
    var last4: String { String(number.suffix(4)) }
}

struct Holding: Codable, Identifiable, Hashable {
    var id = UUID()
    var symbol: String
    var name: String
    var kind: AssetKind
    var qty: Decimal
    var avgCost: Decimal
}

struct Goal: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var emoji: String
    var target: Decimal
    var saved: Decimal
    var hex: String
    var progress: Double { target == 0 ? 0 : ((saved / target) as NSDecimalNumber).doubleValue }
}

struct Budget: Codable, Identifiable, Hashable {
    var id = UUID()
    var category: String
    var icon: String
    var limit: Decimal
    var spent: Decimal
    var remaining: Decimal { max(limit - spent, 0) }
    var used: Double { limit == 0 ? 0 : ((spent / limit) as NSDecimalNumber).doubleValue }
}

struct Note: Codable, Identifiable, Hashable {
    var id = UUID()
    var title: String
    var body: String
    var icon: String
    var date = Date()
    var read = false
}

struct Settings: Codable, Equatable {
    var pin = "1234"
    var pinOn = true
    var faceID = true
    var hideBalances = false
    var haptics = true
    var pushOn = true
    var priceAlerts = true
}

enum Load: Equatable {
    case idle, loading, loaded, failed(String)
    var msg: String? { if case .failed(let m) = self { return m }; return nil }
}

struct Quote: Identifiable, Hashable {
    var id: String { symbol }
    let symbol: String
    let name: String
    let kind: AssetKind
    let price: Decimal
    let pct: Decimal
    var isUp: Bool { pct >= 0 }
}

struct Point: Identifiable, Hashable {
    var id: Date { date }
    let date: Date
    let close: Decimal
}

// MARK: - Persistence

struct Snapshot: Codable {
    var v = 1
    var profile: Profile
    var balance: Decimal
    var txns: [Txn]
    var people: [Person]
    var family: [FamilyMember]
    var card: CashCard
    var holdings: [Holding]
    var goals: [Goal]
    var budgets: [Budget]
    var notes: [Note]
    var settings: Settings
}

enum Disk {
    static var url: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("cash-state.json")
    }
    static func load() -> Snapshot? {
        guard let d = try? Data(contentsOf: url) else { return nil }
        let dec = JSONDecoder(); dec.dateDecodingStrategy = .iso8601
        return try? dec.decode(Snapshot.self, from: d)
    }
    static func save(_ s: Snapshot) {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let d = try? enc.encode(s) else { return }
        try? d.write(to: url, options: .atomic)
    }
    static func wipe() { try? FileManager.default.removeItem(at: url) }
}

// MARK: - Catalog

enum Catalog {
    struct Meta: Identifiable, Hashable {
        var id: String { symbol }
        let symbol: String; let name: String; let hex: String
    }
    static let stocks: [Meta] = [
        .init(symbol:"AAPL",name:"Apple Inc.",hex:"3A3A3C"),
        .init(symbol:"MSFT",name:"Microsoft Corp.",hex:"2F6FB5"),
        .init(symbol:"NVDA",name:"NVIDIA Corp.",hex:"4C9A2A"),
        .init(symbol:"TSLA",name:"Tesla Inc.",hex:"B3241C"),
        .init(symbol:"AMZN",name:"Amazon.com Inc.",hex:"C98A2B"),
        .init(symbol:"GOOGL",name:"Alphabet Inc.",hex:"3B7DD8"),
        .init(symbol:"META",name:"Meta Platforms",hex:"2C6FBF"),
        .init(symbol:"SPOT",name:"Spotify Technology",hex:"1DB954"),
        .init(symbol:"COIN",name:"Coinbase Global",hex:"2B5FD9"),
        .init(symbol:"SHOP",name:"Shopify Inc.",hex:"5E8E3E")
    ]
    static let coins: [(sym: String, name: String, gecko: String, hex: String)] = [
        ("BTC","Bitcoin","bitcoin","F7931A"),
        ("ETH","Ethereum","ethereum","627EEA"),
        ("SOL","Solana","solana","14F195"),
        ("DOGE","Dogecoin","dogecoin","C2A633")
    ]
    static func stock(_ s: String) -> Meta? { stocks.first { $0.symbol == s } }
    static func coin(_ s: String) -> (sym: String, name: String, gecko: String, hex: String)? {
        coins.first { $0.sym == s }
    }
}

// MARK: - Seed

enum Seed {
    struct Bag {
        var profile = Profile()
        var balance: Decimal = 0.39
        var txns: [Txn]
        var people: [Person]
        var family: [FamilyMember]
        var card: CashCard
        var holdings: [Holding]
        var goals: [Goal]
        var budgets: [Budget]
        var notes: [Note]
    }

    static func bag() -> Bag {
        let now = Date()
        func ago(_ d: Int) -> Date { Calendar.current.date(byAdding: .day, value: -d, to: now) ?? now }

        let people: [Person] = [
            .init(name: "Maya Chen", cashtag: "mayachen", hex: "2C2C2E", favorite: true),
            .init(name: "Jordan Blake", cashtag: "jblake", hex: "3A3A3C", favorite: true),
            .init(name: "Priya Patel", cashtag: "priyap", hex: "48484A"),
            .init(name: "Marcus Reed", cashtag: "mreed", hex: "5A5A5C"),
            .init(name: "Sofia Nguyen", cashtag: "sofian", hex: "2A2A2A"),
            .init(name: "Daniel Okafor", cashtag: "danok", hex: "6A6A6C")
        ]

        let txns: [Txn] = [
            .init(kind: .sent, title: "Maya Chen", subtitle: "Coffee + lunch", amount: -18.40, person: "Maya Chen", date: now.addingTimeInterval(-2400)),
            .init(kind: .received, title: "Jordan Blake", subtitle: "Concert tickets", amount: 84.00, person: "Jordan Blake", date: now.addingTimeInterval(-9000)),
            .init(kind: .card, title: "Blue Bottle Coffee", subtitle: "Card ••4821", amount: -6.75, date: ago(1)),
            .init(kind: .buy, title: "Bought Bitcoin", subtitle: "0.0031 BTC", amount: -212.44, symbol: "BTC", qty: 0.0031, date: ago(2)),
            .init(kind: .deposit, title: "Payroll", subtitle: "Northwind Labs", amount: 2140.00, date: ago(3)),
            .init(kind: .recurring, title: "Spotify Premium", subtitle: "Monthly", amount: -11.99, date: ago(4)),
            .init(kind: .sent, title: "Priya Patel", subtitle: "Rent share", amount: -650.00, person: "Priya Patel", date: ago(6)),
            .init(kind: .sell, title: "Sold Apple", subtitle: "2 AAPL", amount: 391.20, symbol: "AAPL", qty: 2, date: ago(8)),
            .init(kind: .card, title: "Uber", subtitle: "Card ••4821", amount: -23.10, date: ago(9)),
            .init(kind: .withdrawal, title: "Withdrawal", subtitle: "Bank ••4471", amount: -300.00, date: ago(11)),
            .init(kind: .request, title: "Sofia Nguyen", subtitle: "Brunch", amount: 26.50, person: "Sofia Nguyen", pending: true, date: ago(13)),
            .init(kind: .card, title: "Trader Joe's", subtitle: "Card ••4821", amount: -62.18, date: ago(15))
        ]

        let designs: [CardDesign] = [
            .init(name: "Midnight", hex: "0B0B0B", finish: .matte, pattern: .dollars, holder: "ALEX RIVERA"),
            .init(name: "Bone", hex: "F4F4F2", finish: .matte, pattern: .plain, holder: "ALEX RIVERA"),
            .init(name: "Cash Green", hex: "00D632", finish: .gloss, pattern: .dollars, holder: "ALEX RIVERA")
        ]

        let holdings: [Holding] = [
            .init(symbol: "BTC", name: "Bitcoin", kind: .crypto, qty: 0.0421, avgCost: 58200),
            .init(symbol: "ETH", name: "Ethereum", kind: .crypto, qty: 1.24, avgCost: 2880),
            .init(symbol: "AAPL", name: "Apple Inc.", kind: .stock, qty: 6, avgCost: 182.10),
            .init(symbol: "NVDA", name: "NVIDIA Corp.", kind: .stock, qty: 3.5, avgCost: 104.20),
            .init(symbol: "SPOT", name: "Spotify Technology", kind: .stock, qty: 2, avgCost: 214.00)
        ]

        let goals: [Goal] = [
            .init(name: "Japan trip", emoji: "✈️", target: 4000, saved: 1850, hex: "00D632"),
            .init(name: "New MacBook", emoji: "💻", target: 2500, saved: 640, hex: "1C1C1E"),
            .init(name: "Emergency fund", emoji: "🛟", target: 10000, saved: 7300, hex: "00A828")
        ]

        let budgets: [Budget] = [
            .init(category: "Eating out", icon: "fork.knife", limit: 400, spent: 268),
            .init(category: "Transport", icon: "car.fill", limit: 180, spent: 96),
            .init(category: "Shopping", icon: "bag.fill", limit: 300, spent: 291),
            .init(category: "Fun", icon: "sparkles", limit: 150, spent: 42)
        ]

        let notes: [Note] = [
            .init(title: "Maya Chen paid you", body: "$18.40 · Coffee + lunch", icon: "arrow.down.left", date: now.addingTimeInterval(-1800)),
            .init(title: "Bitcoin is up 2.4%", body: "Tap to view your position", icon: "bitcoinsign.circle", date: now.addingTimeInterval(-7200)),
            .init(title: "Card purchase", body: "Blue Bottle Coffee · $6.75", icon: "creditcard", date: ago(1), read: true)
        ]

        return Bag(txns: txns, people: people,
                   family: [.init(name: "Yuli", role: "Sponsor", hex: "E8443A", photo: "bird.fill")],
                   card: CashCard(designs: designs, activeID: designs[0].id),
                   holdings: holdings, goals: goals, budgets: budgets, notes: notes)
    }

    static func fallback() -> [String: Quote] {
        var out: [String: Quote] = [:]
        let s: [(String, String, Double, Double)] = [
            ("AAPL","Apple Inc.",195.60,0.42),("MSFT","Microsoft Corp.",418.20,-0.31),
            ("NVDA","NVIDIA Corp.",118.95,1.87),("TSLA","Tesla Inc.",244.10,-2.05),
            ("AMZN","Amazon.com Inc.",186.40,0.63),("GOOGL","Alphabet Inc.",172.85,0.18),
            ("META","Meta Platforms",512.30,1.12),("SPOT","Spotify Technology",318.75,2.44),
            ("COIN","Coinbase Global",228.60,3.18),("SHOP","Shopify Inc.",78.40,-0.92)
        ]
        let c: [(String, String, Double, Double)] = [
            ("BTC","Bitcoin",68412.90,2.41),("ETH","Ethereum",3412.55,1.18),
            ("SOL","Solana",178.42,-0.94),("DOGE","Dogecoin",0.1642,4.02)
        ]
        for (k,n,p,d) in s { out[k] = Quote(symbol: k, name: n, kind: .stock, price: Decimal(p), pct: Decimal(d)) }
        for (k,n,p,d) in c { out[k] = Quote(symbol: k, name: n, kind: .crypto, price: Decimal(p), pct: Decimal(d)) }
        return out
    }
}

// MARK: - Formatters

enum Fmt {
    private static let cur: NumberFormatter = {
        let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = "USD"
        f.maximumFractionDigits = 2; f.minimumFractionDigits = 2; return f
    }()
    static func money(_ d: Decimal, signed: Bool = false) -> String {
        let s = cur.string(from: d as NSDecimalNumber) ?? "$0.00"
        return signed && d > 0 ? "+" + s : s
    }
    static func pct(_ d: Decimal) -> String {
        (d > 0 ? "+" : "") + String(format: "%.2f", (d as NSDecimalNumber).doubleValue) + "%"
    }
    static func units(_ d: Decimal, _ places: Int) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal; f.maximumFractionDigits = places
        return f.string(from: d as NSDecimalNumber) ?? "0"
    }
    static func day(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d"; return f.string(from: d)
    }
    static func stamp(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d, yyyy · h:mm a"; return f.string(from: d)
    }
    static func round(_ d: Decimal, _ scale: Int) -> Decimal {
        var i = d, o = Decimal(); NSDecimalRound(&o, &i, scale, .plain); return o
    }
    static func parse(_ s: String) -> Decimal { Decimal(string: s.replacingOccurrences(of: ",", with: "")) ?? 0 }
}

// MARK: - Wallet

@MainActor
final class Wallet: ObservableObject {
    @Published var profile: Profile
    @Published var balance: Decimal
    @Published var txns: [Txn]
    @Published var people: [Person]
    @Published var family: [FamilyMember]
    @Published var card: CashCard
    @Published var holdings: [Holding]
    @Published var goals: [Goal]
    @Published var budgets: [Budget]
    @Published var notes: [Note]
    @Published var settings: Settings

    @Published var quotes: [String: Quote] = [:]
    @Published var market: Load = .idle
    @Published var lastPull: Date?

    private let svc = MarketService.shared
    private var bag = Set<AnyCancellable>()

    init() {
        let b = Seed.bag()
        if let s = Disk.load() {
            profile = s.profile; balance = s.balance; txns = s.txns
            people = s; family = s.family; card = s.card; holdings = s.holdings
            goals = s.goals; budgets = s.budgets; notes = s.notes; settings = s.settings
        } else {
            profile = b.profile; balance = b.balance; txns = b.txns; people = b.people
            family = b.family; card = b.card; holdings = b.holdings; goals = b.goals
            budgets = b.budgets; notes = b.notes; settings = Settings()
        }
        quotes = Seed.fallback()
        objectWillChange
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.persist() }
            .store(in: &bag)
    }

    private func persist() {
        Disk.save(Snapshot(profile: profile, balance: balance, txns: txns,
            people: people, family: family, card: card, holdings: holdings,
            goals: goals, budgets: budgets, notes: notes, settings: settings))
    }

    func send(to person: Person, amount: Decimal, note: String = "") {
        guard amount > 0, balance >= amount else { return }
        balance -= amount
        txns.insert(Txn(kind: .sent, title: person.name, subtitle: note.isEmpty ? "Demo payment" : note,
            amount: -amount, note: note, person: person.name), at: 0)
    }

    func request(from person: Person, amount: Decimal, note: String = "") {
        guard amount > 0 else { return }
        txns.insert(Txn(kind: .request, title: person.name, subtitle: note.isEmpty ? "Payment requested" : note,
            amount: amount, note: note, person: person.name, pending: true), at: 0)
    }

    func deposit(_ amount: Decimal) {
        guard amount > 0 else { return }
        balance += amount
        txns.insert(Txn(kind: .deposit, title: "Added money", subtitle: "Demo balance", amount: amount), at: 0)
    }

    func withdraw(_ amount: Decimal) {
        guard amount > 0, balance >= amount else { return }
        balance -= amount
        txns.insert(Txn(kind: .withdrawal, title: "Withdrawal", subtitle: "Demo transfer", amount: -amount), at: 0)
    }

    func contribute(to goalID: UUID, amount: Decimal) {
        guard amount > 0, balance >= amount, let i = goals.firstIndex(where: { $0.id == goalID }) else { return }
        balance -= amount
        goals[i].saved += amount
    }

    func resetDemo() {
        Disk.wipe()
        let b = Seed.bag()
        profile = b.profile; balance = b.balance; txns = b.txns; people = b.people
        family = b.family; card = b.card; holdings = b.holdings; goals = b.goals
        budgets = b.budgets; notes = b.notes; settings = Settings()
        quotes = Seed.fallback()
    }

    func pull() async {
        market = .loading
        quotes = Seed.fallback()
        lastPull = Date()
        market = .loaded
    }
}
