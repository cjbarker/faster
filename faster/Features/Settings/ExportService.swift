import Foundation
import SwiftData

@MainActor
final class ExportService {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func exportJSON() throws -> URL {
        let data = try encodeJSON()
        return try writeTemp(data: data, suffix: "faster-export.json")
    }

    func exportCSV() throws -> URL {
        let csv = try encodeCSV()
        return try writeTemp(data: Data(csv.utf8), suffix: "faster-export.csv")
    }

    private func encodeJSON() throws -> Data {
        let context = container.mainContext
        let fasts = try context.fetch(FetchDescriptor<FastSession>())
        let weights = try context.fetch(FetchDescriptor<WeightEntry>())
        let waters = try context.fetch(FetchDescriptor<WaterEntry>())

        let payload = ExportPayload(
            fasts: fasts.map { ExportFast(from: $0) },
            weights: weights.map { ExportWeight(from: $0) },
            waters: waters.map { ExportWater(from: $0) }
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }

    private func encodeCSV() throws -> String {
        let context = container.mainContext
        let fasts = try context.fetch(FetchDescriptor<FastSession>())
        var out = "type,started,ended,kind,duration_hours,completion,mood,energy\n"
        for f in fasts {
            let duration = f.durationSeconds / 3600
            out += "fast,\(iso(f.actualStart)),\(f.actualEnd.map(iso) ?? ""),\(f.protocolKind.rawValue),\(String(format: "%.2f", duration)),\(String(format: "%.2f", f.completionRatio)),\(f.moodAtBreakFast.map(String.init) ?? ""),\(f.energyAtBreakFast.map(String.init) ?? "")\n"
        }
        return out
    }

    private func writeTemp(data: Data, suffix: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(suffix)
        try data.write(to: url, options: .atomic)
        return url
    }

    private func iso(_ d: Date) -> String {
        ISO8601DateFormatter().string(from: d)
    }
}

private struct ExportPayload: Codable {
    var fasts: [ExportFast]
    var weights: [ExportWeight]
    var waters: [ExportWater]
}

private struct ExportFast: Codable {
    var id: String
    var protocolKind: String
    var actualStart: Date
    var actualEnd: Date?
    var completionRatio: Double
    var mood: Int?
    var energy: Int?

    init(from s: FastSession) {
        self.id = s.id.uuidString
        self.protocolKind = s.protocolKind.rawValue
        self.actualStart = s.actualStart
        self.actualEnd = s.actualEnd
        self.completionRatio = s.completionRatio
        self.mood = s.moodAtBreakFast
        self.energy = s.energyAtBreakFast
    }
}

private struct ExportWeight: Codable {
    var date: Date
    var weightKg: Double
    var source: String
    init(from w: WeightEntry) {
        date = w.date
        weightKg = w.weightKg
        source = w.source.rawValue
    }
}

private struct ExportWater: Codable {
    var date: Date
    var volumeMl: Double
    var source: String
    init(from w: WaterEntry) {
        date = w.date
        volumeMl = w.volumeMl
        source = w.source.rawValue
    }
}
