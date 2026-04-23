import SwiftUI

struct AllowedConsumablesView: View {
    var items: [AllowedConsumable]

    var body: some View {
        List {
            ForEach(sections, id: \.self) { verdict in
                Section(header: Text(sectionTitle(verdict))) {
                    ForEach(items.filter { $0.verdict == verdict }) { item in
                        ConsumableRow(item: item)
                    }
                }
            }
            Section {
                Text("When in doubt, plain water is always safe. If a food or drink has calories or protein, treat it as breaking your fast.")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("What's allowed")
    }

    private var sections: [AllowedConsumable.Verdict] {
        [.allowed, .cautious, .breaksFast]
    }
    private func sectionTitle(_ v: AllowedConsumable.Verdict) -> String {
        switch v {
        case .allowed:    return "Allowed during the fast"
        case .cautious:   return "Probably okay — use judgment"
        case .breaksFast: return "Breaks the fast"
        }
    }
}

private struct ConsumableRow: View {
    var item: AllowedConsumable
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(color)
                .frame(width: 22)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name).font(AppFont.headline)
                Text(item.notes).font(AppFont.caption).foregroundStyle(.secondary)
            }
        }
    }
    private var symbol: String {
        switch item.verdict {
        case .allowed:    return "checkmark.circle.fill"
        case .cautious:   return "exclamationmark.triangle.fill"
        case .breaksFast: return "xmark.octagon.fill"
        }
    }
    private var color: Color {
        switch item.verdict {
        case .allowed:    return AppColor.accent
        case .cautious:   return .orange
        case .breaksFast: return AppColor.destructive
        }
    }
}
