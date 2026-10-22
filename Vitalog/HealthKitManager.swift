import Foundation
import HealthKit
import Observation

/// 앱 화면에서 HealthKit 권한 요청과 오늘 활동 요약(걸음·칼로리)을 관리한다.
@MainActor
@Observable
final class HealthKitManager {

    var activity = TodayActivity()
    var statusMessage: String?

    var todaySteps: Int { activity.steps }

    /// 권한 요청 후 오늘 활동 요약을 불러온다.
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            statusMessage = "이 기기에서는 건강 데이터를 사용할 수 없어요."
            return
        }
        do {
            try await StepsReader.requestAuthorization()
            statusMessage = nil
            await refresh()
        } catch {
            statusMessage = "건강 권한 요청에 실패했어요."
        }
    }

    /// 오늘 활동 요약을 다시 읽는다.
    func refresh() async {
        activity = await StepsReader.todayActivity()
    }
}
