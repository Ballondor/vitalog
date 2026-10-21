import Foundation
import HealthKit
import Observation

/// 앱 화면에서 HealthKit 권한 요청과 오늘 걸음 수 상태를 관리한다.
@MainActor
@Observable
final class HealthKitManager {

    var todaySteps: Int = 0
    var statusMessage: String?

    /// 걸음 수 읽기 권한 요청 후 오늘 걸음 수를 불러온다.
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            statusMessage = "이 기기에서는 건강 데이터를 사용할 수 없어요."
            return
        }
        do {
            try await StepsReader.requestAuthorization()
            statusMessage = nil
            await refreshTodaySteps()
        } catch {
            statusMessage = "건강 권한 요청에 실패했어요."
        }
    }

    /// 오늘 걸음 수만 다시 읽는다.
    func refreshTodaySteps() async {
        todaySteps = await StepsReader.todaySteps()
    }
}
