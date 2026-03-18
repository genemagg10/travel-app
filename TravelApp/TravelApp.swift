import SwiftUI
import SwiftData

@main
struct TravelApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .withSampleData()
        }
        .modelContainer(for: [
            Trip.self,
            Destination.self,
            JournalEntry.self,
            ItineraryDay.self,
            Activity.self,
            TravelPhoto.self,
            GPSTrackPoint.self,
            CountryVisit.self
        ])
    }
}
