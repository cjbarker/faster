import SwiftUI

// MARK: - Colors

enum AppColor {
    // Primary accent — vibrant teal-mint
    static let accent       = Color(red: 0.18, green: 0.78, blue: 0.68)

    // Ring tints
    static let fastingRing  = Color(red: 0.42, green: 0.62, blue: 0.98)
    static let eatingRing   = Color(red: 1.00, green: 0.68, blue: 0.28)

    // Semantic
    static let success      = Color(red: 0.18, green: 0.78, blue: 0.45)
    static let warning      = Color.orange
    static let destructive  = Color.red

    // Surfaces
    static let background           = Color(.systemBackground)
    static let secondaryBackground  = Color(.secondarySystemBackground)
    static let tertiaryBackground   = Color(.tertiarySystemBackground)

    // Gradients
    static var fastingGradient: LinearGradient {
        LinearGradient(colors: [fastingRing, accent],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var eatingGradient: LinearGradient {
        LinearGradient(colors: [eatingRing, Color(red: 0.98, green: 0.50, blue: 0.18)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var accentGradient: LinearGradient {
        LinearGradient(colors: [accent, fastingRing],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Spacing tokens

enum Spacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner-radius tokens

enum CR {
    static let sm: CGFloat = 10
    static let md: CGFloat = 16
    static let lg: CGFloat = 22
}

// MARK: - Convenience view modifiers

extension View {
    func cardStyle(padding: CGFloat = Spacing.md) -> some View {
        self
            .padding(padding)
            .background(AppColor.secondaryBackground,
                        in: RoundedRectangle(cornerRadius: CR.md, style: .continuous))
    }

    func elevatedCardStyle(padding: CGFloat = Spacing.md) -> some View {
        self
            .padding(padding)
            .background(AppColor.background,
                        in: RoundedRectangle(cornerRadius: CR.md, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
    }
}

// MARK: - FastEndReason design helpers

extension FastEndReason {
    var displayTitle: String {
        switch self {
        case .completed:  return "Completed"
        case .endedEarly: return "Ended early"
        case .missed:     return "Missed"
        case .adjusted:   return "Adjusted"
        }
    }

    var badgeColor: Color {
        switch self {
        case .completed:  return AppColor.accent
        case .endedEarly: return .orange
        case .missed:     return .secondary
        case .adjusted:   return AppColor.fastingRing
        }
    }
}

// MARK: - FastingPhase design helpers

extension FastingPhase {
    var symbolName: String {
        switch self {
        case .anabolic:          return "fork.knife"
        case .earlyFast:         return "clock"
        case .glycogenDepletion: return "flame"
        case .fatBurning:        return "flame.fill"
        case .deepKetosis:       return "sparkles"
        }
    }

    var phaseColor: Color {
        switch self {
        case .anabolic:          return AppColor.eatingRing
        case .earlyFast:         return .orange
        case .glycogenDepletion: return AppColor.fastingRing.opacity(0.85)
        case .fatBurning:        return AppColor.fastingRing
        case .deepKetosis:       return AppColor.accent
        }
    }
}
