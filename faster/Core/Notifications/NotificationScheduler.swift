import Foundation
import UserNotifications

actor NotificationScheduler {
    private let center = UNUserNotificationCenter.current()
    private let maxPending = 60  // System cap is 64; keep headroom.

    func registerCategories() async {
        let categories: Set<UNNotificationCategory> = Set(
            FasterNotificationCategory.allCases.map { cat in
                UNNotificationCategory(
                    identifier: cat.identifier,
                    actions: cat.actions,
                    intentIdentifiers: [],
                    options: [.customDismissAction]
                )
            }
        )
        center.setNotificationCategories(categories)
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge, .provisional])
            return granted
        } catch {
            return false
        }
    }

    /// Cancel all pending and rebuild from the current fasting state and plan.
    func rebuild(for state: FastingState, plan: PlanPrefs, now: Date = Date()) async {
        center.removeAllPendingNotificationRequests()
        var requests: [UNNotificationRequest] = []

        switch state {
        case .fasting(let start, let end):
            // Pre-break warning
            if let t = end.addingTimeInterval(-30 * 60).futureOnly(after: now) {
                requests.append(make(.preBreakFastWarning, title: "Break-fast coming up", body: "30 minutes until your eating window opens.", at: t, category: .fastActive))
            }
            // Break-fast opens
            if let t = end.futureOnly(after: now) {
                requests.append(make(.fastEnd, title: "Eating window open", body: "Break your fast gently — start small.", at: t, category: .eatingActive))
            }
            // Electrolyte reminder at 12h into the fast
            if plan.electrolyteRemindersEnabled {
                let electroTime = start.addingTimeInterval(12 * 3600)
                if let t = electroTime.futureOnly(after: now), t < end {
                    requests.append(make(.electrolyteReminder, title: "Consider electrolytes", body: "12 hours in — a pinch of salt or an electrolyte drink can help.", at: t, category: .fastActive))
                }
            }
            // Hydration nudges every 2 hours during the fast (up to cap)
            if plan.hydrationNudgesEnabled {
                var t = max(start, now).addingTimeInterval(2 * 3600)
                var count = 0
                while t < end && count < 10 {
                    requests.append(make(.hydrationNudge, title: "Hydration check", body: "A glass of water goes a long way.", at: t, category: .fastActive))
                    t = t.addingTimeInterval(2 * 3600)
                    count += 1
                }
            }

        case .eating(let windowStart, let windowEnd):
            if let t = windowStart.futureOnly(after: now) {
                requests.append(make(.fastStart, title: "Eating window open", body: "Enjoy your meal mindfully.", at: t, category: .eatingActive))
            }
            if let t = windowEnd.addingTimeInterval(-30 * 60).futureOnly(after: now) {
                requests.append(make(.eatingWindowClosing, title: "Eating window closing", body: "30 minutes until your next fast begins.", at: t, category: .eatingActive))
            }
            if let t = windowEnd.futureOnly(after: now) {
                requests.append(make(.fastStart, title: "Fast started", body: "You got this. Hydrate and stay busy.", at: t, category: .fastActive))
            }

        case .none:
            break
        }

        // Daily weigh-in (7am local)
        if plan.dailyWeighInEnabled {
            var comps = DateComponents()
            comps.hour = 7
            comps.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let content = UNMutableNotificationContent()
            content.title = "Morning check-in"
            content.body = "Log today's weight to keep your trend up to date."
            content.sound = .default
            content.categoryIdentifier = FasterNotificationCategory.eatingActive.identifier
            let req = UNNotificationRequest(
                identifier: "\(FasterNotificationType.dailyWeighIn.rawValue).daily",
                content: content,
                trigger: trigger
            )
            requests.append(req)
        }

        // Enforce pending cap deterministically (keep soonest N).
        let capped = Array(requests.prefix(maxPending))
        for request in capped {
            try? await center.add(request)
        }
    }

    func cancelAll() async {
        center.removeAllPendingNotificationRequests()
    }

    private func make(_ type: FasterNotificationType,
                      title: String,
                      body: String,
                      at date: Date,
                      category: FasterNotificationCategory) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = category.identifier
        content.userInfo = ["type": type.rawValue]
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        return UNNotificationRequest(
            identifier: "\(type.rawValue).\(date.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
    }
}

enum FastingState: Sendable, Equatable {
    case none
    case fasting(start: Date, end: Date)
    case eating(windowStart: Date, windowEnd: Date)
}

struct PlanPrefs: Sendable, Equatable {
    var hydrationNudgesEnabled: Bool = true
    var electrolyteRemindersEnabled: Bool = true
    var dailyWeighInEnabled: Bool = true
}

private extension Date {
    func futureOnly(after now: Date) -> Date? {
        self > now ? self : nil
    }
}
