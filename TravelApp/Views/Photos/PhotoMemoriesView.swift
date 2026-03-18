import SwiftUI
import SwiftData
import Photos

struct PhotoMemoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trip.startDate, order: .reverse) private var trips: [Trip]
    @Query(sort: \TravelPhoto.dateTaken, order: .reverse) private var allPhotos: [TravelPhoto]

    @State private var photoService = PhotoService()
    @State private var selectedTrip: Trip?
    @State private var viewMode: ViewMode = .grid
    @State private var devicePhotos: [PHAsset] = []
    @State private var showingPhotoDetail = false
    @State private var selectedPhoto: TravelPhoto?

    enum ViewMode: String, CaseIterable {
        case grid = "Grid"
        case timeline = "Timeline"
        case map = "Map"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // View mode picker
                Picker("View", selection: $viewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch viewMode {
                case .grid:
                    gridView
                case .timeline:
                    timelineView
                case .map:
                    mapView
                }
            }
            .navigationTitle("Memories")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Import from Camera Roll", systemImage: "photo.badge.plus") {
                            Task { await importFromCameraRoll() }
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
    }

    // MARK: - Grid View

    private var gridView: some View {
        ScrollView {
            // Trip filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    chipButton(nil, label: "All")
                    ForEach(trips) { trip in
                        chipButton(trip, label: trip.name)
                    }
                }
                .padding(.horizontal)
            }

            let photos = filteredPhotos
            if photos.isEmpty {
                ContentUnavailableView(
                    "No Photos",
                    systemImage: "photo.on.rectangle",
                    description: Text("Photos from your trips will appear here. Add photos through journal entries or import from your camera roll.")
                )
                .frame(height: 300)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 3)], spacing: 3) {
                    ForEach(photos) { photo in
                        photoThumbnail(photo)
                            .onTapGesture {
                                selectedPhoto = photo
                                showingPhotoDetail = true
                            }
                    }
                }
                .padding(3)
            }
        }
        .sheet(isPresented: $showingPhotoDetail) {
            if let photo = selectedPhoto {
                PhotoDetailView(photo: photo)
            }
        }
    }

    // MARK: - Timeline View

    private var timelineView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                let grouped = Dictionary(grouping: filteredPhotos) { photo in
                    Calendar.current.startOfDay(for: photo.dateTaken)
                }
                let sortedDates = grouped.keys.sorted(by: >)

                ForEach(sortedDates, id: \.self) { date in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(date, style: .date)
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top, 16)

                        if let locationName = grouped[date]?.first?.locationName, !locationName.isEmpty {
                            Label(locationName, systemImage: "mappin")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(grouped[date] ?? []) { photo in
                                    photoThumbnail(photo)
                                        .frame(width: 150, height: 150)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Map View

    private var mapView: some View {
        PhotoMapView(photos: filteredPhotos.filter { $0.latitude != nil && $0.longitude != nil })
    }

    // MARK: - Helpers

    private var filteredPhotos: [TravelPhoto] {
        if let trip = selectedTrip {
            return allPhotos.filter { $0.trip?.id == trip.id }
        }
        return allPhotos
    }

    private func photoThumbnail(_ photo: TravelPhoto) -> some View {
        Group {
            if let data = photo.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 100, maxHeight: 100)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(minHeight: 100)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.gray)
                    }
            }
        }
    }

    private func chipButton(_ trip: Trip?, label: String) -> some View {
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

    private func importFromCameraRoll() async {
        await photoService.requestAuthorization()
        // The PhotosPicker in journal entries handles the actual import
    }
}

// MARK: - Photo Detail

struct PhotoDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var photo: TravelPhoto

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let data = photo.imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label(photo.dateTaken, style: .date)
                            Spacer()
                            if !photo.locationName.isEmpty {
                                Label(photo.locationName, systemImage: "mappin")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        TextField("Add a caption...", text: $photo.caption, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Photo Map View

import MapKit

struct PhotoMapView: View {
    let photos: [TravelPhoto]

    var body: some View {
        Map {
            ForEach(photos) { photo in
                if let lat = photo.latitude, let lon = photo.longitude {
                    Annotation(photo.caption.isEmpty ? "Photo" : photo.caption,
                              coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                        ZStack {
                            Circle()
                                .fill(.blue)
                                .frame(width: 30, height: 30)
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
        }
    }
}
