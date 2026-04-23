import Foundation

public struct GuidanceContext: Sendable, Equatable {
    public var phase: FastingPhase
    public var hoursElapsed: Double
    public var isFasting: Bool
    public var minutesUntilBreakFast: Int?

    public init(phase: FastingPhase, hoursElapsed: Double, isFasting: Bool, minutesUntilBreakFast: Int?) {
        self.phase = phase
        self.hoursElapsed = hoursElapsed
        self.isFasting = isFasting
        self.minutesUntilBreakFast = minutesUntilBreakFast
    }
}

public struct GuidanceResolver: Sendable {
    public var content: GuidanceContent

    public init(content: GuidanceContent) {
        self.content = content
    }

    /// Returns the best guidance card for the current context, plus up to `upcoming` future cards.
    public func current(for ctx: GuidanceContext) -> GuidanceCard? {
        candidates(for: ctx).first
    }

    public func upcoming(for ctx: GuidanceContext, limit: Int = 3) -> [GuidanceCard] {
        // Look at higher hours that are close to current.
        let hour = ctx.hoursElapsed
        return content.cards
            .filter { $0.phase == ctx.phase || nextPhase(after: ctx.phase) == $0.phase }
            .filter { ($0.hourMin.map { Double($0) > hour } ?? false) }
            .sorted { ($0.hourMin ?? 0) < ($1.hourMin ?? 0) }
            .prefix(limit)
            .map { $0 }
    }

    public func breakFastCards() -> [GuidanceCard] {
        content.cards.filter { $0.tags.contains("break-fast") }
    }

    public func allowed(category: String? = nil) -> [AllowedConsumable] {
        guard let category else { return content.allowed }
        return content.allowed.filter { $0.category == category }
    }

    private func candidates(for ctx: GuidanceContext) -> [GuidanceCard] {
        let hour = ctx.hoursElapsed
        return content.cards
            .filter { $0.phase == ctx.phase }
            .filter { card in
                let lo = Double(card.hourMin ?? 0)
                let hi = Double(card.hourMax ?? Int.max / 2)
                return hour >= lo && hour < hi
            }
            .sorted { ($0.hourMin ?? 0) > ($1.hourMin ?? 0) }
    }

    private func nextPhase(after p: FastingPhase) -> FastingPhase {
        switch p {
        case .anabolic:          return .earlyFast
        case .earlyFast:         return .glycogenDepletion
        case .glycogenDepletion: return .fatBurning
        case .fatBurning:        return .deepKetosis
        case .deepKetosis:       return .deepKetosis
        }
    }
}
