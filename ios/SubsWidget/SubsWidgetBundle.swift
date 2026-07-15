//
//  SubsWidgetBundle.swift
//  SubsWidget
//
//  Created by Eren Gün on 8.06.2026.
//

import WidgetKit
import SwiftUI

@main
struct SubsWidgetBundle: WidgetBundle {
    var body: some Widget {
        MonthlySpendWidget()
        NextDueWidget()
        UpcomingWidget()
        SubsDueWidgetLiveActivity()
    }
}
