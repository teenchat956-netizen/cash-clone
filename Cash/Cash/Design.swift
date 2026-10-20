import SwiftUI

enum Ink {
    static let black      = Color(hex: 0x000000)
    static let headerTop  = Color(hex: 0x000000)
    static let headerEnd  = Color(hex: 0x1C1C1E)
    static let sheet      = Color(hex: 0xF2F2F2)
    static let card       = Color.white
    static let green      = Color(hex: 0x00D632)
    static let greenDeep  = Color(hex: 0x00A828)
    static let dim        = Color(hex: 0x8E8E93)
    static let hairline   = Color(hex: 0xE3E3E5)
    static let ghost      = Color(hex: 0x1C1C1E)

    static let sheetRadius: CGFloat = 28
    static let cardRadius: CGFloat = 22
    static let tileRadius: CGFloat = 20
    static let gutter: CGFloat = 18
}

enum T {
    static func black(_ s: CGFloat) -> Font { .custom("Manrope-ExtraBold", size: s) }
    static func heavy(_ s: CGFloat) -> Font { .custom("Manrope-Bold", size: s) }
    static func semi(_ s: CGFloat) -> Font  { .custom("Manrope-SemiBold", size: s) }
    static func med(_ s: CGFloat) -> Font   { .custom("Manrope-Medium", size: s) }
    static func reg(_ s: CGFloat) -> Font   { .custom("Manrope-Regular", size: s) }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255, opacity: 1)
    }
    init?(hexString: String) {
        var s = hexString.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        self.init(hex: v)
    }
}

enum Buzz {
    static var on: Bool { UserDefaults.standard.object(forKey: "cash.haptics") as? Bool ?? true }
    static func tap() { guard on else { return }; UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func thud() { guard on else { return }; UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func ok() { guard on else { return }; UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func bad() { guard on else { return }; UINotificationFeedbackGenerator().notificationOccurred(.error) }
}

struct Sheet<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView(showsIndicators: false) {
            content.padding(.bottom, 130)
        }
        .background(Ink.sheet)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: Ink.sheetRadius,
                                          topTrailingRadius: Ink.sheetRadius,
                                          bottomLeadingRadius: 0,
                                          bottomTrailingRadius: 0))
    }
}

struct WhiteTile<Content: View>: View {
    var radius: CGFloat = Ink.tileRadius
    var padding: CGFloat = 16
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Ink.card, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

struct GhostPill: View {
    let title: String
    var icon: String? = nil
    var action: () -> Void
    var body: some View {
        Button { Buzz.tap(); action() } label: {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon).font(.system(size: 13, weight: .bold)) }
                Text(title).font(T.semi(15))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Ink.card, in: Capsule())
            .foregroundStyle(Ink.black)
        }
        .buttonStyle(.plain)
    }
}

struct BlackPill: View {
    let title: String
    var enabled = true
    var action: () -> Void
    var body: some View {
        Button { Buzz.thud(); action() } label: {
            Text(title)
                .font(T.heavy(17))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(Ink.black, in: Capsule())
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .opacity(enabled ? 1 : 0.35)
        .disabled(!enabled)
    }
}

struct GhostDarkPill: View {
    let title: String
    var action: () -> Void
    var body: some View {
        Button { Buzz.tap(); action() } label: {
            Text(title)
                .font(T.heavy(16))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Ink.black.opacity(0.16), in: Capsule())
                .foregroundStyle(Ink.black)
        }
        .buttonStyle(.plain)
    }
}

struct Monogram: View {
    let text: String
    var color: Color
    var size: CGFloat = 44
    var body: some View {
        Circle().fill(color)
            .frame(width: size, height: size)
            .overlay(Text(text).font(T.heavy(size * 0.36)).foregroundStyle(.white))
    }
}

struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(T.black(21))
            .foregroundStyle(Ink.black)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct Hairline: View {
    var body: some View { Rectangle().fill(Ink.hairline).frame(height: 1) }
}

struct IconTile: View {
    let icon: String
    let label: String
    var tint: Color = Ink.black
    var action: () -> Void
    var body: some View {
        Button { Buzz.tap(); action() } label: {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    Circle().fill(tint.opacity(0.10)).frame(width: 42, height: 42)
                    Image(systemName: icon).font(.system(size: 17, weight: .bold)).foregroundStyle(tint)
                }
                Text(label)
                    .font(T.heavy(15))
                    .foregroundStyle(Ink.black)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Ink.card, in: RoundedRectangle(cornerRadius: Ink.tileRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct Keypad: View {
    @Binding var text: String
    var maxDecimals = 2
    var onDark = false
    private let keys = ["1","2","3","4","5","6","7","8","9",".","0","⌫"]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 2) {
            ForEach(keys, id: \.self) { key in
                Button { Buzz.tap(); press(key) } label: {
                    Text(key)
                        .font(T.heavy(28))
                        .foregroundStyle(onDark ? Ink.black : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 62)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func press(_ key: String) {
        switch key {
        case "⌫": if !text.isEmpty { text.removeLast() }
        case ".":
            guard !text.contains(".") else { return }
            text = text.isEmpty ? "0." : text + "."
        default:
            if let d = text.firstIndex(of: "."),
               text.distance(from: text.index(after: d), to: text.endIndex) >= maxDecimals { return }
            text = (text == "0") ? key : text + key
        }
    }
}

struct EmptyBlock: View {
    let icon: String
    let title: String
    let body_: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 28, weight: .light)).foregroundStyle(Ink.dim)
            Text(title).font(T.heavy(16)).foregroundStyle(Ink.black)
            Text(body_).font(T.reg(14)).foregroundStyle(Ink.dim).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
}
