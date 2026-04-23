import Foundation
#if canImport(ActivityKit)
import ActivityKit

public struct FastingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var start: Date
        public var end: Date
        public var phaseTitle: String

        public init(start: Date, end: Date, phaseTitle: String) {
            self.start = start
            self.end = end
            self.phaseTitle = phaseTitle
        }
    }

    public var protocolLabel: String

    public init(protocolLabel: String) {
        self.protocolLabel = protocolLabel
    }
}
#endif
