import SwiftUI
import MapKit
import SwiftData

struct ItineraryPlannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var trip: Trip

    @State private var showingAddActivity = false
    @State private var selectedDay: ItineraryDay?
    @State private var showingMapForDay = false

    var sortedDays: [ItineraryDay] {
        trip.itineraryDays.sorted { $0.dayNumber < $1.dayNumber }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sortedDays.isEmpty {
                    emptyState
                } else {
                    daysList
                }
            }
            .navigationTitle("Itinerary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Add Day") { addDay() }
                        Button("Generate All Days") { generateAllDays() }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddActivity) {
                if let day = selectedDay {
                    AddActivityView(day: day)
                }
            }
            .sheet(isPresented: $showingMapForDay) {
                if let day = selectedDay {
                    DayMapView(day: day)
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Itinerary Yet", systemImage: "list.bullet.clipboard")
        } description: {
            Text("Plan your trip day by day. Tap + to add days or generate an itinerary for your full trip.")
        } actions: {
            Button("Generate All Days") {
                generateAllDays()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var daysList: some View {
        List {
            ForEach(sortedDays) { day in
                Section {
                    // Day header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Day \(day.dayNumber)")
                                .font(.headline)
                            Text(day.date, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            selectedDay = day
                            showingMapForDay = true
                        } label: {
                            Image(systemName: "map")
                                .font(.body)
                        }

                        Button {
                            selectedDay = day
                            showingAddActivity = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.body)
                        }
                    }

                    // Activities
                    let sortedActivities = day.activities.sorted { $0.startTime < $1.startTime }
                    ForEach(sortedActivities) { activity in
                        ActivityRowView(activity: activity)
                    }
                    .onDelete { offsets in
                        deleteActivities(from: day, at: offsets)
                    }

                    // Day notes
                    if !day.notes.isEmpty {
                        Text(day.notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    }
                }
            }
            .onDelete(perform: deleteDays)
        }
    }

    private func addDay() {
        let dayNumber = (sortedDays.last?.dayNumber ?? 0) + 1
        let date = Calendar.current.date(byAdding: .day, value: dayNumber - 1, to: trip.startDate) ?? Date()
        let day = ItineraryDay(date: date, dayNumber: dayNumber)
        day.trip = trip
        trip.itineraryDays.append(day)
    }

    private func generateAllDays() {
        // Remove existing days
        for day in trip.itineraryDays {
            modelContext.delete(day)
        }
        trip.itineraryDays.removeAll()

        // Generate a day for each day of the trip
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: trip.startDate, to: trip.endDate).day ?? 0

        for i in 0...days {
            let date = calendar.date(byAdding: .day, value: i, to: trip.startDate)!
            let day = ItineraryDay(date: date, dayNumber: i + 1)
            day.trip = trip
            trip.itineraryDays.append(day)
        }
    }

    private func deleteDays(at offsets: IndexSet) {
        for index in offsets {
            let day = sortedDays[index]
            modelContext.delete(day)
        }
    }

    private func deleteActivities(from day: ItineraryDay, at offsets: IndexSet) {
        let sorted = day.activities.sorted { $0.startTime < $1.startTime }
        for index in offsets {
            modelContext.delete(sorted[index])
        }
    }
}

// MARK: - Activity Row

