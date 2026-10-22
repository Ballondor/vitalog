import SwiftUI

/// 걸음 목표 등 공용 상수.
enum StepGoal {
    static let daily = 10_000
}

/// kcal 값을 정수 문자열로 포맷한다. (예: 299.4 → "299")
func kcalText(_ kcal: Double) -> String {
    "\(Int(kcal.rounded())) kcal"
}

/// 아이콘 + 라벨 + 값 한 벌의 작은 통계 뱃지. (앱 + 위젯 공용)
struct StatBadge: View {
    let icon: String
    let tint: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
            }
        }
    }
}

/// 오늘 걸음 수를 목표 대비 진행 링으로 보여주는 공용 뷰. (앱 + 위젯 공용)
struct StepsRing: View {
    let steps: Int
    var goal: Int = StepGoal.daily
    var lineWidth: CGFloat = 12

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(steps) / Double(goal), 1.0)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.green.opacity(0.18), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(colors: [.green, .mint, .green], center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Image(systemName: "figure.walk")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.green)
                Text(steps, format: .number)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("걸음")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(lineWidth)
        }
    }
}

#Preview {
    StepsRing(steps: 6420)
        .frame(width: 180, height: 180)
        .padding()
}
