import ActivityKit
import Foundation
import Flutter

@available(iOS 16.2, *)
class LiveActivityChannel {
    private var currentActivity: Activity<SubsDueAttributes>?
    private let channel: FlutterMethodChannel

    init(binaryMessenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(
            name: "io.devopen.subzilla/live_activity",
            binaryMessenger: binaryMessenger
        )
        channel.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "startActivity":
                guard let args = call.arguments as? [String: Any],
                      let subsJson = args["subsJson"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "subsJson required", details: nil))
                    return
                }
                self?.startActivity(subsJson: subsJson)
                result(nil)
            case "endActivity":
                self?.endActivity()
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func startActivity(subsJson: String) {
        guard currentActivity == nil else { return }
        guard let data = subsJson.data(using: .utf8),
              let subs = try? JSONDecoder().decode([DueSub].self, from: data) else { return }
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) else { return }
        let staleDate = Calendar.current.startOfDay(for: tomorrow)
        let attributes = SubsDueAttributes(appName: "SubZilla")
        let state = SubsDueAttributes.ContentState(dueSubs: subs)
        let content = ActivityContent(state: state, staleDate: staleDate)
        do {
            currentActivity = try Activity.request(attributes: attributes, content: content)
        } catch {
            // Live Activities not supported or denied
        }
    }

    private func endActivity() {
        Task {
            await currentActivity?.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }
}
