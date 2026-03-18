import Foundation
import HealthKit

@Observable
class HealthService {
    private let healthStore = HKHealthStore()
    var isAuthorized = false
    var todaySteps: Int = 0
    var todayDistance: Double = 0 // meters

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async {
        guard isHealthDataAvailable else { return }

        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.flightsClimbed)
        ]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            await fetchTodayData()
        } catch {
            print("HealthKit authorization failed: \(error)")
        }
    }

    @MainActor
    func fetchTodayData() async {
        await fetchSteps()
        await fetchDistance()
    }

    @MainActor
    func fetchSteps(for date: Date = Date()) async {
        guard isAuthorized else { return }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay)
        let stepType = HKQuantityType(.stepCount)

        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
                let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    let steps = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    continuation.resume(returning: steps)
                }
                healthStore.execute(query)
            }
            todaySteps = Int(result)
        } catch {
            print("Failed to fetch steps: \(error)")
        }
    }

    @MainActor
    func fetchDistance(for date: Date = Date()) async {
        guard isAuthorized else { return }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay)
        let distanceType = HKQuantityType(.distanceWalkingRunning)

        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
                let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    let distance = statistics?.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                    continuation.resume(returning: distance)
                }
                healthStore.execute(query)
            }
            todayDistance = result
        } catch {
            print("Failed to fetch distance: \(error)")
        }
    }

    func stepsString(_ steps: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }

    func distanceString(_ meters: Double) -> String {
        let miles = meters / 1609.344
        return String(format: "%.1f mi", miles)
    }
}
