import SwiftUI

// MARK: - Compare cards

/// Renders a set of candidate `Solution`s as equal-width, side-by-side compare
/// cards so the founder can weigh them on the same axes (lens / appetite /
/// impact, riskiest assumption, cheapest test) and pick one. Self-contained: it
/// knows nothing about RunManager or opportunities — it takes the solutions plus
/// two closures, so it stays reusable and parallel-safe. The host decides whether
/// to show the section, so an empty set renders nothing.
struct CompareCardView: View {
    let solutions: [Solution]
    /// Open the solution's detail (the founder wants to read the full pitch).
    var onOpen: (Solution) -> Void
    /// Spec the solution — the host launches /pm-prd for it.
    var onSpec: (Solution) -> Void

    var body: some View {
        if solutions.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Candidate solutions").font(.headline).foregroundStyle(Color.npInk)
                    Spacer(minLength: 0)
                    Text(solutions.count == 1 ? "1 to compare" : "\(solutions.count) to compare")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(solutions) { solution in
                            CompareCard(solution: solution, onOpen: onOpen, onSpec: onSpec)
                                .frame(width: 260, alignment: .topLeading)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// MARK: - One card

/// A single solution rendered as a compare column. The labeled blocks line up
/// row-for-row across sibling cards (title → chips → pitch → riskiest → cheapest
/// → footer) so the same axis is visually comparable. A picked solution
/// (`chosen` / `speccing`) gets a thicker olive border.
private struct CompareCard: View {
    let solution: Solution
    var onOpen: (Solution) -> Void
    var onSpec: (Solution) -> Void

    private var isPicked: Bool {
        solution.status == "chosen" || solution.status == "speccing"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 1. Title
            Text(solution.title)
                .font(.headline)
                .foregroundStyle(Color.npInk)
                .lineLimit(2)

            // 2. Chip row (lens / appetite / impact)
            HStack(spacing: 6) {
                OpportunityBadge(text: solution.lens, tint: solutionLensTint(solution.lens))
                OpportunityBadge(text: solution.appetite, tint: solutionAppetiteTint(solution.appetite))
                OpportunityBadge(text: solution.impact, tint: solutionImpactTint(solution.impact))
            }

            // 3. Pitch — only when present
            if !solution.summary.isEmpty {
                Text(solution.summary)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // 4. Riskiest assumption
            labeledBlock(label: "⚠ Riskiest assumption", value: solution.riskiestAssumption)

            // 5. Cheapest test
            labeledBlock(label: "🧪 Cheapest test", value: solution.cheapestTest)

            Spacer(minLength: 0)

            // 6. Footer button row
            HStack(spacing: 8) {
                Button("Open") { onOpen(solution) }
                    .buttonStyle(.bordered)
                    .help("Open this solution")
                Button("Spec this →") { onSpec(solution) }
                    .buttonStyle(.borderedProminent)
                    .help("Spec this solution — launches /pm-prd for it")
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(14)
        .background(Color.npSurface.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isPicked ? Color.npOlive : Color.npBorder,
                              lineWidth: isPicked ? 2 : 1)
        )
    }

    /// A caption label over a single prose line; "—" when the value is empty so
    /// the row still occupies its place across sibling cards.
    @ViewBuilder
    private func labeledBlock(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value.isEmpty ? "—" : value)
                .font(.caption)
                .foregroundStyle(value.isEmpty ? AnyShapeStyle(.tertiary) : AnyShapeStyle(Color.npInk))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
