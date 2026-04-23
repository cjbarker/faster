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
                    Section("Appearance") {
                        Picker("Theme", selection: Binding(
                            get: { profile.appearanceMode },
                            set: { profile.appearanceMode = $0; try? context.save() }
                        )) {
                            ForEach(AppearanceMode.allCases, id: \.self) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        Text("Dark mode can be always on, always off, or follow your iPhone's setting.")
                            .font(AppFont.caption).foregroundStyle(.secondary)
                    }

                    Section("Units") {
                        Picker("Unit system", selection: Binding(
                            get: { profile.unitSystem },
                            set: { profile.unitSystem = $0; try? context.save() }
                        )) {
                            Text("Imperial").tag(UnitSystem.imperial)
                            Text("Metric").tag(UnitSystem.metric)
                        }
                        .pickerStyle(.segmented)
                    }

                    Section("Apple Health") {
                        Toggle("Log completed fasts to Apple Health as Mindful Minutes", isOn: Binding(
                            get: { profile.writeFastsToHealthKit },
                            set: { profile.writeFastsToHealthKit = $0; try? context.save() }
                        ))
                        Button("Re-request Health permissions") {
                            Task { try? await deps.healthStore.requestAuthorization() }
                        }
                    }
                }

                if let plan = plans.first {
                    Section("Fasting plan") {
                        Picker("Protocol", selection: Binding(
                            get: { plan.protocolKind },
                            set: { plan.protocolKind = $0; try? context.save() }
                        )) {
                            ForEach(ProtocolKind.allCases, id: \.self) { p in
                                Text(p.rawValue).tag(p)
                            }
                        }
                        Toggle("Hydration nudges", isOn: Binding(
                            get: { plan.hydrationNudgesEnabled },
                            set: { plan.hydrationNudgesEnabled = $0; try? context.save() }
                        ))
                        Toggle("Electrolyte reminders", isOn: Binding(
                            get: { plan.electrolyteRemindersEnabled },
                            set: { plan.electrolyteRemindersEnabled = $0; try? context.save() }
                        ))
                        Toggle("Daily weigh-in reminder", isOn: Binding(
                            get: { plan.dailyWeighInEnabled },
                            set: { plan.dailyWeighInEnabled = $0; try? context.save() }
                        ))
                    }
                }

                if let goal = goals.first, let profile = profiles.first {
                    Section("Goal") {
                        WeightField(label: "Target weight", kg: Binding(
                            get: { goal.targetWeightKg },
                            set: { goal.targetWeightKg = $0; try? context.save() }
                        ), unitSystem: profile.unitSystem)
                    }
                }

                Section("Data") {
                    Button("Export JSON") { export(.json) }
                    Button("Export CSV")  { export(.csv) }
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.shortVersion)
                    Text("Not medical advice. Not a treatment for any condition.")
                        .font(AppFont.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showShare) {
                if let url = exportURL {
                    ShareLink(item: url) { Text("Share \(url.lastPathComponent)") }
                        .padding()
                }
            }
        }
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
