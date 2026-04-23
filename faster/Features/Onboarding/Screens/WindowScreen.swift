import SwiftUI

struct WindowScreen: View {
    @Bindable var state: OnboardingState

    var body: some View {
        Form {
            Section("Eating window start") {
                DatePicker(
                    "Window opens at",
                    selection: Binding(
                        get: { timeFromMinutes(state.eatingWindowStartMinutes) },
                        set: { state.eatingWindowStartMinutes = minutesFromTime($0) }
                    ),
                    displayedComponents: .hourAndMinute
                )
                HStack {
                    Text("Window closes at")
                    Spacer()
                    Text(windowEndLabel).foregroundStyle(.secondary)
                }
            }
            Section {
                Text("Your eating window is \(state.protocolKind.eatingHours) hours long. We'll start your fast automatically when the window closes.")
                    .foregroundStyle(.secondary)
                    .font(AppFont.caption)
            }
        }
        .navigationTitle("Eating window")
        .toolbar { OnboardingToolbar(state: state) }
    }

    private var windowEndLabel: String {
        let endMinutes = (state.eatingWindowStartMinutes + state.protocolKind.eatingHours * 60) % (24 * 60)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timeFromMinutes(endMinutes))
    }

    private func timeFromMinutes(_ m: Int) -> Date {
        var comps = DateComponents()
        comps.hour = m / 60
        comps.minute = m % 60
        return Calendar.current.date(from: comps) ?? Date()
    }

    private func minutesFromTime(_ d: Date) -> Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: d)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }
}
