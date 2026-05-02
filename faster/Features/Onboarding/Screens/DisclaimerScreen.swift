import SwiftUI

struct DisclaimerScreen: View {
    @Bindable var state: OnboardingState

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Hero icon + title
                    VStack(spacing: Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(AppColor.accent.opacity(0.10))
                                .frame(width: 100, height: 100)
                            Image(systemName: "heart.text.clipboard.fill")
                                .font(.system(size: 46))
                                .foregroundStyle(AppColor.accentGradient)
                                .symbolRenderingMode(.hierarchical)
                        }
                        .padding(.top, Spacing.xl)

                        Text("Welcome to faster")
                            .font(AppFont.largeTitle)
                            .multilineTextAlignment(.center)

                        Text("Your intermittent fasting companion")
                            .font(AppFont.callout)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    // Disclaimer bullets
                    VStack(spacing: Spacing.sm) {
                        DisclaimerBullet(
                            icon: "info.circle.fill",
                            color: AppColor.fastingRing,
                            text: "faster provides general guidance for intermittent fasting and weight management."
                        )
                        DisclaimerBullet(
                            icon: "cross.circle.fill",
                            color: AppColor.warning,
                            text: "This is not medical advice and is not a treatment for any condition."
                        )
                        DisclaimerBullet(
                            icon: "stethoscope",
                            color: AppColor.accent,
                            text: "Consult a healthcare provider if you have a medical condition, take medications, are pregnant, or have a history of disordered eating."
                        )
                    }
                    .padding(.bottom, Spacing.xl)
                }
                .padding(.horizontal)
            }

            // Sticky bottom CTA
            VStack(spacing: Spacing.md) {
                Toggle(isOn: $state.acknowledgedDisclaimer) {
                    Text("I understand and accept the above")
                        .font(AppFont.callout)
                }
                .tint(AppColor.accent)

                Button("Get Started") {
                    advance(state)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.accent)
                .disabled(!state.acknowledgedDisclaimer)
                .frame(maxWidth: .infinity)
                .controlSize(.large)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: state.acknowledgedDisclaimer)
            }
            .padding(Spacing.lg)
            .background(.bar)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DisclaimerBullet: View {
    var icon: String
    var color: Color
    var text: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 28)

            Text(text)
                .font(AppFont.callout)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.secondaryBackground,
                    in: RoundedRectangle(cornerRadius: CR.md, style: .continuous))
    }
}
