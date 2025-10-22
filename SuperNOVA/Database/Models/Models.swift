//
//  Models.swift
//  SuperNOVA
//
//  Created by Daniel on 20/10/25.
//

import Foundation

struct EntityClassModel: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String?
    let description: String?
    let createdAt: Date
    let updatedAt: Date
}

struct PropertyModel: Identifiable {
    let id: String
    let entityClassId: String
    let name: String
    let type: PropertyType
    let isRequired: Bool
    let isLongText: Bool
    let order: Int
    let referenceTargetClassId: String?
}

struct StateModel {
    let id: String
    let entityClassId: String
    let name: String
    let type: StateType
    let icon: String?
    let color: String?
    let order: Int
}

struct ActionModel {
    let id: String
    let entityClassId: String
    let name: String
    let icon: String?
    let description: String?
    let triggerType: ActionTriggerType
    let order: Int
    let triggerStateId: String?
    let allowedStateIds: [String]
}
