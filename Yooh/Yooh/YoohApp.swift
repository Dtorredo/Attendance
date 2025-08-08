//
//  YoohApp.swift
//  Yooh
//
//  Created by Derrick ng'ang'a on 06/08/2025.
//

import SwiftUI

@main
struct YoohApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: SchoolClass.self)
    }
}
