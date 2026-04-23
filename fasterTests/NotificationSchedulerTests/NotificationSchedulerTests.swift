import XCTest
import UserNotifications
@testable import faster

final class NotificationSchedulerTests: XCTestCase {
    func testRebuildDoesNotExceedCap() async {
        let scheduler = NotificationScheduler()
        let now = Date()
        let start = now
        let end = now.addingTimeInterval(20 * 3600)
        await scheduler.rebuild(for: .fasting(start: start, end: end), plan: PlanPrefs(), now: now)
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        XCTAssertLessThanOrEqual(pending.count, 64, "Must not exceed system cap")
    }
}
