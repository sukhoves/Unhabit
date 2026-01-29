//
//  TimeTrackingAttributes.swift
//  Unhabit
//
//  Created by Evgenii Sukhov on 16.01.2026.
//

import Foundation
import ActivityKit

struct TimeTrackingAttributes: ActivityAttributes {
    public typealias TimeTrackingStatus = ContentState
    
    public struct ContentState: Codable, Hashable {
        var startTime: Date
        var endTime: Date
        var qtyCigarette: Int
    }
}


