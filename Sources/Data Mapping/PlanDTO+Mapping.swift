//
//  PlanDTO.swift
//  
//
//  Created by 김동욱 on 2023/03/13.
//

import Foundation
import Domain

struct PlanDTO: Codable {
    let title: String
    let description: String
    let schedules: [ScheduleDTO]
    
    init(plan: Plan) {
        self.title = plan.title
        self.description = plan.description
        self.schedules = plan.schedules.map { .init(schedule: $0) }
    }
}

extension PlanDTO {
    func toDomain() -> Plan {
        .init(title: title,
              description: description,
              schedules: schedules.map { $0.toDomain() }
        )
    }
}
