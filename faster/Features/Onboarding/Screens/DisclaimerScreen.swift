import SwiftUI

struct DisclaimerScreen: View {
    @Bindable var state: OnboardingState

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Welcome to faster")
                .font(AppFont.largeTitle)
            Text("Before we begin")
                .font(AppFont.title)
            Text("faster provides general guidance for intermittent fasting and weight loss. It is not medical advice and is not a treatment for any condition.")
                .font(AppFont.body)
            Text("Please consult a healthcare provider before starting if you have a medical condition, are on medications, are pregnant or breastfeeding, or have a history of disordered eating.")
                .font(AppFont.body)
                .foregroundStyle(.secondary)
            Spacer()
            Toggle("I understand and acknowledge the above.", isOn: $state.acknowledgedDisclaimer)
                .padding(.vertical)
            Button("Continue") { advance(state) }
                .buttonStyle(.borderedProminent)
                .disabled(!state.acknowledgedDisclaimer)
                .frame(maxWidth: .infinity)
        }
        .padding()
    }
}
