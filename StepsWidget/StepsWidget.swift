import WidgetKit
import SwiftUI

struct StepsEntry: TimelineEntry {
    let date: Date
    let activity: TodayActivity
}

struct StepsProvider: TimelineProvider {
    private var sample: TodayActivity {
        TodayActivity(steps: 6420, activeKcal: 320, estimatedKcal: 256)
    }

    func placeholder(in context: Context) -> StepsEntry {
        StepsEntry(date: Date(), activity: sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (StepsEntry) -> Void) {
        if context.isPreview {
            completion(StepsEntry(date: Date(), activity: sample))
            return
        }
        Task {
            let activity = await StepsReader.todayActivity()
            completion(StepsEntry(date: Date(), activity: activity))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StepsEntry>) -> Void) {
        Task {
            let activity = await StepsReader.todayActivity()
            let entry = StepsEntry(date: Date(), activity: activity)
            // 약 30분 뒤 갱신 (WidgetKit 예산에 따라 실제 주기는 달라질 수 있음)
            let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }
}

struct StepsWidgetEntryView: View {
    var entry: StepsEntry
    @Environment(\.widgetFamily) private var family

    private var activity: TodayActivity { entry.activity }

    var body: some View {
        switch family {
        case .systemMedium:
            HStack(spacing: 18) {
                StepsRing(steps: activity.steps, lineWidth: 12)
                    .frame(width: 104, height: 104)

                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Label("오늘 걸음수", systemImage: "figure.walk")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                        Text(activity.steps, format: .number)
                            .font(.system(.title, design: .rounded).weight(.bold))
                    }
                    StatBadge(icon: "flame.fill", tint: .orange,
                              label: "활동 에너지", value: kcalText(activity.activeKcal))
                    StatBadge(icon: "figure.walk", tint: .green,
                              label: "걸음 추정", value: kcalText(activity.estimatedKcal))
                }
                Spacer(minLength: 0)
            }
            .containerBackground(.fill.tertiary, for: .widget)

        default:
            VStack(spacing: 6) {
                StepsRing(steps: activity.steps, lineWidth: 10)
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text("\(kcalText(activity.activeKcal)) · 추정 \(kcalText(activity.estimatedKcal))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
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
        .description("오늘 걸음 수와 소모 칼로리를 보여줍니다.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    StepsWidget()
} timeline: {
    StepsEntry(date: .now, activity: TodayActivity(steps: 6420, activeKcal: 320, estimatedKcal: 256))
    StepsEntry(date: .now, activity: TodayActivity(steps: 10240, activeKcal: 540, estimatedKcal: 409))
}
