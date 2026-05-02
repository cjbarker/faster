import SwiftUI

struct ProtocolScreen: View {
    @Bindable var state: OnboardingState

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.sm) {
                Text("Choose a fasting protocol")
                    .font(AppFont.title3)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, Spacing.md)

                ForEach(ProtocolKind.allCases, id: \.self) { kind in
                    ProtocolCard(
                        kind: kind,
                        isSelected: state.protocolKind == kind,
                        isLocked: kind.requiresExperience && !state.hasFastingExperience
                    ) {
                        if !(kind.requiresExperience && !state.hasFastingExperience) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                state.protocolKind = kind
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                if state.requiresExperience && !state.hasFastingExperience {
                    Label("Longer protocols unlock after you've completed shorter fasts first.", systemImage: "lock.fill")
                        .font(AppFont.caption)
                        .foregroundStyle(.orange)
                        .padding(.horizontal)
                        .padding(.top, Spacing.xs)
                }
            }
            .padding(.bottom, 100)
        }
        .navigationTitle("Fasting Protocol")
        .toolbar { OnboardingToolbar(state: state) }
    }
}

private struct ProtocolCard: View {
    var kind: ProtocolKind
    var isSelected: Bool
    var isLocked: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppColor.accent.opacity(0.12) : AppColor.secondaryBackground)
                        .frame(width: 48, height: 48)
                    Text(kind.rawValue)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? AppColor.accent : .secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(kind.rawValue)
                        .font(AppFont.headline)
                        .foregroundStyle(isLocked ? Color.secondary : Color.primary)
                    Text("Fast \(kind.fastingHours)h, eat \(kind.eatingHours)h per day.")
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.tertiary)
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AppColor.accent)
                        .symbolRenderingMode(.hierarchical)
                }
            }
            .padding(Spacing.md)
            .background(
                isSelected ? AppColor.accent.opacity(0.06) : AppColor.secondaryBackground,
                in: RoundedRectangle(cornerRadius: CR.md, style: .continuous)
            )
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: CR.md, style: .continuous)
                        .strokeBorder(AppColor.accent.opacity(0.3), lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
        .opacity(isLocked ? 0.5 : 1.0)
    }
}
