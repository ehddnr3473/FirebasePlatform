//
//  FBSchedule.swift
//  FirebasePlatform
//
//  Created by 김동욱 on 2023/02/18.
//

import Foundation
import Domain
import CoreLocation

/// Data Transfer Object
/// ScheduleDTO(Data) -> Schedule(Domain)
struct FBSchedule {
    let title: String
    let description: String
    let coordinate: CLLocationCoordinate2D
    let fromDate: Date?
    let toDate: Date?
}

// MARK: - Mapping to domain
extension FBSchedule {
    func toDomain() -> Schedule {
        Schedule(
            title: title,
            description: description,
            coordinate: coordinate,
            fromDate: fromDate,
            toDate: toDate
        )
    }
}

extension Schedule {
    func toData() -> FBSchedule {
        FBSchedule(title: title,
                    description: description,
                    coordinate: coordinate,
                    fromDate: fromDate,
                    toDate: toDate)
    }
}
