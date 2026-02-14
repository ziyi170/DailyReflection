//
//  DailyReflectionWidgetExtensionBundle.swift
//  DailyReflectionWidgetExtension
//
//  Created by 小艺 on 2026/2/1.
//

import WidgetKit
import SwiftUI

@main
struct DailyReflectionWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        DailyReflectionWidget()
        DailyReflectionLockWidget() 
        DailyReflectionWidgetExtensionControl()
        DailyReflectionLiveActivity()
    }
}
