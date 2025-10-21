//
//  ActionTriggerType.swift
//  SuperNOVA
//
//  Created by Daniel on 20/10/25.
//

import Foundation

enum ActionTriggerType: String, Codable {
    case manual
    case automatic
}

enum StateType: String, Codable {
    case inactive
    case active
    case inProgress = "in_progress"

    var displayName: String {
        switch self {
        case .inactive: return "Inactive"
        case .active: return "Active"
        case .inProgress: return "In Progress"
        }
    }
}
