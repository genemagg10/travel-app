import Foundation
import SwiftData

struct SampleDataService {
    static func createNYCTrip(in context: ModelContext) {
        // Create the NYC trip - upcoming trip
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: 7, to: Date())!
        let endDate = calendar.date(byAdding: .day, value: 12, to: Date())!

        let trip = Trip(
            name: "New York City Adventure",
            tripDescription: "Exploring the Big Apple! Museums, food, Broadway, and all the iconic landmarks. Can't wait to walk through Central Park and see the city skyline.",
            startDate: startDate,
            endDate: endDate,
            status: "planned"
        )
        context.insert(trip)

        // Destinations
        let destinations: [(String, String, String, Double, Double)] = [
            ("Times Square", "United States", "US", 40.7580, -73.9855),
            ("Central Park", "United States", "US", 40.7829, -73.9654),
            ("Statue of Liberty", "United States", "US", 40.6892, -74.0445),
            ("Brooklyn Bridge", "United States", "US", 40.7061, -73.9969),
            ("Empire State Building", "United States", "US", 40.7484, -73.9857),
            ("Metropolitan Museum of Art", "United States", "US", 40.7794, -73.9632),
            ("One World Observatory", "United States", "US", 40.7127, -74.0134),
        ]

        for (name, country, code, lat, lon) in destinations {
            let dest = Destination(name: name, country: country, countryCode: code, latitude: lat, longitude: lon)
            dest.trip = trip
            trip.destinations.append(dest)
        }

        // Create itinerary days
        for dayOffset in 0...5 {
            let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate)!
            let day = ItineraryDay(date: date, dayNumber: dayOffset + 1)
            day.trip = trip
            trip.itineraryDays.append(day)

