import Foundation
import SwiftData
import CoreLocation

// MARK: - Trip

@Model
final class Trip {
    var id: UUID
    var name: String
    var tripDescription: String
    var startDate: Date
    var endDate: Date
    var coverPhotoData: Data?
    var status: String // planned, active, completed
    var rating: Int // 0-5 stars

    @Relationship(deleteRule: .cascade) var destinations: [Destination]
    @Relationship(deleteRule: .cascade) var journalEntries: [JournalEntry]
    @Relationship(deleteRule: .cascade) var itineraryDays: [ItineraryDay]
    @Relationship(deleteRule: .cascade) var photos: [TravelPhoto]
    @Relationship(deleteRule: .cascade) var trackPoints: [GPSTrackPoint]

    var isUpcoming: Bool { startDate > Date() }
    var isActive: Bool { startDate <= Date() && endDate >= Date() }
    var isCompleted: Bool { endDate < Date() }

    var duration: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }

    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: startDate)) – \(formatter.string(from: endDate))"
    }

    init(
        name: String,
        tripDescription: String = "",
        startDate: Date,
        endDate: Date,
        status: String = "planned",
        rating: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.tripDescription = tripDescription
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.rating = rating
        self.destinations = []
        self.journalEntries = []
        self.itineraryDays = []
        self.photos = []
        self.trackPoints = []
    }
}

// MARK: - Destination

@Model
final class Destination {
    var id: UUID
    var name: String
    var country: String
    var countryCode: String
    var latitude: Double
    var longitude: Double
    var arrivalDate: Date?
    var departureDate: Date?
    var notes: String
    var category: String // visited, wantToVisit, favorite

    var trip: Trip?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(
        name: String,
        country: String,
        countryCode: String = "",
        latitude: Double,
        longitude: Double,
        notes: String = "",
        category: String = "visited"
    ) {
        self.id = UUID()
        self.name = name
        self.country = country
        self.countryCode = countryCode
        self.latitude = latitude
        self.longitude = longitude
        self.notes = notes
        self.category = category
    }
}

// MARK: - Journal Entry

@Model
final class JournalEntry {
    var id: UUID
    var title: String
    var content: String
    var date: Date
    var mood: String // great, good, okay, tired, rough
    var weatherNote: String
    var latitude: Double?
    var longitude: Double?
    var locationName: String
    var stepCount: Int
    var distanceWalked: Double // in meters
    var isDailySummary: Bool

    var trip: Trip?
    @Relationship(deleteRule: .cascade) var photos: [TravelPhoto]

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    init(
        title: String,
        content: String = "",
        date: Date = Date(),
        mood: String = "good",
        weatherNote: String = "",
        locationName: String = "",
        stepCount: Int = 0,
        distanceWalked: Double = 0,
        isDailySummary: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.date = date
        self.mood = mood
        self.weatherNote = weatherNote
        self.locationName = locationName
        self.stepCount = stepCount
        self.distanceWalked = distanceWalked
        self.isDailySummary = isDailySummary
        self.photos = []
    }
}

// MARK: - Itinerary Day

@Model
final class ItineraryDay {
    var id: UUID
    var date: Date
    var dayNumber: Int
    var notes: String

    var trip: Trip?
    @Relationship(deleteRule: .cascade) var activities: [Activity]

    init(date: Date, dayNumber: Int, notes: String = "") {
        self.id = UUID()
        self.date = date
        self.dayNumber = dayNumber
        self.notes = notes
        self.activities = []
    }
}

// MARK: - Activity

@Model
final class Activity {
    var id: UUID
    var name: String
    var activityDescription: String
    var startTime: Date
    var endTime: Date?
    var locationName: String
    var address: String
    var latitude: Double?
    var longitude: Double?
    var category: String // sightseeing, food, transport, accommodation, entertainment, shopping, other
    var isCompleted: Bool
    var cost: Double
    var currency: String
    var bookingReference: String
    var notes: String

    var itineraryDay: ItineraryDay?

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        var result = formatter.string(from: startTime)
        if let end = endTime {
            result += " – \(formatter.string(from: end))"
        }
        return result
    }

    var categoryIcon: String {
        switch category {
        case "sightseeing": return "binoculars.fill"
        case "food": return "fork.knife"
        case "transport": return "car.fill"
        case "accommodation": return "bed.double.fill"
        case "entertainment": return "theatermasks.fill"
        case "shopping": return "bag.fill"
        default: return "mappin.circle.fill"
        }
    }

    var categoryColor: String {
        switch category {
        case "sightseeing": return "blue"
        case "food": return "orange"
        case "transport": return "green"
        case "accommodation": return "purple"
        case "entertainment": return "pink"
        case "shopping": return "yellow"
        default: return "gray"
        }
    }

    init(
        name: String,
        activityDescription: String = "",
        startTime: Date,
        endTime: Date? = nil,
        locationName: String = "",
        address: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        category: String = "other",
        cost: Double = 0,
        currency: String = "USD",
        bookingReference: String = "",
        notes: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.activityDescription = activityDescription
        self.startTime = startTime
        self.endTime = endTime
        self.locationName = locationName
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.category = category
        self.isCompleted = false
        self.cost = cost
        self.currency = currency
        self.bookingReference = bookingReference
        self.notes = notes
    }
}

// MARK: - Travel Photo

@Model
final class TravelPhoto {
    var id: UUID
    var imageData: Data?
    var assetIdentifier: String? // PHAsset local identifier
    var caption: String
    var dateTaken: Date
    var latitude: Double?
    var longitude: Double?
    var locationName: String

    var trip: Trip?
    var journalEntry: JournalEntry?

    init(
        caption: String = "",
        dateTaken: Date = Date(),
        latitude: Double? = nil,
        longitude: Double? = nil,
        locationName: String = "",
        assetIdentifier: String? = nil
    ) {
        self.id = UUID()
        self.caption = caption
        self.dateTaken = dateTaken
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
        self.assetIdentifier = assetIdentifier
    }
}

// MARK: - GPS Track Point

@Model
final class GPSTrackPoint {
    var id: UUID
    var latitude: Double
    var longitude: Double
    var altitude: Double
    var timestamp: Date
    var speed: Double // m/s
    var course: Double // degrees

    var trip: Trip?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(
        latitude: Double,
        longitude: Double,
        altitude: Double = 0,
        timestamp: Date = Date(),
        speed: Double = 0,
        course: Double = 0
    ) {
        self.id = UUID()
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.timestamp = timestamp
        self.speed = speed
        self.course = course
    }
}

// MARK: - Country Visit

@Model
final class CountryVisit {
    var id: UUID
    var countryName: String
    var countryCode: String
    var category: String // visited, wantToVisit, favorite
    var firstVisited: Date?
    var lastVisited: Date?
    var visitCount: Int
    var notes: String

    init(
        countryName: String,
        countryCode: String,
        category: String = "visited",
        firstVisited: Date? = nil,
        visitCount: Int = 1
    ) {
        self.id = UUID()
        self.countryName = countryName
        self.countryCode = countryCode
        self.category = category
        self.firstVisited = firstVisited
        self.lastVisited = firstVisited
        self.visitCount = visitCount
        self.notes = ""
    }
}
