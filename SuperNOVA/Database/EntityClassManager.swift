//
//  EntityClassManager.swift
//  SuperNOVA
//
//  Created by Daniel on 20/10/25.
//  Facade pattern for backward compatibility
//

import Foundation

class EntityClassManager {
    static let shared = EntityClassManager()

    private let entityClassRepo = EntityClassRepository()
    private let propertyRepo = PropertyRepository()
    private let stateRepo = StateRepository()
    private let actionRepo = ActionRepository()

    private init() {}

    // MARK: - Entity Class

    func createEntityClass(name: String, icon: String? = nil, description: String? = nil) -> String? {
        LogManager.shared.addLog("Creating entity class: \(name)", component: "EntityClassManager")
        let result = entityClassRepo.create(name: name, icon: icon, description: description)
        if let id = result {
            LogManager.shared.addLog("Entity class created with ID: \(id)", component: "EntityClassManager")
        } else {
            LogManager.shared.addError("Failed to create entity class: \(name)", component: "EntityClassManager")
        }
        return result
    }

    func getEntityClass(id: String) -> EntityClassModel? {
        return entityClassRepo.get(id: id)
    }

    func getAllEntityClasses() -> [EntityClassModel] {
        return entityClassRepo.getAll()
    }

    func updateEntityClass(id: String, name: String? = nil, icon: String? = nil, description: String? = nil) -> Bool {
        LogManager.shared.addLog("Updating entity class: \(id)", component: "EntityClassManager")
        let result = entityClassRepo.update(id: id, name: name, icon: icon, description: description)
        if result {
            LogManager.shared.addLog("Entity class updated successfully", component: "EntityClassManager")
        } else {
            LogManager.shared.addError("Failed to update entity class", component: "EntityClassManager")
        }
        return result
    }

    func deleteEntityClass(id: String) -> Bool {
        LogManager.shared.addLog("Deleting entity class: \(id)", component: "EntityClassManager")
        let result = entityClassRepo.delete(id: id)
        if result {
            LogManager.shared.addLog("Entity class deleted successfully", component: "EntityClassManager")
        } else {
            LogManager.shared.addError("Failed to delete entity class", component: "EntityClassManager")
        }
        return result
    }

    // MARK: - Property

    func createProperty(
        entityClassId: String,
        name: String,
        type: PropertyType,
        isRequired: Bool = false,
        isLongText: Bool = false,
        order: Int = 0,
        referenceTargetClassId: String? = nil
    ) -> String? {
        LogManager.shared.addLog("Creating property '\(name)' for class: \(entityClassId)", component: "EntityClassManager")
        let result = propertyRepo.create(
            entityClassId: entityClassId,
            name: name,
            type: type,
            isRequired: isRequired,
            isLongText: isLongText,
            order: order,
            referenceTargetClassId: referenceTargetClassId
        )
        if let id = result {
            LogManager.shared.addLog("Property created with ID: \(id)", component: "EntityClassManager")
        } else {
            LogManager.shared.addError("Failed to create property: \(name)", component: "EntityClassManager")
        }
        return result
    }

    func getProperties(for entityClassId: String) -> [PropertyModel] {
        return propertyRepo.getAll(for: entityClassId)
    }

    func updateProperty(
        propertyId: String,
        name: String? = nil,
        type: PropertyType? = nil,
        isRequired: Bool? = nil,
        isLongText: Bool? = nil,
        referenceTargetClassId: String? = nil
    ) -> Bool {
        LogManager.shared.addLog("Updating property: \(propertyId)", component: "EntityClassManager")
        let result = propertyRepo.update(
            propertyId: propertyId,
            name: name,
            type: type,
            isRequired: isRequired,
            isLongText: isLongText,
            referenceTargetClassId: referenceTargetClassId
        )
        if result {
            LogManager.shared.addLog("Property updated successfully", component: "EntityClassManager")
        } else {
            LogManager.shared.addError("Failed to update property", component: "EntityClassManager")
        }
        return result
    }

    func updatePropertyOrder(propertyId: String, newOrder: Int) -> Bool {
        return propertyRepo.updateOrder(propertyId: propertyId, newOrder: newOrder)
    }

    func deleteProperty(id: String) -> Bool {
        LogManager.shared.addLog("Deleting property: \(id)", component: "EntityClassManager")
        let result = propertyRepo.delete(id: id)
        if result {
            LogManager.shared.addLog("Property deleted successfully", component: "EntityClassManager")
        } else {
            LogManager.shared.addError("Failed to delete property", component: "EntityClassManager")
        }
        return result
    }

    // MARK: - State

    func createState(
        entityClassId: String,
        name: String,
        type: StateType,
        icon: String? = nil,
        color: String? = nil,
        order: Int = 0
    ) -> String? {
        LogManager.shared.addLog("Creating state '\(name)' for class: \(entityClassId)", component: "EntityClassManager")
        let result = stateRepo.create(entityClassId: entityClassId, name: name, type: type, icon: icon, color: color, order: order)
        if let id = result {
            LogManager.shared.addLog("State created with ID: \(id)", component: "EntityClassManager")
        } else {
            LogManager.shared.addError("Failed to create state: \(name)", component: "EntityClassManager")
        }
        return result
    }

    func getStates(for entityClassId: String) -> [StateModel] {
        return stateRepo.getAll(for: entityClassId)
    }

    func deleteState(id: String) -> Bool {
        LogManager.shared.addLog("Deleting state: \(id)", component: "EntityClassManager")
        let result = stateRepo.delete(id: id)
        if result {
            LogManager.shared.addLog("State deleted successfully", component: "EntityClassManager")
        } else {
            LogManager.shared.addError("Failed to delete state", component: "EntityClassManager")
        }
        return result
    }

    // MARK: - Action

    func createAction(
        entityClassId: String,
        name: String,
        icon: String? = nil,
        description: String? = nil,
        triggerType: ActionTriggerType = .manual,
        order: Int = 0,
        triggerStateId: String? = nil,
        allowedStateIds: [String] = []
    ) -> String? {
        LogManager.shared.addLog("Creating action '\(name)' for class: \(entityClassId)", component: "EntityClassManager")
        let result = actionRepo.create(
            entityClassId: entityClassId,
            name: name,
            icon: icon,
            description: description,
            triggerType: triggerType,
            order: order,
            triggerStateId: triggerStateId,
            allowedStateIds: allowedStateIds
        )
        if let id = result {
            LogManager.shared.addLog("Action created with ID: \(id)", component: "EntityClassManager")
        } else {
            LogManager.shared.addError("Failed to create action: \(name)", component: "EntityClassManager")
        }
        return result
    }

    func getActions(for entityClassId: String) -> [ActionModel] {
        return actionRepo.getAll(for: entityClassId)
    }

    func deleteAction(id: String) -> Bool {
        LogManager.shared.addLog("Deleting action: \(id)", component: "EntityClassManager")
        let result = actionRepo.delete(id: id)
        if result {
            LogManager.shared.addLog("Action deleted successfully", component: "EntityClassManager")
        } else {
            LogManager.shared.addError("Failed to delete action", component: "EntityClassManager")
        }
        return result
    }
}
