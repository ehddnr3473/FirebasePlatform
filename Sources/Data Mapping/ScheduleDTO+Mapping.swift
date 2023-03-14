//
//  ScheduleDTO.swift
//  
//
//  Created by 김동욱 on 2023/03/13.
//

import Foundation
import Domain
import CoreLocation

struct ScheduleDTO: Codable {
    let title: String
    let description: String
    let latitude: Double
    let longitude: Double
    let fromDate: String?
    let toDate: String?
    
    init(schedule: Schedule) {
        self.title = schedule.title
        self.description = schedule.description
        self.latitude = schedule.coordinate.latitude
        self.longitude = schedule.coordinate.longitude
        if let fromDate = schedule.fromDate, let toDate = schedule.toDate {
            self.fromDate = dateFormatter.string(from: fromDate)
            self.toDate = dateFormatter.string(from: toDate)
        } else {
            self.fromDate = nil
            self.toDate = nil
        }
    }
}

extension ScheduleDTO {
    func toDomain() -> Schedule {
        .init(title: title,
              description: description,
              coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
              fromDate: dateFormatter.date(from: fromDate ?? ""),
              toDate: dateFormatter.date(from: toDate ?? "")
        )
    }
}

// MARK: - Private
private let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yy.MM.dd"
    return dateFormatter
}()
