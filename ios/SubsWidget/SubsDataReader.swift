import Foundation

struct SubsDataReader {
    static func read() -> WidgetData? {
        guard let defaults = UserDefaults(suiteName: "group.io.devopen.subzilla"),
              let jsonString = defaults.string(forKey: "subs_data"),
              let data = jsonString.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(WidgetData.self, from: data)
    }
}
