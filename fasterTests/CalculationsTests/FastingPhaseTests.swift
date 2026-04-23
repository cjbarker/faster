import XCTest
@testable import faster

final class FastingPhaseTests: XCTestCase {
    func testBoundaries() {
        XCTAssertEqual(FastingPhase.phase(forHoursElapsed: 0),    .anabolic)
        XCTAssertEqual(FastingPhase.phase(forHoursElapsed: 3.9),  .anabolic)
        XCTAssertEqual(FastingPhase.phase(forHoursElapsed: 4.0),  .earlyFast)
        XCTAssertEqual(FastingPhase.phase(forHoursElapsed: 11.99),.earlyFast)
        XCTAssertEqual(FastingPhase.phase(forHoursElapsed: 12.0), .glycogenDepletion)
        XCTAssertEqual(FastingPhase.phase(forHoursElapsed: 15.99),.glycogenDepletion)
        XCTAssertEqual(FastingPhase.phase(forHoursElapsed: 16.0), .fatBurning)
        XCTAssertEqual(FastingPhase.phase(forHoursElapsed: 23.99),.fatBurning)
        XCTAssertEqual(FastingPhase.phase(forHoursElapsed: 24.0), .deepKetosis)
        XCTAssertEqual(FastingPhase.phase(forHoursElapsed: 72.0), .deepKetosis)
    }
    func testHydrationElectrolyteThreshold() {
        XCTAssertFalse(Hydration.shouldRecommendElectrolytes(hoursElapsed: 11))
        XCTAssertTrue(Hydration.shouldRecommendElectrolytes(hoursElapsed: 12))
    }
}
