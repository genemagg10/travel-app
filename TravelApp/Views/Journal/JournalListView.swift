import SwiftUI
import SwiftData
import PhotosUI

struct JournalListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var allEntries: [JournalEntry]
    @Query(sort: \Trip.startDate, order: .reverse) private var trips: [Trip]

    @State private var showingNewEntry = false
    @State private var showingDailySummary = false
    @State private var selectedTrip: Trip?
    @State private var searchText = ""

    var filteredEntries: [JournalEntry] {
        var entries = allEntries
        if let trip = selectedTrip {
            entries = entries.filter { $0.trip?.id == trip.id }
        }
        if !searchText.isEmpty {
            entries = entries.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        return entries
    }

    var body: some View {
        NavigationStack {
            Group {
                if allEntries.isEmpty {
                    emptyState
                } else {
                    journalList
                }
            }
            .navigationTitle("Travel Journal")
            .searchable(text: $searchText, prompt: "Search entries")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("New Entry", systemImage: "square.and.pencil") {
                            showingNewEntry = true
                        }
                        Button("Daily Summary", systemImage: "sun.horizon.fill") {
                            showingDailySummary = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingNewEntry) {
                JournalEntryEditorView(trips: trips)
            }
            .sheet(isPresented: $showingDailySummary) {
                DailySummaryView(trips: trips)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Journal Entries", systemImage: "book.closed")
        } description: {
            Text("Record your travel memories, thoughts, and daily summaries here.")
        } actions: {
            Button("Write First Entry") {
                showingNewEntry = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var journalList: some View {
        List {
            // Trip filter
            if trips.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        tripChip(nil, label: "All")
                        ForEach(trips) { trip in
                            tripChip(trip, label: trip.name)
                        }
                    }
                }
                .listRowBackground(Color.clear)
            }

            ForEach(filteredEntries) { entry in
                NavigationLink(destination: JournalEntryDetailView(entry: entry)) {
                    JournalEntryRow(entry: entry)
                }
            }
            .onDelete(perform: deleteEntries)
        }
    }

    private func tripChip(_ trip: Trip?, label: String) -> some View {
        Button {
            selectedTrip = trip
        } label: {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedTrip?.id == trip?.id ? Color.blue : Color.gray.opacity(0.2))
                .foregroundStyle(selectedTrip?.id == trip?.id ? .white : .primary)
                .clipShape(Capsule())
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredEntries[index])
        }
    }
}

// MARK: - Journal Entry Row

struct JournalEntryRow: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if entry.isDailySummary {
                    Label("Summary", systemImage: "sun.horizon.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }

                Text(moodEmoji(entry.mood))
                    .font(.title3)
            }

            Text(entry.title)
                .font(.headline)
                .lineLimit(1)

            if !entry.content.isEmpty {
                Text(entry.content)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 12) {
                if !entry.locationName.isEmpty {
                    Label(entry.locationName, systemImage: "mappin")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                if entry.stepCount > 0 {
                    Label("\(entry.stepCount)", systemImage: "figure.walk")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }

                if !entry.photos.isEmpty {
                    Label("\(entry.photos.count)", systemImage: "photo")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
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
}

// MARK: - Journal Entry Editor

struct JournalEntryEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let trips: [Trip]

    @State private var title = ""
    @State private var content = ""
    @State private var mood = "good"
    @State private var weatherNote = ""
    @State private var locationName = ""
    @State private var selectedTrip: Trip?
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoData: [Data] = []

    let moods = [("great", "😄"), ("good", "🙂"), ("okay", "😐"), ("tired", "😴"), ("rough", "😓")]

    var body: some View {
        NavigationStack {
            Form {
                Section("Entry") {
                    TextField("Title", text: $title)
                    TextEditor(text: $content)
                        .frame(minHeight: 150)
                }

                Section("How are you feeling?") {
                    HStack(spacing: 16) {
                        ForEach(moods, id: \.0) { m in
                            Button {
                                mood = m.0
                            } label: {
                                VStack(spacing: 4) {
                                    Text(m.1)
                                        .font(.title)
                                    Text(m.0.capitalized)
                                        .font(.caption2)
                                }
                                .padding(8)
                                .background(mood == m.0 ? Color.blue.opacity(0.15) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Details") {
                    if !trips.isEmpty {
                        Picker("Trip", selection: $selectedTrip) {
                            Text("None").tag(nil as Trip?)
                            ForEach(trips) { trip in
                                Text(trip.name).tag(trip as Trip?)
                            }
                        }
                    }

                    TextField("Location", text: $locationName)
                    TextField("Weather", text: $weatherNote)
                }

                Section("Photos") {
                    PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 10, matching: .images) {
                        Label("Add Photos", systemImage: "photo.badge.plus")
                    }
                    .onChange(of: selectedPhotos) { _, newItems in
                        loadPhotos(from: newItems)
                    }

                    if !photoData.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(photoData.indices, id: \.self) { index in
                                    if let uiImage = UIImage(data: photoData[index]) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveEntry() }
                        .disabled(title.isEmpty)
                        .bold()
                }
            }
        }
    }

    private func loadPhotos(from items: [PhotosPickerItem]) {
        photoData.removeAll()
        for item in items {
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        photoData.append(data)
                    }
                }
            }
        }
    }

    private func saveEntry() {
        let entry = JournalEntry(
            title: title,
            content: content,
            mood: mood,
            weatherNote: weatherNote,
            locationName: locationName
        )

        if let trip = selectedTrip {
            entry.trip = trip
            trip.journalEntries.append(entry)
        }

        // Save photos
        for data in photoData {
            let photo = TravelPhoto(caption: "", dateTaken: Date())
            photo.imageData = data
            photo.journalEntry = entry
            entry.photos.append(photo)
        }

        modelContext.insert(entry)
        dismiss()
    }
}

// MARK: - Journal Entry Detail

struct JournalEntryDetailView: View {
    @Bindable var entry: JournalEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.date, style: .date)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if !entry.locationName.isEmpty {
                            Label(entry.locationName, systemImage: "mappin.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }

                    Spacer()

                    Text(moodEmoji(entry.mood))
                        .font(.largeTitle)
                }

                Text(entry.title)
                    .font(.title.bold())

                // Photos
                if !entry.photos.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(entry.photos) { photo in
                                if let data = photo.imageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 200, height: 150)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }
                }

