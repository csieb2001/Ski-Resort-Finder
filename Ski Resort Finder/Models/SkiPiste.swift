import Foundation
import MapKit
import SwiftUI

// MARK: - Ski Piste Models

struct SkiPiste: Identifiable, Codable {
    let id: String
    let name: String?
    let type: PisteType
    let difficulty: PisteDifficulty
    let coordinates: [CLLocationCoordinate2D]
    let grooming: PisteGrooming?
    let status: PisteStatus?
    
    init(id: String, name: String?, type: PisteType, difficulty: PisteDifficulty, coordinates: [CLLocationCoordinate2D], grooming: PisteGrooming? = nil, status: PisteStatus? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.difficulty = difficulty
        self.coordinates = coordinates
        self.grooming = grooming
        self.status = status
    }
}

// MARK: - Piste Type

enum PisteType: String, CaseIterable, Codable {
    case downhill = "downhill"
    case nordic = "nordic"
    case skitour = "skitour"
    case sled = "sled"
    case connection = "connection"
    case snowPark = "snow_park"
    case playground = "playground"
    
    var displayName: String {
        switch self {
        case .downhill:
            return "piste_type_downhill".localized
        case .nordic:
            return "piste_type_nordic".localized
        case .skitour:
            return "piste_type_skitour".localized
        case .sled:
            return "piste_type_sled".localized
        case .connection:
            return "piste_type_connection".localized
        case .snowPark:
            return "piste_type_snow_park".localized
        case .playground:
            return "piste_type_playground".localized
        }
    }
    
    var icon: String {
        switch self {
        case .downhill:
            return "figure.skiing.downhill"
        case .nordic:
            return "figure.skiing.crosscountry"
        case .skitour:
            return "figure.hiking"
        case .sled:
            return "figure.sledding"
        case .connection:
            return "arrow.triangle.swap"
        case .snowPark:
            return "figure.snowboarding"
        case .playground:
            return "figure.and.child.holdinghands"
        }
    }
}

// MARK: - Piste Difficulty

enum PisteDifficulty: String, CaseIterable, Codable {
    case novice = "novice"       // Green
    case easy = "easy"           // Blue
    case intermediate = "intermediate" // Red
    case advanced = "advanced"   // Black
    case expert = "expert"       // Double Black
    case freeride = "freeride"   // Off-piste
    
    var displayName: String {
        switch self {
        case .novice:
            return "piste_difficulty_novice".localized
        case .easy:
            return "piste_difficulty_easy".localized
        case .intermediate:
            return "piste_difficulty_intermediate".localized
        case .advanced:
            return "piste_difficulty_advanced".localized
        case .expert:
            return "piste_difficulty_expert".localized
        case .freeride:
            return "piste_difficulty_freeride".localized
        }
    }
    
    var color: Color {
        switch self {
        case .novice:
            return .green
        case .easy:
            return .blue
        case .intermediate:
            return .red
        case .advanced:
            return .black
        case .expert:
            return .black
        case .freeride:
            return .orange
        }
    }
    
    var mapColor: UIColor {
        switch self {
        case .novice:
            return UIColor.systemGreen
        case .easy:
            return UIColor.systemBlue
        case .intermediate:
            return UIColor.systemRed
        case .advanced:
            return UIColor.black
        case .expert:
            return UIColor.black
        case .freeride:
            return UIColor.systemOrange
        }
    }
    
    var symbol: String {
        switch self {
        case .novice:
            return "●"  // Green circle
        case .easy:
            return "■"  // Blue square
        case .intermediate:
            return "◆"  // Red diamond
        case .advanced:
            return "◆◆" // Black diamond
        case .expert:
            return "◆◆" // Double black diamond
        case .freeride:
            return "🏔"  // Off-piste
        }
    }
}

// MARK: - Piste Grooming

enum PisteGrooming: String, CaseIterable, Codable {
    case classic = "classic"
    case skating = "skating"
    case backcountry = "backcountry"
    case mogul = "mogul"
    
    var displayName: String {
        switch self {
        case .classic:
            return "piste_grooming_classic".localized
        case .skating:
            return "piste_grooming_skating".localized
        case .backcountry:
            return "piste_grooming_backcountry".localized
        case .mogul:
            return "piste_grooming_mogul".localized
        }
    }
}

// MARK: - Piste Status

enum PisteStatus: String, CaseIterable, Codable {
    case open = "open"
    case closed = "closed"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .open:
            return "piste_status_open".localized
        case .closed:
            return "piste_status_closed".localized
        case .unknown:
            return "piste_status_unknown".localized
        }
    }
    
    var color: Color {
        switch self {
        case .open:
            return .green
        case .closed:
            return .red
        case .unknown:
            return .gray
        }
    }
}

// Note: CLLocationCoordinate2D Codable extension is already defined in MapView.swift