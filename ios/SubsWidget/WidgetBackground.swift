import SwiftUI
import WidgetKit

extension View {
    @ViewBuilder
    func widgetBackground() -> some View {
        if #available(iOS 17, *) {
            containerBackground(.fill, for: .widget)
        } else {
            background(Color(UIColor.systemBackground))
                .padding()
        }
    }
}
