//
//  widgetBundle.swift
//  widget
//
//  Created by Gleswam on 8. 5. 2025..
//

import WidgetKit
import SwiftUI

@main
struct MainWidgetBundle: WidgetBundle {
    var body: some Widget {
        WeatherWidget()
        NewsWidget()
        GreetingWidget()
    }
}
