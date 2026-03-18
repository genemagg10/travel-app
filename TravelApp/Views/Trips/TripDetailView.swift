import SwiftUI
import MapKit
import SwiftData

struct TripDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var trip: Trip

    @State private var showingAddDestination = false
    @State private var showingItinerary = false
    @State private var showingJournal = false
    @State private var showingTracking = false
    @State private var selectedTab = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                actionButtons
                tabContent
            }
        }
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Edit Trip") { }
                    Button("Share Trip") { }
                    if trip.status == "planned" {
                        Button("Start Trip") { trip.status = "active" }
                    }
                    if trip.status == "active" {
                        Button("Complete Trip") { trip.status = "completed" }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddDestination) {
            AddDestinationView(trip: trip)
        }
        .sheet(isPresented: $showingItinerary) {
            ItineraryPlannerView(trip: trip)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Map preview of destinations
            if !trip.destinations.isEmpty {
                Map {
                    ForEach(trip.destinations) { dest in
                        Marker(dest.name, coordinate: dest.coordinate)
                            .tint(.blue)
                    }

                    let sorted = trip.trackPoints.sorted { $0.timestamp < $1.timestamp }
                    if sorted.count > 1 {
                        MapPolyline(coordinates: sorted.map { $0.coordinate })
                            .stroke(.blue, lineWidth: 3)
                    }
                }
                .frame(height: 220)
                .allowsHitTesting(false)
            } else {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.7), .purple.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 220)
                    .overlay {
                        VStack {
                            Image(systemName: "airplane")
                                .font(.system(size: 40))
                                .foregroundStyle(.white.opacity(0.6))
                            Text("Add destinations to see them on the map")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
            }

            // Info overlay
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.name)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .shadow(radius: 3)

                Text(trip.formattedDateRange)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(radius: 2)

                HStack(spacing: 16) {
                    Label("\(trip.destinations.count) places", systemImage: "mappin.circle.fill")
                    Label("\(trip.duration) days", systemImage: "calendar")
                    Label("\(trip.journalEntries.count) entries", systemImage: "book.fill")
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
                .shadow(radius: 2)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                actionButton("Add Place", icon: "mappin.circle.fill", color: .blue) {
                    showingAddDestination = true
                }
                actionButton("Itinerary", icon: "list.bullet.clipboard.fill", color: .green) {
                    showingItinerary = true
                }
                actionButton("Journal", icon: "book.fill", color: .purple) {
                    showingJournal = true
                }
                if trip.status == "active" {
                    actionButton("Track", icon: "location.fill", color: .red) {
                        showingTracking = true
                    }
                }
                actionButton("Photos", icon: "photo.fill", color: .orange) { }
            }
            .padding()
        }
    }

    private func actionButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.15))
                    .foregroundStyle(color)
                    .clipShape(Circle())
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.primary)
            }
        }
    }

    // MARK: - Tab Content

    private var tabContent: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $selectedTab) {
                Text("Overview").tag(0)
                Text("Places").tag(1)
                Text("Timeline").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            switch selectedTab {
            case 0: overviewSection
            case 1: placesSection
            case 2: timelineSection
            default: EmptyView()
            }
        }
    }

    // MARK: - Overview

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !trip.tripDescription.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("About")
                        .font(.headline)
                    Text(trip.tripDescription)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }

            // Rating
            VStack(alignment: .leading, spacing: 6) {
                Text("Rating")
                    .font(.headline)
                HStack {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= trip.rating ? "star.fill" : "star")
                            .foregroundStyle(star <= trip.rating ? .yellow : .gray.opacity(0.3))
                            .font(.title3)
                            .onTapGesture {
                                trip.rating = star
                            }
                    }
                }
            }
            .padding(.horizontal)

            // Quick stats
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statCard("Days", value: "\(trip.duration)", icon: "calendar", color: .blue)
                statCard("Places", value: "\(trip.destinations.count)", icon: "mappin", color: .green)
                statCard("Journal", value: "\(trip.journalEntries.count)", icon: "book", color: .purple)
                statCard("Photos", value: "\(trip.photos.count)", icon: "photo", color: .orange)
            }
            .padding(.horizontal)
        }
        .padding(.top, 16)
    }

    private func statCard(_ title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
                Text(value)
                    .font(.title2.bold())
            }
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Places

    private var placesSection: some View {
        VStack(spacing: 12) {
            if trip.destinations.isEmpty {
                ContentUnavailableView("No Places", systemImage: "mappin.slash", description: Text("Add destinations to your trip"))
                    .frame(height: 200)
            } else {
                ForEach(trip.destinations) { dest in
                    destinationCard(dest)
                }
            }
        }
        .padding()
    }

    private func destinationCard(_ dest: Destination) -> some View {
        HStack(spacing: 12) {
            Map {
                Marker(dest.name, coordinate: dest.coordinate)
            }
            .frame(width: 70, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 4) {
                Text(dest.name)
                    .font(.headline)
                Text(dest.country)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !dest.notes.isEmpty {
                    Text(dest.notes)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Timeline

    private var timelineSection: some View {
        VStack(spacing: 0) {
            let sortedEntries = trip.journalEntries.sorted { $0.date < $1.date }

            if sortedEntries.isEmpty {
                ContentUnavailableView("No Entries", systemImage: "text.book.closed", description: Text("Journal entries will appear here"))
                    .frame(height: 200)
            } else {
                ForEach(sortedEntries) { entry in
                    timelineEntry(entry)
                }
            }
        }
        .padding()
    }

    private func timelineEntry(_ entry: JournalEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(.blue)
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(.blue.opacity(0.3))
                    .frame(width: 2)
            }
            .frame(width: 10)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(entry.title)
                    .font(.subheadline.bold())
                if !entry.content.isEmpty {
                    Text(entry.content)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                if entry.isDailySummary {
                    HStack(spacing: 8) {
                        Label("\(entry.stepCount)", systemImage: "figure.walk")
                        if entry.distanceWalked > 0 {
                            Label(String(format: "%.1f mi", entry.distanceWalked / 1609.344), systemImage: "ruler")
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.blue)
                }
            }
            .padding(.bottom, 16)

            Spacer()
        }
    }
}

// MARK: - Add Destination

struct AddDestinationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let trip: Trip

    @State private var name = ""
    @State private var country = ""
    @State private var notes = ""
    @State private var latitude = ""
    @State private var longitude = ""
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Search for a Place") {
                    TextField("Search location...", text: $searchText)
                        .onSubmit { searchLocation() }

                    if !searchResults.isEmpty {
                        ForEach(searchResults, id: \.self) { item in
                            Button {
                                selectMapItem(item)
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(item.name ?? "Unknown")
                                        .foregroundStyle(.primary)
                                    if let address = item.placemark.title {
                                        Text(address)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                Section("Place Details") {
                    TextField("Name", text: $name)
                    TextField("Country", text: $country)
                    TextField("Latitude", text: $latitude)
                        .keyboardType(.decimalPad)
                    TextField("Longitude", text: $longitude)
                        .keyboardType(.decimalPad)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }
            }
            .navigationTitle("Add Destination")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") { addDestination() }
                        .disabled(name.isEmpty)
                        .bold()
                }
            }
        }
    }

    private func searchLocation() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            searchResults = response?.mapItems ?? []
        }
    }

    private func selectMapItem(_ item: MKMapItem) {
        name = item.name ?? ""
        let coord = item.placemark.coordinate
        latitude = "\(coord.latitude)"
        longitude = "\(coord.longitude)"
        country = item.placemark.country ?? ""
        searchResults = []
    }

    private func addDestination() {
        let dest = Destination(
            name: name,
            country: country,
            latitude: Double(latitude) ?? 0,
            longitude: Double(longitude) ?? 0,
            notes: notes
        )
        dest.trip = trip
        trip.destinations.append(dest)
        dismiss()
    }
}
