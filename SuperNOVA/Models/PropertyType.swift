//
//  PropertyType.swift
//  SuperNOVA
//
//  Created by Daniel on 20/10/25.
//

import Foundation

enum PropertyType: String, Codable, CaseIterable {
    // Simple Types
    case text
    case number
    case currency
    case date
    case datetime
    case duration

    // Complex Types
    case location
    case images
    case files
    case audios

    // Relational Types
    case referenceUnique
    case referenceMultiple

    var displayName: String {
        switch self {
        case .text: return "Text"
        case .number: return "Number"
        case .currency: return "Currency"
        case .date: return "Date"
        case .datetime: return "Date & Time"
        case .duration: return "Duration"
        case .location: return "Location"
        case .images: return "Images"
        case .files: return "Files"
        case .audios: return "Audios"
        case .referenceUnique: return "Reference (Unique)"
        case .referenceMultiple: return "Reference (Multiple)"
        }
    }
}
