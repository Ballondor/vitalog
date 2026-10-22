import Foundation
import HealthKit

/// 오늘의 활동 요약 — 걸음 수, 실제 활동 에너지(HealthKit), 걸음 기반 추정 칼로리.
struct TodayActivity {
    var steps: Int = 0
    var activeKcal: Double = 0      // HealthKit 활동 에너지 (실제 소모)
    var estimatedKcal: Double = 0   // 걸음 수 × 체중 기반 추정
}

/// HealthKit 읽기 — 앱 타겟과 위젯 익스텐션에서 공용으로 사용한다.
/// 권한은 앱에서 한 번 요청하면 같은 앱 번들의 익스텐션(위젯)과 공유된다.
enum StepsReader {

    static let stepType = HKQuantityType(.stepCount)
    static let energyType = HKQuantityType(.activeEnergyBurned)
    static let bodyMassType = HKQuantityType(.bodyMass)

    static var readTypes: Set<HKObjectType> { [stepType, energyType, bodyMassType] }

    /// 걸음당 kcal 추정 계수 (체중 1kg 기준). 70kg면 걸음당 ≈ 0.04kcal.
    static let kcalPerStepPerKg = 0.00057
    /// 체중 데이터가 없을 때 사용하는 기본 체중(kg).
    static let defaultBodyMassKg = 70.0

    /// 걸음 수·활동 에너지·체중 읽기 권한 요청. (쓰기 권한은 요청하지 않는다)
    static func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try await HKHealthStore().requestAuthorization(toShare: [], read: readTypes)
    }

    /// 오늘 0시부터 지금까지 누적 걸음 수.
    static func todaySteps() async -> Int {
        let kcal = await cumulativeSum(of: stepType, unit: .count())
        return Int(kcal)
    }

    /// 오늘 누적 활동 에너지(kcal).
    static func todayActiveEnergy() async -> Double {
        await cumulativeSum(of: energyType, unit: .kilocalorie())
    }

    /// 가장 최근 체중(kg). 기록이 없으면 nil.
    static func latestBodyMass() async -> Double? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }
        let store = HKHealthStore()
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: bodyMassType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                let kg = (samples?.first as? HKQuantitySample)?
                    .quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: kg)
            }
            store.execute(query)
        }
    }

    /// 오늘의 활동 요약(걸음·활동 에너지·걸음 기반 추정)을 한 번에 구성한다.
    static func todayActivity() async -> TodayActivity {
        async let stepsTask = todaySteps()
        async let activeTask = todayActiveEnergy()
        async let weightTask = latestBodyMass()

        let steps = await stepsTask
        let weight = (await weightTask) ?? defaultBodyMassKg
        let estimate = Double(steps) * weight * kcalPerStepPerKg
        return TodayActivity(steps: steps, activeKcal: await activeTask, estimatedKcal: estimate)
    }

    /// 오늘 0시~현재 구간의 누적 합계를 지정한 단위로 읽는다.
    private static func cumulativeSum(of type: HKQuantityType, unit: HKUnit) async -> Double {
        guard HKHealthStore.isHealthDataAvailable() else { return 0 }
        let store = HKHealthStore()
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                continuation.resume(returning: result?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            store.execute(query)
        }
    }
}
