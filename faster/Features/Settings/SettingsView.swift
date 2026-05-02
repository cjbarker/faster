import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppDependencies.self) private var deps
    @Query private var profiles: [UserProfile]
    @Query private var plans: [FastingPlan]
    @Query private var goals: [Goal]

    @State private var exportURL: URL?
    @State private var showShare = false

    var body: some View {
        NavigationStack {
            Form {
                if let profile = profiles.first {
                    Section {
                        Picker(selection: Binding(
                            get: { profile.appearanceMode },
                            set: { profile.appearanceMode = $0; try? context.save() }
                        )) {
                            ForEach(AppearanceMode.allCases, id: \.self) { mode in
                                Text(mode.title).tag(mode)
                            }
                        } label: {
                            Label("Theme", systemImage: "circle.lefthalf.filled")
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Label("Appearance", systemImage: "paintpalette")
                    } footer: {
                        Text("Override system light/dark mode or let your iPhone decide.")
                            .font(AppFont.caption)
                    }

                    Section {
                        Picker(selection: Binding(
                            get: { profile.unitSystem },
                            set: { profile.unitSystem = $0; try? context.save() }
                        )) {
                            Text("Imperial").tag(UnitSystem.imperial)
                            Text("Metric").tag(UnitSystem.metric)
                        } label: {
                            Label("Units", systemImage: "ruler")
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Label("Measurement", systemImage: "scalemass")
                    }

                    Section {
                        Toggle(isOn: Binding(
                            get: { profile.writeFastsToHealthKit },
                            set: { profile.writeFastsToHealthKit = $0; try? context.save() }
                        )) {
                            Label("Log fasts to Health", systemImage: "heart.fill")
                        }
                        .tint(AppColor.accent)

                        Button {
                            Task { try? await deps.healthStore.requestAuthorization() }
                        } label: {
                            Label("Re-request permissions", systemImage: "arrow.clockwise")
                        }
                    } header: {
                        Label("Apple Health", systemImage: "heart.text.square")
                    } footer: {
                        Text("Completed fasts are logged as Mindful Minutes.")
                            .font(AppFont.caption)
                    }
                }

                if let plan = plans.first {
                    Section {
                        Picker(selection: Binding(
                            get: { plan.protocolKind },
                            set: { plan.protocolKind = $0; try? context.save() }
                        )) {
                            ForEach(ProtocolKind.allCases, id: \.self) { p in
                                Text(p.rawValue).tag(p)
                            }
                        } label: {
                            Label("Protocol", systemImage: "timer")
                        }

                        DatePicker(
                            selection: Binding(
                                get: { minutesToDate(plan.eatingWindowStartMinutes) },
                                set: { plan.eatingWindowStartMinutes = dateToMinutes($0); try? context.save() }
                            ),
                            displayedComponents: .hourAndMinute
                        ) {
                            Label("Eating window opens", systemImage: "clock")
                        }

                        Toggle(isOn: Binding(
                            get: { plan.hydrationNudgesEnabled },
                            set: { plan.hydrationNudgesEnabled = $0; try? context.save() }
                        )) {
                            Label("Hydration nudges", systemImage: "drop.fill")
                        }
                        .tint(AppColor.eatingRing)

                        Toggle(isOn: Binding(
                            get: { plan.electrolyteRemindersEnabled },
                            set: { plan.electrolyteRemindersEnabled = $0; try? context.save() }
                        )) {
                            Label("Electrolyte reminders", systemImage: "bolt.fill")
                        }
                        .tint(.orange)

                        Toggle(isOn: Binding(
                            get: { plan.dailyWeighInEnabled },
                            set: { plan.dailyWeighInEnabled = $0; try? context.save() }
                        )) {
                            Label("Daily weigh-in reminder", systemImage: "scalemass.fill")
                        }
                        .tint(AppColor.accent)
                    } header: {
                        Label("Fasting Plan", systemImage: "timer")
                    }
                }

                if let goal = goals.first, let profile = profiles.first {
                    Section {
                        WeightField(
                            label: "Target weight",
                            kg: Binding(
                                get: { goal.targetWeightKg },
                                set: { goal.targetWeightKg = $0; try? context.save() }
                            ),
                            unitSystem: profile.unitSystem
                        )
                    } header: {
                        Label("Goal", systemImage: "target")
                    }
                }

                Section {
                    Button {
                        export(.json)
                    } label: {
                        Label("Export JSON", systemImage: "arrow.up.doc.fill")
                    }
                    Button {
                        export(.csv)
                    } label: {
                        Label("Export CSV", systemImage: "tablecells")
                    }
                } header: {
                    Label("Data", systemImage: "square.and.arrow.up")
                }

                Section {
                    LabeledContent {
                        Text(Bundle.main.shortVersion)
                            .foregroundStyle(.secondary)
                    } label: {
                        Label("Version", systemImage: "info.circle")
                    }

                    Text("Not medical advice. Not a treatment for any condition.")
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Label("About", systemImage: "info.circle")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showShare) {
                if let url = exportURL {
                    ShareLink(item: url) {
                        Label("Share \(url.lastPathComponent)", systemImage: "square.and.arrow.up")
                    }
                    .padding(Spacing.lg)
                }
            }
        }
    }

    private func minutesToDate(_ minutes: Int) -> Date {
        var c = DateComponents(); c.hour = minutes / 60; c.minute = minutes % 60
        return Calendar.current.date(from: c) ?? Date()
    }

    private func dateToMinutes(_ date: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    private enum ExportKind { case json, csv }
    private func export(_ kind: ExportKind) {
        do {
            exportURL = try (kind == .json ? deps.exportService.exportJSON() : deps.exportService.exportCSV())
            showShare = true
        } catch {
            exportURL = nil
        }
    }
}

private extension Bundle {
    var shortVersion: String {
        (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
    }
}
