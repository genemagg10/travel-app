import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            WorldMapView()
                .tabItem {
                    Label("Map", systemImage: "globe.americas.fill")
                }
                .tag(0)

            TripsListView()
                .tabItem {
                    Label("Trips", systemImage: "suitcase.fill")
                }
                .tag(1)

            JournalListView()
                .tabItem {
                    Label("Journal", systemImage: "book.fill")
                }
                .tag(2)

            PhotoMemoriesView()
                .tabItem {
                    Label("Memories", systemImage: "photo.on.rectangle.angled")
                }
                .tag(3)

            TravelStatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(4)
        }
        .tint(.blue)
    }
}
