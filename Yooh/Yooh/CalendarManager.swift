//
//  CalendarManager.swift
//  Yooh
//
//  Created by Derrick ng'ang'a on 06/08/2025.
//

import Foundation
import UserNotifications
import Combine
import SwiftData

class CalendarManager: NSObject, ObservableObject {
    @Published var upcomingClasses: [SchoolClass] = []
    private var modelContext: ModelContext? = nil

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadUpcomingClasses()
    }
    
    // MARK: - Load Classes from SwiftData
    
    func loadUpcomingClasses() {
        guard let modelContext = modelContext else { return }
        let descriptor = FetchDescriptor<SchoolClass>(sortBy: [SortDescriptor(\SchoolClass.startDate, order: .forward)])
        do {
            upcomingClasses = try modelContext.fetch(descriptor)
        } catch {
            print("Fetch failed")
        }
    }
    
    // MARK: - Refresh Data
    
    func refreshData() {
        loadUpcomingClasses()
    }
}
