import Foundation
import UserNotifications

enum FasterNotificationType: String, CaseIterable, Sendable {
    case fastStart              = "fast.start"
    case preBreakFastWarning    = "fast.prebreak"          // 30 min pre-break
    case fastEnd                = "fast.end"
    case hydrationNudge         = "hydration.nudge"
    case electrolyteReminder    = "hydration.electrolyte"
    case eatingWindowClosing    = "eating.closing"
    case dailyWeighIn           = "daily.weighin"
}

enum FasterNotificationCategory: String, CaseIterable {
    case fastActive = "category.fast.active"
    case eatingActive = "category.eating.active"

    var identifier: String { rawValue }

    var actions: [UNNotificationAction] {
        switch self {
        case .fastActive:
            return [
                UNNotificationAction(identifier: "ACTION_LOG_WATER", title: "Log Water", options: []),
                UNNotificationAction(identifier: "ACTION_END_FAST",  title: "End Fast",  options: [.destructive])
            ]
        case .eatingActive:
            return [
                UNNotificationAction(identifier: "ACTION_START_FAST", title: "Start Fast", options: [])
            ]
        }
    }
}
