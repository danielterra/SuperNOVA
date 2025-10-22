//
//  FormModels.swift
//  SuperNOVA
//
//  Created by Daniel on 21/10/25.
//

import Foundation

// MARK: - State Item

struct StateItem: Identifiable {
    let id: String
    var name: String
    var type: StateType

    init(id: String = UUID().uuidString, name: String, type: StateType) {
        self.id = id
        self.name = name
        self.type = type
    }
}

// MARK: - Property Item

struct PropertyItem: Identifiable, Equatable {
    let id: String
    var name: String
    var type: PropertyType
    var isRequired: Bool
    var referenceTargetClassId: String?

    init(id: String = UUID().uuidString, name: String, type: PropertyType, isRequired: Bool, referenceTargetClassId: String? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.isRequired = isRequired
        self.referenceTargetClassId = referenceTargetClassId
    }
}

// MARK: - Field Identifier

enum FormField: Hashable {
    case name
    case description
}
