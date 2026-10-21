import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var manager = HealthKitManager()

    var body: some View {
        VStack(spacing: 28) {
            Text("오늘 걸음수")
                .font(.largeTitle.bold())

            StepsRing(steps: manager.todaySteps, lineWidth: 18)
                .frame(width: 220, height: 220)

            Text("목표 \(StepGoal.daily.formatted()) 걸음")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let message = manager.statusMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button {
                    Task {
                        await manager.refreshTodaySteps()
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
