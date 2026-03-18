import SwiftUI
import SwiftData

struct SampleDataLoader: ViewModifier {
    @Environment(\.modelContext) private var modelContext
    @Query private var trips: [Trip]
    @AppStorage("hasLoadedSampleData") private var hasLoadedSampleData = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                if !hasLoadedSampleData && trips.isEmpty {
                    SampleDataService.createNYCTrip(in: modelContext)
                    hasLoadedSampleData = true
                }
            }
    }
}

extension View {
    func withSampleData() -> some View {
        modifier(SampleDataLoader())
    }
}
