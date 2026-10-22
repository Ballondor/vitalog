import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var manager = HealthKitManager()

    var body: some View {
        VStack(spacing: 24) {
            Text("오늘 걸음수")
                .font(.largeTitle.bold())

            StepsRing(steps: manager.activity.steps, lineWidth: 18)
                .frame(width: 200, height: 200)

            Text("목표 \(StepGoal.daily.formatted()) 걸음")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 28) {
                StatBadge(
                    icon: "flame.fill",
                    tint: .orange,
                    label: "활동 에너지",
                    value: kcalText(manager.activity.activeKcal)
                )
                StatBadge(
                    icon: "figure.walk",
                    tint: .green,
                    label: "걸음 추정",
                    value: kcalText(manager.activity.estimatedKcal)
                )
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)

            if let message = manager.statusMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button {
                    Task {
                        await manager.refresh()
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                } label: {
                    Label("새로고침", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button("건강 권한 다시 요청") {
                    Task { await manager.requestAuthorization() }
                }
                .font(.footnote)
            }
            .padding(.horizontal, 40)
        }
        .padding()
        .task {
            await manager.requestAuthorization()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

#Preview {
    ContentView()
}
