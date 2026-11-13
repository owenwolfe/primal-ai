import SwiftUI

struct ResultView: View {
    let result: Evaluation

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 18) {
                Label(result.status == "complete" ? "YOUR LABEL, EXPLAINED" : "INCOMPLETE MATCH",
                      systemImage: result.rating == "aligned" ? "leaf" : "text.magnifyingglass")
                    .font(.caption.weight(.semibold)).tracking(1)
                Text(result.title).font(.system(.largeTitle, design: .serif))
                    .accessibilityIdentifier("resultTitle")
                    .fixedSize(horizontal: false, vertical: true)
                Text(summary).font(.body)
                Text("Rules: \(result.rulesVersion)").font(.caption.monospaced())
            }
            .padding(24).frame(maxWidth: .infinity, alignment: .leading)
            .background(PrimalStyle.leaf, in: RoundedRectangle(cornerRadius: 24))

            Text("Inside the ingredient list").font(.title2.weight(.semibold))
            VStack(spacing: 0) {
                ForEach(result.findings) { finding in
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(finding.explanation)
                            Text(finding.basis == "preference" ? "Basis: draft product preference" : "Basis: no matching rule")
                                .font(.caption).foregroundStyle(PrimalStyle.muted)
                        }
                        .padding(.vertical, 12)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: finding.isAligned ? "checkmark.circle" : "magnifyingglass.circle")
                                .font(.title3).accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(finding.label).font(.headline)
                                Text(finding.categoryTitle).font(.caption).foregroundStyle(PrimalStyle.muted)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                    if finding.id != result.findings.last?.id { Divider() }
                }
            }
            .padding(.horizontal, 18).background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 20))

            DisclosureGroup("How this result works") {
                Text(result.methodology).font(.subheadline).padding(.vertical, 12)
            }
            Text(result.notice).font(.footnote).foregroundStyle(PrimalStyle.muted)
        }
    }

    private var summary: String {
        if result.status != "complete" {
            return "\(result.unmatchedIngredients.count) ingredient(s) need a closer look. We’ve held back the overall rating. Check the text and review the unmatched ingredients below."
        }
        if result.rating == "aligned" {
            return "Every ingredient matched a whole food or kitchen staple in the draft model. Quantities and nutrition aren’t assessed."
        }
        if result.rating == "review" {
            return "The draft model found an added sweetener or additive to review. Tap each ingredient to understand why it was highlighted."
        }
        return "This result uses an unfamiliar rating. Review the ingredient findings and methodology below."
    }
}
