import SwiftUI
import MapKit
import SwiftData

struct WorldMapView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var countryVisits: [CountryVisit]
    @Query private var trips: [Trip]
    @Query private var trackPoints: [GPSTrackPoint]

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedCountry: CountryVisit?
    @State private var showingCountryPicker = false
    @State private var showingHeatMap = false
    @State private var mapStyle: MapDisplayStyle = .standard
    @State private var showingFilterSheet = false
    @State private var filterCategory: String = "all"

    enum MapDisplayStyle: String, CaseIterable {
        case standard = "Standard"
        case satellite = "Satellite"
        case hybrid = "Hybrid"
    }

    var filteredVisits: [CountryVisit] {
        if filterCategory == "all" { return countryVisits }
        return countryVisits.filter { $0.category == filterCategory }
    }

    var visitedCount: Int { countryVisits.filter { $0.category == "visited" }.count }
    var wantToVisitCount: Int { countryVisits.filter { $0.category == "wantToVisit" }.count }
    var favoriteCount: Int { countryVisits.filter { $0.category == "favorite" }.count }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                mapContent

                VStack(spacing: 12) {
                    // Map controls
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            mapStyleButton
                            heatMapToggle
                            filterButton
                        }
                        .padding(.trailing, 12)
                    }

                    // Stats bar
                    statsBar
                }
            }
            .navigationTitle("World Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCountryPicker = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingCountryPicker) {
                CountryPickerView()
            }
            .sheet(item: $selectedCountry) { country in
                CountryDetailSheet(country: country)
            }
        }
    }

    // MARK: - Map Content

    @ViewBuilder
    private var mapContent: some View {
        Map(position: $cameraPosition) {
            // Country markers
            ForEach(filteredVisits) { visit in
                if let info = CountryData.country(byCode: visit.countryCode) {
                    Annotation(visit.countryName, coordinate: info.coordinate) {
                        countryMarker(for: visit)
                            .onTapGesture {
                                selectedCountry = visit
                            }
                    }
                }
            }

            // GPS track lines
            if showingHeatMap {
                ForEach(trips) { trip in
                    let sorted = trip.trackPoints.sorted { $0.timestamp < $1.timestamp }
                    if sorted.count > 1 {
                        MapPolyline(coordinates: sorted.map { $0.coordinate })
                            .stroke(.red.opacity(0.6), lineWidth: 3)
                    }
                }
            }

            // Destination pins
            ForEach(trips) { trip in
                ForEach(trip.destinations) { dest in
                    Marker(dest.name, coordinate: dest.coordinate)
                        .tint(markerColor(for: dest.category))
                }
            }
        }
        .mapStyle(currentMapStyle)
        .ignoresSafeArea(edges: .top)
    }

    private var currentMapStyle: MapStyle {
        switch mapStyle {
        case .standard: return .standard
        case .satellite: return .imagery
        case .hybrid: return .hybrid
        }
    }

    // MARK: - Country Marker

    private func countryMarker(for visit: CountryVisit) -> some View {
        ZStack {
            Circle()
                .fill(colorForCategory(visit.category))
                .frame(width: 32, height: 32)
                .shadow(radius: 3)

            if visit.category == "favorite" {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
            } else if visit.category == "wantToVisit" {
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
            } else {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }

    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "visited": return .blue
        case "wantToVisit": return .orange
        case "favorite": return .red
        default: return .gray
        }
    }

    private func markerColor(for category: String) -> Color {
        switch category {
        case "favorite": return .red
        case "wantToVisit": return .orange
        default: return .blue
        }
    }

    // MARK: - Controls

    private var mapStyleButton: some View {
        Menu {
            ForEach(MapDisplayStyle.allCases, id: \.self) { style in
                Button {
                    mapStyle = style
                } label: {
                    Label(style.rawValue, systemImage: mapStyle == style ? "checkmark" : "")
                }
            }
        } label: {
            Image(systemName: "map")
                .font(.system(size: 16))
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
    }

    private var heatMapToggle: some View {
        Button {
            showingHeatMap.toggle()
        } label: {
            Image(systemName: showingHeatMap ? "flame.fill" : "flame")
                .font(.system(size: 16))
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .foregroundStyle(showingHeatMap ? .orange : .primary)
        }
    }

    private var filterButton: some View {
        Menu {
            Button("All") { filterCategory = "all" }
            Button("Visited") { filterCategory = "visited" }
            Button("Want to Visit") { filterCategory = "wantToVisit" }
            Button("Favorites") { filterCategory = "favorite" }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 16))
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: 20) {
            statItem(count: visitedCount, label: "Visited", color: .blue, icon: "checkmark.circle.fill")
            statItem(count: wantToVisitCount, label: "Bucket List", color: .orange, icon: "star.circle.fill")
            statItem(count: favoriteCount, label: "Favorites", color: .red, icon: "heart.circle.fill")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func statItem(count: Int, label: String, color: Color, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: 18))
            VStack(alignment: .leading, spacing: 1) {
                Text("\(count)")
                    .font(.system(size: 16, weight: .bold))
                Text(label)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Country Picker

struct CountryPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existingVisits: [CountryVisit]

    @State private var searchText = ""
    @State private var selectedCategory = "visited"
    @State private var selectedRegion = "All"

    let categories = [("visited", "Visited"), ("wantToVisit", "Want to Visit"), ("favorite", "Favorite")]

    var filteredCountries: [CountryInfo] {
        var countries = CountryData.countries
        let existingCodes = Set(existingVisits.map { $0.countryCode })
        countries = countries.filter { !existingCodes.contains($0.id) }

        if selectedRegion != "All" {
            countries = countries.filter { $0.region == selectedRegion }
        }
        if !searchText.isEmpty {
            countries = countries.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return countries
    }

    var body: some View {
        NavigationStack {
            List {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.0) { cat in
                        Text(cat.1).tag(cat.0)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        regionChip("All")
                        ForEach(CountryData.regions, id: \.self) { region in
                            regionChip(region)
                        }
                    }
                }
                .listRowBackground(Color.clear)

                ForEach(filteredCountries) { country in
                    Button {
                        addCountry(country)
                    } label: {
                        HStack {
                            Text(flagEmoji(for: country.id))
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text(country.name)
                                    .foregroundStyle(.primary)
                                Text(country.region)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "plus.circle")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search countries")
            .navigationTitle("Add Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func regionChip(_ region: String) -> some View {
        Button {
            selectedRegion = region
        } label: {
            Text(region)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedRegion == region ? Color.blue : Color.gray.opacity(0.2))
                .foregroundStyle(selectedRegion == region ? .white : .primary)
                .clipShape(Capsule())
        }
    }

    private func addCountry(_ country: CountryInfo) {
        let visit = CountryVisit(
            countryName: country.name,
            countryCode: country.id,
            category: selectedCategory,
            firstVisited: selectedCategory == "visited" ? Date() : nil
        )
        modelContext.insert(visit)
        dismiss()
    }

    private func flagEmoji(for countryCode: String) -> String {
        let base: UInt32 = 127397
        var emoji = ""
        for scalar in countryCode.uppercased().unicodeScalars {
            if let unicode = Unicode.Scalar(base + scalar.value) {
                emoji.append(String(unicode))
            }
        }
        return emoji
    }
}

// MARK: - Country Detail Sheet

struct CountryDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let country: CountryVisit

    @State private var notes: String
    @State private var category: String
    @State private var visitCount: Int

    init(country: CountryVisit) {
        self.country = country
        _notes = State(initialValue: country.notes)
        _category = State(initialValue: country.category)
        _visitCount = State(initialValue: country.visitCount)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(flagEmoji(for: country.countryCode))
                            .font(.system(size: 60))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(country.countryName)
                                .font(.title2.bold())
                            if let first = country.firstVisited {
                                Text("First visited: \(first, style: .date)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Status") {
                    Picker("Category", selection: $category) {
                        Text("Visited").tag("visited")
                        Text("Want to Visit").tag("wantToVisit")
                        Text("Favorite").tag("favorite")
                    }
                    .onChange(of: category) { _, newValue in
                        country.category = newValue
                    }

                    if category != "wantToVisit" {
                        Stepper("Visit count: \(visitCount)", value: $visitCount, in: 1...100)
                            .onChange(of: visitCount) { _, newValue in
                                country.visitCount = newValue
                            }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .onChange(of: notes) { _, newValue in
                            country.notes = newValue
                        }
                }

                Section {
                    Button("Remove Country", role: .destructive) {
                        modelContext.delete(country)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Country Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func flagEmoji(for countryCode: String) -> String {
        let base: UInt32 = 127397
        var emoji = ""
        for scalar in countryCode.uppercased().unicodeScalars {
            if let unicode = Unicode.Scalar(base + scalar.value) {
                emoji.append(String(unicode))
            }
        }
        return emoji
    }
}
