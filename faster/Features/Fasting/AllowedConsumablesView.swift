import SwiftUI

struct AllowedConsumablesView: View {
    var items: [AllowedConsumable]

    private var sections: [AllowedConsumable.Verdict] { [.allowed, .cautious, .breaksFast] }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                ForEach(sections, id: \.self) { verdict in
                    let group = items.filter { $0.verdict == verdict }
                    if !group.isEmpty {
                        VerdictSection(verdict: verdict, items: group)
                    }
                }

                Text("When in doubt, plain water is always safe. If a food or drink has calories or protein, treat it as breaking your fast.")
                    .font(AppFont.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.horizontal)
            .padding(.vertical, Spacing.md)
        }
        .navigationTitle("What's Allowed")
    }
}

private struct VerdictSection: View {
    var verdict: AllowedConsumable.Verdict
    var items: [AllowedConsumable]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: headerSymbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(headerColor)
                Text(sectionTitle)
                    .font(AppFont.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(headerColor)
            }
            .padding(.horizontal, Spacing.sm)

            VStack(spacing: Spacing.xs) {
                ForEach(items) { item in
                    ConsumableRow(item: item)
                }
            }
        }
    }

    private var sectionTitle: String {
        switch verdict {
        case .allowed:    return "Allowed during the fast"
        case .cautious:   return "Use judgment"
        case .breaksFast: return "Breaks the fast"
        }
    }

    private var headerSymbol: String {
        switch verdict {
        case .allowed:    return "checkmark.circle.fill"
        case .cautious:   return "exclamationmark.triangle.fill"
        case .breaksFast: return "xmark.octagon.fill"
        }
    }

    private var headerColor: Color {
        switch verdict {
        case .allowed:    return AppColor.accent
        case .cautious:   return .orange
        case .breaksFast: return AppColor.destructive
        }
    }
}

private struct ConsumableRow: View {
    var item: AllowedConsumable

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 24, height: 24)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(AppFont.callout)
                    .fontWeight(.medium)
                Text(item.notes)
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(AppColor.secondaryBackground,
                    in: RoundedRectangle(cornerRadius: CR.md, style: .continuous))
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
