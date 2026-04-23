import XCTest
import SwiftData
@testable import faster

@MainActor
final class FastingControllerTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var controller: FastingController!

    override func setUpWithError() throws {
        container = ModelContainerFactory.make(inMemory: true)
        context = container.mainContext
        controller = FastingController(
            context: context,
            scheduler: NotificationScheduler(),
            healthStore: HealthStore()
        )
    }

    func testStartAndEndFast() throws {
        let plan = FastingPlan(protocolKind: .sixteenEight, eatingWindowStartMinutes: 12 * 60)
        context.insert(plan)
        let session = try controller.startFast(plan: plan, at: Date().addingTimeInterval(-15 * 3600))
        XCTAssertTrue(session.isActive)

        let expectation = expectation(description: "ended")
        Task {
            try await controller.endFast(session, reason: .completed)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
        XCTAssertNotNil(session.actualEnd)
    }

    func testCannotStartWhileActive() throws {
        let plan = FastingPlan()
        context.insert(plan)
        _ = try controller.startFast(plan: plan)
        XCTAssertThrowsError(try controller.startFast(plan: plan)) { error in
            XCTAssertEqual(error as? FastingError, .alreadyActive)
        }
    }

    func testAdjustStartRejectsFutureTime() throws {
        let plan = FastingPlan()
        context.insert(plan)
        let session = try controller.startFast(plan: plan)
        let future = Date().addingTimeInterval(3600)
        XCTAssertThrowsError(try controller.adjustStart(session, to: future))
    }

    func testAdjustStartRejectsBeyond48h() throws {
        let plan = FastingPlan()
        context.insert(plan)
        let session = try controller.startFast(plan: plan)
        let tooOld = Date().addingTimeInterval(-72 * 3600)
        XCTAssertThrowsError(try controller.adjustStart(session, to: tooOld))
    }
}

extension FastingError: Equatable {
    public static func == (lhs: FastingError, rhs: FastingError) -> Bool {
        lhs.localizedDescription == rhs.localizedDescription
    }
}
