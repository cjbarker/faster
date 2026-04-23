import XCTest
@testable import faster

final class GuidanceResolverTests: XCTestCase {
    private let content = GuidanceContent(
        cards: [
            GuidanceCard(id: "a", phase: .anabolic,          title: "a", body: "",   hourMin: 0,  hourMax: 4,  tags: [],             ctaType: nil),
            GuidanceCard(id: "b", phase: .earlyFast,         title: "b", body: "",   hourMin: 4,  hourMax: 12, tags: [],             ctaType: nil),
            GuidanceCard(id: "c", phase: .glycogenDepletion, title: "c", body: "",   hourMin: 12, hourMax: 16, tags: ["electrolytes"], ctaType: nil),
            GuidanceCard(id: "d", phase: .fatBurning,        title: "d", body: "",   hourMin: 16, hourMax: 24, tags: ["break-fast"], ctaType: nil)
        ],
        allowed: [
            AllowedConsumable(id: "water", name: "Water", verdict: .allowed, notes: "", category: "water"),
            AllowedConsumable(id: "juice", name: "Juice", verdict: .breaksFast, notes: "", category: "sugar")
        ]
    )

    func testCurrentMatchesPhaseAndHour() {
        let r = GuidanceResolver(content: content)
        let ctx = GuidanceContext(phase: .earlyFast, hoursElapsed: 6, isFasting: true, minutesUntilBreakFast: 600)
        XCTAssertEqual(r.current(for: ctx)?.id, "b")
    }

    func testUpcomingOrderedAndFiltered() {
        let r = GuidanceResolver(content: content)
        let ctx = GuidanceContext(phase: .earlyFast, hoursElapsed: 6, isFasting: true, minutesUntilBreakFast: 600)
        let up = r.upcoming(for: ctx, limit: 3).map(\.id)
        XCTAssertEqual(up.first, "c")  // next phase card
    }

    func testAllowedFiltering() {
        let r = GuidanceResolver(content: content)
        XCTAssertEqual(r.allowed(category: "water").count, 1)
        XCTAssertEqual(r.allowed().count, 2)
    }

    func testBreakFastCards() {
        let r = GuidanceResolver(content: content)
        XCTAssertEqual(r.breakFastCards().first?.id, "d")
    }
}
