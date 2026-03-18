import SwiftUI
import SwiftData
import Charts

struct TravelStatsView: View {
    @Query private var trips: [Trip]
    @Query private var countryVisits: [CountryVisit]
    @Query private var journalEntries: [JournalEntry]
    @Query private var photos: [TravelPhoto]
    @Query private var trackPoints: [GPSTrackPoint]

    var completedTrips: [Trip] { trips.filter { $0.status == "completed" } }
    var totalDaysTraveled: Int { completedTrips.reduce(0) { $0 + $1.duration } }
    var totalCountries: Int { countryVisits.filter { $0.category == "visited" || $0.category == "favorite" }.count }

    var tripsByYear: [(String, Int)] {
        let grouped = Dictionary(grouping: completedTrips) { trip in
            Calendar.current.component(.year, from: trip.startDate)
        }
        return grouped.map { ("\($0.key)", $0.value.count) }.sorted { $0.0 < $1.0 }
    }

    var countriesByRegion: [(String, Int)] {
        let visited = countryVisits.filter { $0.category == "visited" || $0.category == "favorite" }
        let byRegion = Dictionary(grouping: visited) { visit in
            CountryData.country(byCode: visit.countryCode)?.region ?? "Other"
        }
        return byRegion.map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroStats
                    travelScoreCard
                    if !tripsByYear.isEmpty { tripsPerYearChart }
                    if !countriesByRegion.isEmpty { regionBreakdownChart }
                    moodBreakdown
                    recentTripsSection
                }
                .padding()
            }
            .navigationTitle("Travel Stats")
        }
    }

    // MARK: - Hero Stats

    private var heroStats: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            heroStat(value: "\(completedTrips.count)", label: "Trips", icon: "suitcase.fill", color: .blue)
            heroStat(value: "\(totalCountries)", label: "Countries", icon: "globe", color: .green)
            heroStat(value: "\(totalDaysTraveled)", label: "Days", icon: "calendar", color: .orange)
        }
    }

    private func heroStat(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Travel Score

    private var travelScoreCard: some View {
        let score = calculateTravelScore()

        return VStack(spacing: 10) {
            HStack {
                Text("Travel Score")
                    .font(.headline)
                Spacer()
                Text("\(score)/100")
                    .font(.title2.bold())
                    .foregroundStyle(.blue)
            }

            ProgressView(value: Double(score), total: 100)
                .tint(scoreColor(score))

            Text(scoreMessage(score))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func calculateTravelScore() -> Int {
        var score = 0
        score += min(totalCountries * 5, 40) // Up to 40 points for countries
        score += min(completedTrips.count * 3, 20) // Up to 20 for trips
        score += min(journalEntries.count, 15) // Up to 15 for journaling
        score += min(photos.count / 5, 15) // Up to 15 for photos
        score += min(totalDaysTraveled / 10, 10) // Up to 10 for days
        return min(score, 100)
    }

    private func scoreColor(_ score: Int) -> Color {
        if score >= 75 { return .green }
        if score >= 50 { return .blue }
        if score >= 25 { return .orange }
        return .red
    }

    private func scoreMessage(_ score: Int) -> String {
        if score >= 75 { return "Globe Trotter! You've seen a lot of the world." }
        if score >= 50 { return "Seasoned Traveler. Keep exploring!" }
        if score >= 25 { return "Getting Started. Many adventures await!" }
        return "Armchair Explorer. Time to plan your first trip!"
    }

    // MARK: - Trips Per Year Chart

    private var tripsPerYearChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Trips Per Year")
                .font(.headline)

            Chart(tripsByYear, id: \.0) { item in
                BarMark(
                    x: .value("Year", item.0),
                    y: .value("Trips", item.1)
                )
                .foregroundStyle(.blue.gradient)
                .cornerRadius(6)
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Region Breakdown

    private var regionBreakdownChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Countries by Region")
                .font(.headline)

            Chart(countriesByRegion, id: \.0) { item in
                SectorMark(
                    angle: .value("Count", item.1),
                    innerRadius: .ratio(0.5),
                    angularInset: 2
                )
                .foregroundStyle(by: .value("Region", item.0))
                .cornerRadius(4)
            }
            .frame(height: 200)

            // Legend
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(countriesByRegion, id: \.0) { item in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.blue)
                            .frame(width: 8, height: 8)
                        Text("\(item.0): \(item.1)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Mood Breakdown

    private var moodBreakdown: some View {
        let moodCounts = Dictionary(grouping: journalEntries) { $0.mood }
            .map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }

        return Group {
            if !moodCounts.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Travel Moods")
                        .font(.headline)

                    HStack(spacing: 16) {
                        ForEach(moodCounts, id: \.0) { item in
                            VStack(spacing: 4) {
                                Text(moodEmoji(item.0))
                                    .font(.title)
                                Text("\(item.1)")
                                    .font(.headline)
                                Text(item.0.capitalized)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private func moodEmoji(_ mood: String) -> String {
        switch mood {
        case "great": return "😄"
        case "good": return "🙂"
        case "okay": return "😐"
        case "tired": return "😴"
        case "rough": return "😓"
        default: return "🙂"
        }
    }

    // MARK: - Recent Trips

    private var recentTripsSection: some View {
        Group {
            if !completedTrips.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recent Adventures")
                        .font(.headline)

                    ForEach(completedTrips.prefix(5)) { trip in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(trip.name)
                                    .font(.subheadline.bold())
                                Text(trip.formattedDateRange)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if trip.rating > 0 {
                                HStack(spacing: 2) {
                                    ForEach(0..<trip.rating, id: \.self) { _ in
                                        Image(systemName: "star.fill")
                                            .font(.caption2)
                                            .foregroundStyle(.yellow)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}