struct ActivityRowView: View {
    @Bindable var activity: Activity

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: activity.categoryIcon)
                .font(.body)
                .foregroundStyle(Color(activityColor))
                .frame(width: 32, height: 32)
                .background(Color(activityColor).opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(activity.name)
                    .font(.subheadline.bold())

                Text(activity.timeString)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !activity.locationName.isEmpty {
                    Label(activity.locationName, systemImage: "mappin")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                if activity.cost > 0 {
                    Text("\(activity.currency) \(activity.cost, specifier: "%.2f")")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            Button {
                activity.isCompleted.toggle()
            } label: {
                Image(systemName: activity.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(activity.isCompleted ? .green : .gray)
                    .font(.title3)
            }
        }
        .padding(.vertical, 4)
    }

    private var activityColor: Color {
        switch activity.categoryColor {
        case "blue": return .blue
        case "orange": return .orange
        case "green": return .green
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        default: return .gray
        }
    }
}

// MARK: - Add Activity

struct AddActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let day: ItineraryDay

    @State private var name = ""
    @State private var description = ""
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var hasEndTime = false
    @State private var locationName = ""
    @State private var address = ""
    @State private var category = "sightseeing"
    @State private var cost: Double = 0
    @State private var currency = "USD"
    @State private var bookingRef = ""
    @State private var notes = ""
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var latitude: Double?
    @State private var longitude: Double?

    let categories = [
        ("sightseeing", "Sightseeing", "binoculars.fill"),
        ("food", "Food & Drink", "fork.knife"),
        ("transport", "Transport", "car.fill"),
        ("accommodation", "Hotel", "bed.double.fill"),
        ("entertainment", "Entertainment", "theatermasks.fill"),
        ("shopping", "Shopping", "bag.fill"),
        ("other", "Other", "mappin.circle.fill")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Activity") {
                    TextField("Activity Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Category") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(categories, id: \.0) { cat in
                                Button {
                                    category = cat.0
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: cat.2)
                                            .font(.title3)
                                        Text(cat.1)
                                            .font(.caption2)
                                    }
                                    .frame(width: 70, height: 60)
                                    .background(category == cat.0 ? Color.blue.opacity(0.15) : Color.gray.opacity(0.08))
                                    .foregroundStyle(category == cat.0 ? .blue : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Time") {
                    DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                    Toggle("Set End Time", isOn: $hasEndTime)
                    if hasEndTime {
                        DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
                    }
                }

                Section("Location") {
                    TextField("Search place...", text: $searchText)
                        .onSubmit { searchPlace() }

                    if !searchResults.isEmpty {
                        ForEach(searchResults, id: \.self) { item in
                            Button {
                                selectPlace(item)
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(item.name ?? "Unknown")
                                        .foregroundStyle(.primary)
                                    if let addr = item.placemark.title {
                                        Text(addr)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }

                    if !locationName.isEmpty {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.red)
                            Text(locationName)
                        }
                    }
                }

                Section("Cost") {
                    HStack {
                        TextField("Currency", text: $currency)
                            .frame(width: 50)
                        TextField("Amount", value: $cost, format: .number)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Additional") {
                    TextField("Booking Reference", text: $bookingRef)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") { addActivity() }
                        .disabled(name.isEmpty)
                        .bold()
                }
            }
        }
    }

    private func searchPlace() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            searchResults = response?.mapItems ?? []
        }
    }

    private func selectPlace(_ item: MKMapItem) {
        locationName = item.name ?? ""
        address = item.placemark.title ?? ""
        latitude = item.placemark.coordinate.latitude
        longitude = item.placemark.coordinate.longitude
        searchResults = []
        searchText = ""
    }

    private func addActivity() {
        // Combine day date with selected time
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let combinedStart = calendar.date(bySettingHour: timeComponents.hour ?? 9,
                                          minute: timeComponents.minute ?? 0,
                                          second: 0, of: day.date) ?? startTime

        var combinedEnd: Date? = nil
        if hasEndTime {
            let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
            combinedEnd = calendar.date(bySettingHour: endComponents.hour ?? 10,
                                        minute: endComponents.minute ?? 0,
                                        second: 0, of: day.date)
        }

        let activity = Activity(
            name: name,
            activityDescription: description,
            startTime: combinedStart,
            endTime: combinedEnd,
            locationName: locationName,
            address: address,
            latitude: latitude,
            longitude: longitude,
            category: category,
            cost: cost,
            currency: currency,
            bookingReference: bookingRef,
            notes: notes
        )
        activity.itineraryDay = day
        day.activities.append(activity)
        dismiss()
    }
}

// MARK: - Day Map View

struct DayMapView: View {
    @Environment(\.dismiss) private var dismiss
    let day: ItineraryDay

    var activitiesWithLocation: [Activity] {
        day.activities.filter { $0.latitude != nil && $0.longitude != nil }
            .sorted { $0.startTime < $1.startTime }
    }

    var body: some View {
        NavigationStack {
            Map {
                ForEach(activitiesWithLocation) { activity in
                    if let coord = activity.coordinate {
                        Marker(activity.name, systemImage: activity.categoryIcon, coordinate: coord)
                            .tint(markerColor(for: activity.category))
                    }
                }

                // Draw route between activities
                if activitiesWithLocation.count > 1 {
                    let coords = activitiesWithLocation.compactMap { $0.coordinate }
                    MapPolyline(coordinates: coords)
                        .stroke(.blue.opacity(0.6), lineWidth: 2)
                }
            }
            .navigationTitle("Day \(day.dayNumber) Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .overlay(alignment: .bottom) {
                if !activitiesWithLocation.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(activitiesWithLocation) { activity in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: activity.categoryIcon)
                                            .foregroundStyle(markerColor(for: activity.category))
                                        Text(activity.name)
                                            .font(.caption.bold())
                                    }
                                    Text(activity.timeString)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }

    private func markerColor(for category: String) -> Color {
        switch category {
        case "sightseeing": return .blue
        case "food": return .orange
        case "transport": return .green
        case "accommodation": return .purple
        case "entertainment": return .pink
        case "shopping": return .yellow
        default: return .gray
        }
    }
}
