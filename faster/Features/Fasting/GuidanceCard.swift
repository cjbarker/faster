import Foundation

public struct GuidanceCard: Codable, Identifiable, Hashable, Sendable {
    public var id: String
    public var phase: FastingPhase
    public var title: String
    public var body: String
    public var hourMin: Int?        // earliest hours into fast this applies
    public var hourMax: Int?        // latest hours into fast this applies
    public var tags: [String]       // e.g., ["hydration"], ["break-fast"], ["avoid"]
    public var ctaType: String?     // "log_water", "start_fast", "end_fast"
}

public struct AllowedConsumable: Codable, Identifiable, Hashable, Sendable {
    public enum Verdict: String, Codable, Sendable {
        case allowed        // will not break fast
        case cautious       // may affect fast depending on strictness
        case breaksFast     // breaks the fast
    }
    public var id: String
    public var name: String
    public var verdict: Verdict
    public var notes: String
    public var category: String     // "water", "caffeine", "electrolytes", "zero-calorie", "dairy", "solid", ...
}

public struct GuidanceContent: Codable, Sendable {
    public var cards: [GuidanceCard]
    public var allowed: [AllowedConsumable]
}

public protocol GuidanceProvider: Sendable {
    func load() throws -> GuidanceContent
}

public struct BundleGuidanceProvider: GuidanceProvider {
    public init() {}
    public func load() throws -> GuidanceContent {
        guard let url = Bundle.main.url(forResource: "guidance", withExtension: "json") else {
            throw NSError(domain: "faster", code: 404, userInfo: [NSLocalizedDescriptionKey: "guidance.json not found in bundle"])
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(GuidanceContent.self, from: data)
    }
}
