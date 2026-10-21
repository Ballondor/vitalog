import WidgetKit
import SwiftUI

struct StepsEntry: TimelineEntry {
    let date: Date
    let steps: Int
}

struct StepsProvider: TimelineProvider {
    func placeholder(in context: Context) -> StepsEntry {
        StepsEntry(date: Date(), steps: 6420)
    }

    func getSnapshot(in context: Context, completion: @escaping (StepsEntry) -> Void) {
        if context.isPreview {
            completion(StepsEntry(date: Date(), steps: 6420))
            return
        }
        Task {
            let steps = await StepsReader.todaySteps()
            completion(StepsEntry(date: Date(), steps: steps))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StepsEntry>) -> Void) {
        Task {
            let steps = await StepsReader.todaySteps()
            let entry = StepsEntry(date: Date(), steps: steps)
            // 약 30분 뒤 갱신 (WidgetKit 예산에 따라 실제 주기는 달라질 수 있음)
            let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }
}

struct StepsWidgetEntryView: View {
    var entry: StepsEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium:
            HStack(spacing: 20) {
                StepsRing(steps: entry.steps, lineWidth: 12)
                    .frame(width: 110, height: 110)

                VStack(alignment: .leading, spacing: 6) {
                    Label("오늘 걸음수", systemImage: "figure.walk")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                    Text(entry.steps, format: .number)
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    Text("목표 \(StepGoal.daily.formatted()) 걸음")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .containerBackground(.fill.tertiary, for: .widget)

        default:
            StepsRing(steps: entry.steps, lineWidth: 11)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

struct StepsWidget: Widget {
    let kind = "StepsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StepsProvider()) { entry in
            StepsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("오늘 걸음수")
        .description("오늘 걸은 걸음 수를 보여줍니다.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    StepsWidget()
} timeline: {
    StepsEntry(date: .now, steps: 6420)
    StepsEntry(date: .now, steps: 10240)
}