            // Add activities for each day
            switch dayOffset {
            case 0: // Day 1 - Arrival & Midtown
                addActivities(to: day, date: date, activities: [
                    ("Arrive at JFK Airport", "transport", "JFK Airport", "JFK Airport, Queens, NY", 40.6413, -73.7781, 14, 0),
                    ("Check into Hotel", "accommodation", "The Manhattan Hotel", "Times Square area", 40.7580, -73.9855, 16, 0),
                    ("Walk around Times Square", "sightseeing", "Times Square", "Broadway & 7th Ave", 40.7580, -73.9855, 17, 30),
                    ("Dinner at Joe's Pizza", "food", "Joe's Pizza", "7 Carmine St, Greenwich Village", 40.7306, -74.0023, 19, 0),
                    ("Broadway Show", "entertainment", "Broadway Theatre", "1681 Broadway", 40.7630, -73.9836, 20, 0),
                ])

            case 1: // Day 2 - Iconic Landmarks
                addActivities(to: day, date: date, activities: [
                    ("Empire State Building", "sightseeing", "Empire State Building", "20 W 34th St", 40.7484, -73.9857, 9, 0),
                    ("Lunch at Katz's Delicatessen", "food", "Katz's Deli", "205 E Houston St", 40.7223, -73.9874, 12, 0),
                    ("Brooklyn Bridge Walk", "sightseeing", "Brooklyn Bridge", "Brooklyn Bridge, NY", 40.7061, -73.9969, 14, 0),
                    ("DUMBO Exploration", "sightseeing", "DUMBO", "Water St, Brooklyn", 40.7033, -73.9894, 15, 30),
                    ("Dinner in Brooklyn", "food", "Juliana's Pizza", "19 Old Fulton St, Brooklyn", 40.7026, -73.9934, 18, 30),
                ])

            case 2: // Day 3 - Culture & Museums
                addActivities(to: day, date: date, activities: [
                    ("Metropolitan Museum of Art", "sightseeing", "The Met", "1000 5th Ave", 40.7794, -73.9632, 9, 30),
                    ("Lunch at Museum Café", "food", "The Met Café", "Inside The Met", 40.7794, -73.9632, 12, 30),
                    ("Central Park Walk", "sightseeing", "Central Park", "Central Park", 40.7829, -73.9654, 14, 0),
                    ("Guggenheim Museum", "sightseeing", "Guggenheim", "1071 5th Ave", 40.7830, -73.9590, 16, 0),
                    ("Dinner at Upper West Side", "food", "Jacob's Pickles", "509 Amsterdam Ave", 40.7870, -73.9748, 19, 0),
                ])

            case 3: // Day 4 - Downtown & Liberty
                addActivities(to: day, date: date, activities: [
                    ("Statue of Liberty Ferry", "transport", "Battery Park", "Battery Park, Manhattan", 40.7033, -74.0170, 8, 30),
                    ("Statue of Liberty Visit", "sightseeing", "Statue of Liberty", "Liberty Island", 40.6892, -74.0445, 9, 30),
                    ("Ellis Island", "sightseeing", "Ellis Island", "Ellis Island", 40.6995, -74.0396, 11, 0),
                    ("One World Observatory", "sightseeing", "One World Trade Center", "285 Fulton St", 40.7127, -74.0134, 14, 0),
                    ("9/11 Memorial", "sightseeing", "9/11 Memorial", "180 Greenwich St", 40.7115, -74.0134, 15, 30),
                    ("Dinner in Tribeca", "food", "Bubby's", "120 Hudson St, Tribeca", 40.7196, -74.0090, 18, 30),
                ])

            case 4: // Day 5 - Neighborhoods & Food
                addActivities(to: day, date: date, activities: [
                    ("Chelsea Market", "shopping", "Chelsea Market", "75 9th Ave", 40.7424, -74.0061, 10, 0),
                    ("High Line Walk", "sightseeing", "The High Line", "High Line Park", 40.7480, -74.0048, 11, 30),
                    ("Lunch in Greenwich Village", "food", "Bleecker Street Pizza", "69 7th Ave S", 40.7323, -74.0030, 13, 0),
                    ("Washington Square Park", "sightseeing", "Washington Square Park", "Washington Square", 40.7308, -73.9973, 14, 0),
                    ("SoHo Shopping", "shopping", "SoHo", "Broadway & Spring St", 40.7233, -73.9988, 15, 30),
                    ("Little Italy & Chinatown", "sightseeing", "Little Italy", "Mulberry St", 40.7191, -73.9973, 17, 0),
                    ("Farewell Dinner at Peter Luger", "food", "Peter Luger Steak House", "178 Broadway, Brooklyn", 40.7098, -73.9627, 19, 30),
                ])

            case 5: // Day 6 - Departure
                addActivities(to: day, date: date, activities: [
                    ("Breakfast at Hotel", "food", "Hotel Restaurant", "Times Square area", 40.7580, -73.9855, 8, 0),
                    ("Last minute shopping", "shopping", "Fifth Avenue", "5th Ave", 40.7547, -73.9818, 9, 30),
                    ("Head to Airport", "transport", "JFK Airport", "JFK Airport, Queens, NY", 40.6413, -73.7781, 12, 0),
                ])

            default:
                break
            }
        }

        // Add some country visits for the world map
        let countryVisits: [(String, String, String, Date?)] = [
            ("United States", "US", "visited", calendar.date(byAdding: .year, value: -10, to: Date())),
            ("United Kingdom", "GB", "visited", calendar.date(byAdding: .year, value: -3, to: Date())),
            ("France", "FR", "visited", calendar.date(byAdding: .year, value: -2, to: Date())),
            ("Italy", "IT", "favorite", calendar.date(byAdding: .year, value: -1, to: Date())),
            ("Japan", "JP", "visited", calendar.date(byAdding: .month, value: -6, to: Date())),
            ("Mexico", "MX", "visited", calendar.date(byAdding: .year, value: -4, to: Date())),
            ("Canada", "CA", "visited", calendar.date(byAdding: .year, value: -5, to: Date())),
            ("Spain", "ES", "wantToVisit", nil),
            ("Greece", "GR", "wantToVisit", nil),
            ("Thailand", "TH", "wantToVisit", nil),
            ("Australia", "AU", "wantToVisit", nil),
            ("Iceland", "IS", "favorite", nil),
            ("New Zealand", "NZ", "wantToVisit", nil),
        ]

        for (name, code, category, date) in countryVisits {
            let visit = CountryVisit(
                countryName: name,
                countryCode: code,
                category: category,
                firstVisited: date
            )
            context.insert(visit)
        }

        // Add a completed past trip for stats
        let pastStart = calendar.date(byAdding: .month, value: -6, to: Date())!
        let pastEnd = calendar.date(byAdding: .day, value: 10, to: pastStart)!
        let pastTrip = Trip(
            name: "Tokyo & Kyoto",
            tripDescription: "Amazing trip through Japan - temples, food, and culture.",
            startDate: pastStart,
            endDate: pastEnd,
            status: "completed",
            rating: 5
        )
        context.insert(pastTrip)

        let tokyoDest = Destination(name: "Tokyo", country: "Japan", countryCode: "JP", latitude: 35.6762, longitude: 139.6503)
        tokyoDest.trip = pastTrip
        pastTrip.destinations.append(tokyoDest)

        let kyotoDest = Destination(name: "Kyoto", country: "Japan", countryCode: "JP", latitude: 35.0116, longitude: 135.7681)
        kyotoDest.trip = pastTrip
        pastTrip.destinations.append(kyotoDest)

        // Add journal entries for the past trip
        let journalEntries = [
            ("Arrived in Tokyo!", "The city is incredible. Shibuya crossing was mind-blowing. The energy here is unlike anything I've ever experienced.", "great", 12500, 8.2),
            ("Tsukiji & Akihabara", "Started with the best sushi of my life at the outer market. Spent afternoon exploring the electric town.", "great", 18000, 11.3),
            ("Day trip to Kamakura", "The Great Buddha was serene. Beautiful coastal town. Found a hidden temple garden that was pure peace.", "good", 15000, 9.7),
            ("Bullet train to Kyoto", "The shinkansen was so smooth. Kyoto feels like stepping back in time. Checked into a traditional ryokan.", "good", 8000, 5.1),
            ("Temples of Kyoto", "Fushimi Inari's thousand gates were magical at sunrise. Kinkaku-ji golden pavilion shining in the afternoon sun.", "great", 22000, 14.5),
        ]

        for (i, entry) in journalEntries.enumerated() {
            let date = calendar.date(byAdding: .day, value: i, to: pastStart)!
            let journal = JournalEntry(
                title: entry.0,
                content: entry.1,
                date: date,
                mood: entry.2,
                locationName: i < 3 ? "Tokyo" : "Kyoto",
                stepCount: entry.3,
                distanceWalked: entry.4 * 1609.344,
                isDailySummary: true
            )
            journal.trip = pastTrip
            pastTrip.journalEntries.append(journal)
            context.insert(journal)
        }

        // Another past trip
        let europeStart = calendar.date(byAdding: .year, value: -2, to: Date())!
        let europeEnd = calendar.date(byAdding: .day, value: 14, to: europeStart)!
        let europeTrip = Trip(
            name: "European Adventure",
            tripDescription: "Two weeks across London, Paris, and Rome. Art, food, and history.",
            startDate: europeStart,
            endDate: europeEnd,
            status: "completed",
            rating: 4
        )
        context.insert(europeTrip)

        let londonDest = Destination(name: "London", country: "United Kingdom", countryCode: "GB", latitude: 51.5074, longitude: -0.1278)
        londonDest.trip = europeTrip
        europeTrip.destinations.append(londonDest)

        let parisDest = Destination(name: "Paris", country: "France", countryCode: "FR", latitude: 48.8566, longitude: 2.3522)
        parisDest.trip = europeTrip
        europeTrip.destinations.append(parisDest)

        let romeDest = Destination(name: "Rome", country: "Italy", countryCode: "IT", latitude: 41.9028, longitude: 12.4964)
        romeDest.trip = europeTrip
        europeTrip.destinations.append(romeDest)
    }

    private static func addActivities(
        to day: ItineraryDay,
        date: Date,
        activities: [(String, String, String, String, Double, Double, Int, Int)]
    ) {
        let calendar = Calendar.current
        for activity in activities {
            let time = calendar.date(bySettingHour: activity.6, minute: activity.7, second: 0, of: date)!
            let act = Activity(
                name: activity.0,
                startTime: time,
                locationName: activity.2,
                address: activity.3,
                latitude: activity.4,
                longitude: activity.5,
                category: activity.1
            )
            act.itineraryDay = day
            day.activities.append(act)
        }
    }
}
