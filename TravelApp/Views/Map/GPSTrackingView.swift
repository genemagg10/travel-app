import SwiftUI
import MapKit
import SwiftData

struct GPSTrackingView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var trip: Trip
    @State private var locationService = LocationService()
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    var sortedTrackPoints: [GPSTrackPoint] {
        trip.trackPoints.sorted { $0.timestamp < $1.timestamp }
    }

    var trackingDuration: String {
        guard let first = sortedTrackPoints.first?.timestamp,
              let last = sortedTrackPoints.last?.timestamp else { return "0:00" }
        let interval = last.timeIntervalSince(first)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return String(format: "%d:%02d", hours, minutes)
    }

    var totalDistance: Double {
        guard sortedTrackPoints.count > 1 else { return 0 }
        var total: Double = 0
        for i in 1..<sortedTrackPoints.count {
            let prev = CLLocation(latitude: sortedTrackPoints[i-1].latitude,
                                  longitude: sortedTrackPoints[i-1].longitude)
            let curr = CLLocation(latitude: sortedTrackPoints[i].latitude,
                                  longitude: sortedTrackPoints[i].longitude)
            total += curr.distance(from: prev)
        }
        return total
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $cameraPosition) {
                UserAnnotation()

                if sortedTrackPoints.count > 1 {
                    MapPolyline(coordinates: sortedTrackPoints.map { $0.coordinate })
                        .stroke(.blue, lineWidth: 4)
                }

                if let first = sortedTrackPoints.first {
                    Annotation("Start", coordinate: first.coordinate) {
                        Circle()
                            .fill(.green)
                            .frame(width: 14, height: 14)
                            .overlay {
                                Circle().stroke(.white, lineWidth: 2)
                            }
                    }
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }

            // Controls overlay
            VStack(spacing: 12) {
                // Stats
                HStack(spacing: 20) {
                    VStack {
                        Text(String(format: "%.1f mi", totalDistance / 1609.344))
                            .font(.headline)
                        Text("Distance")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    VStack {
                        Text(trackingDuration)
                            .font(.headline)
                        Text("Duration")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    VStack {
                        Text("\(sortedTrackPoints.count)")
                            .font(.headline)
                        Text("Points")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Track button
                Button {
                    toggleTracking()
                } label: {
                    HStack {
                        Image(systemName: locationService.isTracking ? "stop.circle.fill" : "location.fill")
                        Text(locationService.isTracking ? "Stop Tracking" : "Start Tracking")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(locationService.isTracking ? Color.red : Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding()
        }
        .navigationTitle("GPS Tracking")
        .onAppear {
            locationService.requestPermission()
        }
        .onDisappear {
            if locationService.isTracking {
                saveTrackPoints()
                locationService.stopTracking()
            }
        }
    }

    private func toggleTracking() {
        if locationService.isTracking {
            saveTrackPoints()
            locationService.stopTracking()
        } else {
            locationService.startTracking()
        }
    }

    private func saveTrackPoints() {
        for location in locationService.trackPoints {
            let point = GPSTrackPoint(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                altitude: location.altitude,
                timestamp: location.timestamp,
                speed: location.speed,
                course: location.course
            )
            point.trip = trip
            trip.trackPoints.append(point)
        }
    }
}
