import SwiftUI
import SwiftData

struct TripsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trip.startDate, order: .reverse) private var trips: [Trip]
    @State private var showingNewTrip = false
    @State private var selectedFilter: TripFilter = .all

    enum TripFilter: String, CaseIterable {
        case all = "All"
        case upcoming = "Upcoming"
        case active = "Active"
        case completed = "Completed"
    }

    var filteredTrips: [Trip] {
        switch selectedFilter {
        case .all: return trips
        case .upcoming: return trips.filter { $0.isUpcoming }
        case .active: return trips.filter { $0.isActive }
        case .completed: return trips.filter { $0.isCompleted }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if trips.isEmpty {
                    emptyState
                } else {
                    tripsList
                }
            }
            .navigationTitle("My Trips")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewTrip = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingNewTrip) {
                NewTripView()
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Trips Yet", systemImage: "suitcase")
        } description: {
            Text("Start planning your next adventure by tapping the + button.")
        } actions: {
            Button("Plan a Trip") {
                showingNewTrip = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var tripsList: some View {
        List {
            // Filter picker
            Picker("Filter", selection: $selectedFilter) {
                ForEach(TripFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)

            ForEach(filteredTrips) { trip in
                NavigationLink(destination: TripDetailView(trip: trip)) {
                    TripRowView(trip: trip)
                }
            }
            .onDelete(perform: deleteTrips)
        }
    }

    private func deleteTrips(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredTrips[index])
        }
    }
}

// MARK: - Trip Row

struct TripRowView: View {
    let trip: Trip

    var body: some View {
        HStack(spacing: 14) {
            // Cover image or placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(statusGradient)
                    .frame(width: 60, height: 60)

                if let data = trip.coverPhotoData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: statusIcon)
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(trip.name)
                    .font(.headline)

                Text(trip.formattedDateRange)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Label("\(trip.destinations.count)", systemImage: "mappin")
                    Label("\(trip.duration)d", systemImage: "calendar")
                    if trip.rating > 0 {
                        HStack(spacing: 2) {
                            ForEach(0..<trip.rating, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer()

            statusBadge
        }
        .padding(.vertical, 4)
    }

    private var statusGradient: LinearGradient {
        switch trip.status {
        case "active":
            return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "completed":
            return LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var statusIcon: String {
        switch trip.status {
        case "active": return "airplane"
        case "completed": return "checkmark.seal.fill"
        default: return "calendar.badge.clock"
        }
    }

    private var statusBadge: some View {
        Text(trip.status.capitalized)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.15))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch trip.status {
        case "active": return .green
        case "completed": return .blue
        default: return .orange
        }
    }
}

// MARK: - New Trip

struct NewTripView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
    @State private var status = "planned"

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Details") {
                    TextField("Trip Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Dates") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                }

                Section("Status") {
                    Picker("Status", selection: $status) {
                        Text("Planned").tag("planned")
                        Text("Active").tag("active")
                        Text("Completed").tag("completed")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        createTrip()
                    }
                    .disabled(name.isEmpty)
                    .bold()
                }
            }
        }
    }

    private func createTrip() {
        let trip = Trip(
            name: name,
            tripDescription: description,
            startDate: startDate,
            endDate: endDate,
            status: status
        )
        modelContext.insert(trip)
        dismiss()
    }
}
