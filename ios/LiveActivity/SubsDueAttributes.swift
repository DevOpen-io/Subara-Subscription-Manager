import ActivityKit
import Foundation

struct DueSub: Codable, Hashable {
    let name: String
    let amount: Double
    let currency: String
    let color: Int
}

struct SubsDueAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var dueSubs: [DueSub]
    }
    // Static attributes (set at start, don't change)
    let appName: String
}
