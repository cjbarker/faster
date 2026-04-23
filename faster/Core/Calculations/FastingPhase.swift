import Foundation

public enum FastingPhase: String, CaseIterable, Codable, Sendable {
    case anabolic          // 0–4h
    case earlyFast         // 4–12h
    case glycogenDepletion // 12–16h
    case fatBurning        // 16–24h
    case deepKetosis       // 24h+

    public var title: String {
        switch self {
        case .anabolic:          return "Anabolic"
        case .earlyFast:         return "Early Fast"
        case .glycogenDepletion: return "Glycogen Depletion"
        case .fatBurning:        return "Fat Burning"
        case .deepKetosis:       return "Deep Ketosis"
        }
    }

    public var tagline: String {
        switch self {
        case .anabolic:          return "Digesting your last meal — insulin is elevated."
        case .earlyFast:         return "Insulin is falling; your body is finishing digestion."
        case .glycogenDepletion: return "Liver glycogen is running low; fat burning is ramping up."
        case .fatBurning:        return "You're burning body fat and producing ketones."
        case .deepKetosis:       return "Deep ketosis — autophagy is active."
        }
    }

    public static func phase(forHoursElapsed hours: Double) -> FastingPhase {
        switch hours {
        case ..<4:          return .anabolic
        case ..<12:         return .earlyFast
        case ..<16:         return .glycogenDepletion
        case ..<24:         return .fatBurning
        default:            return .deepKetosis
        }
    }
}
