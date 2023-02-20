//
//  FBTravelPlan.swift
//  FirebasePlatform
//
//  Created by 김동욱 on 2023/02/18.
//

import Foundation
import Domain

/// Data Transfer Object
/// FBTravelPlan(Data) -> TravelPlan(Domain)
struct FBTravelPlan {
    let title: String
    let description: String
    let schedules: [FBSchedule]
}

// MARK: - Mapping to domain
extension FBTravelPlan {
    func toDomain() -> TravelPlan {
        let schedules = schedules.map { $0.toDomain() }
        return TravelPlan(title: title,
                          description: description,
                          schedules: schedules)
    }
}

extension TravelPlan {
    func toData() -> FBTravelPlan {
        return FBTravelPlan(title: title,
                             description: description,
                             schedules: schedules.map { $0.toData() })
    }
}
