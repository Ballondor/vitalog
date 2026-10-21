import Foundation
import HealthKit

/// HealthKit 걸음 수 읽기 — 앱 타겟과 위젯 익스텐션에서 공용으로 사용한다.
/// 권한은 앱에서 한 번 요청하면 같은 앱 번들의 익스텐션(위젯)과 공유된다.
enum StepsReader {

    static let stepType = HKQuantityType(.stepCount)

    /// 걸음 수 읽기 권한 요청. (쓰기 권한은 요청하지 않는다)
    static func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try await HKHealthStore().requestAuthorization(toShare: [], read: [stepType])
    }

    /// 오늘 0시부터 지금까지 누적 걸음 수.
    static func todaySteps() async -> Int {
        guard HKHealthStore.isHealthDataAvailable() else { return 0 }
        let store = HKHealthStore()

        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: Date(),
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(steps))
            }
            store.execute(query)
        }
    }
}
