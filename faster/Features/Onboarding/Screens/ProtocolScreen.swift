import SwiftUI

struct ProtocolScreen: View {
    @Bindable var state: OnboardingState

    var body: some View {
        Form {
            Section("Choose a protocol") {
                ForEach(ProtocolKind.allCases, id: \.self) { kind in
                    Button {
                        state.protocolKind = kind
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(kind.rawValue).font(AppFont.headline)
                                Text(describe(kind)).font(AppFont.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if state.protocolKind == kind {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(AppColor.accent)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(kind.requiresExperience && !state.hasFastingExperience)
                }
            }
            if state.requiresExperience && !state.hasFastingExperience {
                Section {
                    Text("Longer protocols are unlocked once you've done shorter fasts first.")
                        .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle("Fasting protocol")
        .toolbar { OnboardingToolbar(state: state) }
    }

    private func describe(_ kind: ProtocolKind) -> String {
        "Fast \(kind.fastingHours)h, eat \(kind.eatingHours)h per day."
    }
}