                // Content
                Text(entry.content)
                    .font(.body)
                    .lineSpacing(6)

                Divider()

                // Stats
                if entry.isDailySummary {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Today's Stats")
                            .font(.headline)

                        HStack(spacing: 20) {
                            statBadge(value: "\(entry.stepCount)", label: "Steps", icon: "figure.walk", color: .blue)
                            if entry.distanceWalked > 0 {
                                statBadge(
                                    value: String(format: "%.1f mi", entry.distanceWalked / 1609.344),
                                    label: "Distance",
                                    icon: "ruler",
                                    color: .green
                                )
                            }
                        }
                    }
                }

                if !entry.weatherNote.isEmpty {
                    Label(entry.weatherNote, systemImage: "cloud.sun.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func statBadge(value: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            VStack(alignment: .leading) {
                Text(value)
                    .font(.headline)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
}

// MARK: - Daily Summary (Day One Style)

struct DailySummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let trips: [Trip]

    @State private var healthService = HealthService()
    @State private var title = ""
    @State private var highlights = ""
    @State private var mood = "good"
    @State private var weatherNote = ""
    @State private var locationName = ""
    @State private var selectedTrip: Trip?
    @State private var gratitude = ""

    let moods = [("great", "😄"), ("good", "🙂"), ("okay", "😐"), ("tired", "😴"), ("rough", "😓")]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "sun.horizon.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.orange)
                        Text("End of Day Summary")
                            .font(.title3.bold())
                        Text(Date(), style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                }

                Section("How was your day?") {
                    HStack(spacing: 14) {
                        ForEach(moods, id: \.0) { m in
                            Button {
                                mood = m.0
                            } label: {
                                VStack(spacing: 4) {
                                    Text(m.1).font(.title2)
                                    Text(m.0.capitalized).font(.caption2)
                                }
                                .padding(6)
                                .background(mood == m.0 ? Color.blue.opacity(0.15) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Summary") {
                    TextField("Title for today", text: $title)
                    TextEditor(text: $highlights)
                        .frame(minHeight: 100)
                        .overlay(alignment: .topLeading) {
                            if highlights.isEmpty {
                                Text("What were the highlights of your day?")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                            }
                        }
                }

                Section("Gratitude") {
                    TextEditor(text: $gratitude)
                        .frame(minHeight: 60)
                        .overlay(alignment: .topLeading) {
                            if gratitude.isEmpty {
                                Text("What are you grateful for today?")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                            }
                        }
                }

                Section("Details") {
                    if !trips.isEmpty {
                        Picker("Trip", selection: $selectedTrip) {
                            Text("None").tag(nil as Trip?)
                            ForEach(trips) { trip in
                                Text(trip.name).tag(trip as Trip?)
                            }
                        }
                    }
                    TextField("Location", text: $locationName)
                    TextField("Weather", text: $weatherNote)
                }

                Section("Today's Activity") {
                    HStack(spacing: 20) {
                        VStack {
                            Image(systemName: "figure.walk")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            Text("\(healthService.todaySteps)")
                                .font(.headline)
                            Text("Steps")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        VStack {
                            Image(systemName: "ruler")
                                .font(.title2)
                                .foregroundStyle(.green)
                            Text(healthService.distanceString(healthService.todayDistance))
                                .font(.headline)
                            Text("Distance")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    Button("Refresh Health Data") {
                        Task { await healthService.fetchTodayData() }
                    }
                }
            }
            .navigationTitle("Daily Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveSummary() }
                        .bold()
                }
            }
            .task {
                await healthService.requestAuthorization()
            }
        }
    }

    private func saveSummary() {
        var fullContent = highlights
        if !gratitude.isEmpty {
            fullContent += "\n\nGratitude:\n\(gratitude)"
        }

        let entry = JournalEntry(
            title: title.isEmpty ? "Day Summary - \(Date().formatted(.dateTime.month().day()))" : title,
            content: fullContent,
            mood: mood,
            weatherNote: weatherNote,
            locationName: locationName,
            stepCount: healthService.todaySteps,
            distanceWalked: healthService.todayDistance,
            isDailySummary: true
        )

        if let trip = selectedTrip {
            entry.trip = trip
            trip.journalEntries.append(entry)
        }

        modelContext.insert(entry)
        dismiss()
    }
}
