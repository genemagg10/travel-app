import Foundation
import CoreLocation

struct CountryInfo: Identifiable {
    let id: String // ISO 3166-1 alpha-2
    let name: String
    let latitude: Double
    let longitude: Double
    let region: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct CountryData {
    static let countries: [CountryInfo] = [
        // North America
        CountryInfo(id: "US", name: "United States", latitude: 39.8283, longitude: -98.5795, region: "North America"),
        CountryInfo(id: "CA", name: "Canada", latitude: 56.1304, longitude: -106.3468, region: "North America"),
        CountryInfo(id: "MX", name: "Mexico", latitude: 23.6345, longitude: -102.5528, region: "North America"),

        // Central America & Caribbean
        CountryInfo(id: "GT", name: "Guatemala", latitude: 15.7835, longitude: -90.2308, region: "Central America"),
        CountryInfo(id: "BZ", name: "Belize", latitude: 17.1899, longitude: -88.4976, region: "Central America"),
        CountryInfo(id: "HN", name: "Honduras", latitude: 15.1999, longitude: -86.2419, region: "Central America"),
        CountryInfo(id: "SV", name: "El Salvador", latitude: 13.7942, longitude: -88.8965, region: "Central America"),
        CountryInfo(id: "NI", name: "Nicaragua", latitude: 12.8654, longitude: -85.2072, region: "Central America"),
        CountryInfo(id: "CR", name: "Costa Rica", latitude: 9.7489, longitude: -83.7534, region: "Central America"),
        CountryInfo(id: "PA", name: "Panama", latitude: 8.538, longitude: -80.7821, region: "Central America"),
        CountryInfo(id: "CU", name: "Cuba", latitude: 21.5218, longitude: -77.7812, region: "Caribbean"),
        CountryInfo(id: "JM", name: "Jamaica", latitude: 18.1096, longitude: -77.2975, region: "Caribbean"),
        CountryInfo(id: "DO", name: "Dominican Republic", latitude: 18.7357, longitude: -70.1627, region: "Caribbean"),
        CountryInfo(id: "PR", name: "Puerto Rico", latitude: 18.2208, longitude: -66.5901, region: "Caribbean"),
        CountryInfo(id: "BS", name: "Bahamas", latitude: 25.0343, longitude: -77.3963, region: "Caribbean"),

        // South America
        CountryInfo(id: "BR", name: "Brazil", latitude: -14.235, longitude: -51.9253, region: "South America"),
        CountryInfo(id: "AR", name: "Argentina", latitude: -38.4161, longitude: -63.6167, region: "South America"),
        CountryInfo(id: "CL", name: "Chile", latitude: -35.6751, longitude: -71.543, region: "South America"),
        CountryInfo(id: "CO", name: "Colombia", latitude: 4.5709, longitude: -74.2973, region: "South America"),
        CountryInfo(id: "PE", name: "Peru", latitude: -9.19, longitude: -75.0152, region: "South America"),
        CountryInfo(id: "VE", name: "Venezuela", latitude: 6.4238, longitude: -66.5897, region: "South America"),
        CountryInfo(id: "EC", name: "Ecuador", latitude: -1.8312, longitude: -78.1834, region: "South America"),
        CountryInfo(id: "BO", name: "Bolivia", latitude: -16.2902, longitude: -63.5887, region: "South America"),
        CountryInfo(id: "PY", name: "Paraguay", latitude: -23.4425, longitude: -58.4438, region: "South America"),
        CountryInfo(id: "UY", name: "Uruguay", latitude: -32.5228, longitude: -55.7658, region: "South America"),

        // Europe
        CountryInfo(id: "GB", name: "United Kingdom", latitude: 55.3781, longitude: -3.436, region: "Europe"),
        CountryInfo(id: "FR", name: "France", latitude: 46.2276, longitude: 2.2137, region: "Europe"),
        CountryInfo(id: "DE", name: "Germany", latitude: 51.1657, longitude: 10.4515, region: "Europe"),
        CountryInfo(id: "IT", name: "Italy", latitude: 41.8719, longitude: 12.5674, region: "Europe"),
        CountryInfo(id: "ES", name: "Spain", latitude: 40.4637, longitude: -3.7492, region: "Europe"),
        CountryInfo(id: "PT", name: "Portugal", latitude: 39.3999, longitude: -8.2245, region: "Europe"),
        CountryInfo(id: "NL", name: "Netherlands", latitude: 52.1326, longitude: 5.2913, region: "Europe"),
        CountryInfo(id: "BE", name: "Belgium", latitude: 50.5039, longitude: 4.4699, region: "Europe"),
        CountryInfo(id: "CH", name: "Switzerland", latitude: 46.8182, longitude: 8.2275, region: "Europe"),
        CountryInfo(id: "AT", name: "Austria", latitude: 47.5162, longitude: 14.5501, region: "Europe"),
        CountryInfo(id: "SE", name: "Sweden", latitude: 60.1282, longitude: 18.6435, region: "Europe"),
        CountryInfo(id: "NO", name: "Norway", latitude: 60.472, longitude: 8.4689, region: "Europe"),
        CountryInfo(id: "DK", name: "Denmark", latitude: 56.2639, longitude: 9.5018, region: "Europe"),
        CountryInfo(id: "FI", name: "Finland", latitude: 61.9241, longitude: 25.7482, region: "Europe"),
        CountryInfo(id: "IE", name: "Ireland", latitude: 53.1424, longitude: -7.6921, region: "Europe"),
        CountryInfo(id: "PL", name: "Poland", latitude: 51.9194, longitude: 19.1451, region: "Europe"),
        CountryInfo(id: "CZ", name: "Czech Republic", latitude: 49.8175, longitude: 15.473, region: "Europe"),
        CountryInfo(id: "GR", name: "Greece", latitude: 39.0742, longitude: 21.8243, region: "Europe"),
        CountryInfo(id: "HR", name: "Croatia", latitude: 45.1, longitude: 15.2, region: "Europe"),
        CountryInfo(id: "HU", name: "Hungary", latitude: 47.1625, longitude: 19.5033, region: "Europe"),
        CountryInfo(id: "RO", name: "Romania", latitude: 45.9432, longitude: 24.9668, region: "Europe"),
        CountryInfo(id: "IS", name: "Iceland", latitude: 64.9631, longitude: -19.0208, region: "Europe"),
        CountryInfo(id: "TR", name: "Turkey", latitude: 38.9637, longitude: 35.2433, region: "Europe"),
        CountryInfo(id: "RU", name: "Russia", latitude: 61.524, longitude: 105.3188, region: "Europe"),
        CountryInfo(id: "UA", name: "Ukraine", latitude: 48.3794, longitude: 31.1656, region: "Europe"),

        // Asia
        CountryInfo(id: "JP", name: "Japan", latitude: 36.2048, longitude: 138.2529, region: "Asia"),
        CountryInfo(id: "CN", name: "China", latitude: 35.8617, longitude: 104.1954, region: "Asia"),
        CountryInfo(id: "KR", name: "South Korea", latitude: 35.9078, longitude: 127.7669, region: "Asia"),
        CountryInfo(id: "IN", name: "India", latitude: 20.5937, longitude: 78.9629, region: "Asia"),
        CountryInfo(id: "TH", name: "Thailand", latitude: 15.87, longitude: 100.9925, region: "Asia"),
        CountryInfo(id: "VN", name: "Vietnam", latitude: 14.0583, longitude: 108.2772, region: "Asia"),
        CountryInfo(id: "SG", name: "Singapore", latitude: 1.3521, longitude: 103.8198, region: "Asia"),
        CountryInfo(id: "MY", name: "Malaysia", latitude: 4.2105, longitude: 101.9758, region: "Asia"),
        CountryInfo(id: "ID", name: "Indonesia", latitude: -0.7893, longitude: 113.9213, region: "Asia"),
        CountryInfo(id: "PH", name: "Philippines", latitude: 12.8797, longitude: 121.774, region: "Asia"),
        CountryInfo(id: "TW", name: "Taiwan", latitude: 23.6978, longitude: 120.9605, region: "Asia"),
        CountryInfo(id: "NP", name: "Nepal", latitude: 28.3949, longitude: 84.124, region: "Asia"),
        CountryInfo(id: "LK", name: "Sri Lanka", latitude: 7.8731, longitude: 80.7718, region: "Asia"),
        CountryInfo(id: "KH", name: "Cambodia", latitude: 12.5657, longitude: 104.991, region: "Asia"),
        CountryInfo(id: "MM", name: "Myanmar", latitude: 21.9162, longitude: 95.956, region: "Asia"),
        CountryInfo(id: "AE", name: "United Arab Emirates", latitude: 23.4241, longitude: 53.8478, region: "Asia"),
        CountryInfo(id: "IL", name: "Israel", latitude: 31.0461, longitude: 34.8516, region: "Asia"),
        CountryInfo(id: "JO", name: "Jordan", latitude: 30.5852, longitude: 36.2384, region: "Asia"),

        // Africa
        CountryInfo(id: "ZA", name: "South Africa", latitude: -30.5595, longitude: 22.9375, region: "Africa"),
        CountryInfo(id: "EG", name: "Egypt", latitude: 26.8206, longitude: 30.8025, region: "Africa"),
        CountryInfo(id: "MA", name: "Morocco", latitude: 31.7917, longitude: -7.0926, region: "Africa"),
        CountryInfo(id: "KE", name: "Kenya", latitude: -0.0236, longitude: 37.9062, region: "Africa"),
        CountryInfo(id: "TZ", name: "Tanzania", latitude: -6.369, longitude: 34.8888, region: "Africa"),
        CountryInfo(id: "NG", name: "Nigeria", latitude: 9.082, longitude: 8.6753, region: "Africa"),
        CountryInfo(id: "ET", name: "Ethiopia", latitude: 9.145, longitude: 40.4897, region: "Africa"),
        CountryInfo(id: "GH", name: "Ghana", latitude: 7.9465, longitude: -1.0232, region: "Africa"),
        CountryInfo(id: "TN", name: "Tunisia", latitude: 33.8869, longitude: 9.5375, region: "Africa"),
        CountryInfo(id: "RW", name: "Rwanda", latitude: -1.9403, longitude: 29.8739, region: "Africa"),

        // Oceania
        CountryInfo(id: "AU", name: "Australia", latitude: -25.2744, longitude: 133.7751, region: "Oceania"),
        CountryInfo(id: "NZ", name: "New Zealand", latitude: -40.9006, longitude: 174.886, region: "Oceania"),
        CountryInfo(id: "FJ", name: "Fiji", latitude: -17.7134, longitude: 178.065, region: "Oceania"),
    ]

    static func country(byCode code: String) -> CountryInfo? {
        countries.first { $0.id == code }
    }

    static func country(byName name: String) -> CountryInfo? {
        countries.first { $0.name.lowercased() == name.lowercased() }
    }

    static func countries(inRegion region: String) -> [CountryInfo] {
        countries.filter { $0.region == region }
    }

    static let regions = ["North America", "Central America", "Caribbean", "South America", "Europe", "Asia", "Africa", "Oceania"]
}
