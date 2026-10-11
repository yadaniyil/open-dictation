import SwiftUI

/// The small round number in front of a step.
struct StepBadge: View {
    let number: Int

    /// Grows with the text, so a large number still fits inside.
    @ScaledMetric(relativeTo: .subheadline) private var side = HomeStyle.badgeSize

    var body: some View {
        Text(verbatim: "\(number)")
            .font(HomeStyle.badgeFont)
            .foregroundStyle(HomeStyle.tint)
            .frame(width: side, height: side)
            .background(Circle().fill(HomeStyle.softTint))
            .accessibilityLabel("Step \(number)")
    }
}

#Preview {
    StepBadge(number: 1)
}
