//
//  DefaultPlansRepository.swift
//  FirebasePlatform
//
//  Created by 김동욱 on 2023/02/18.
//

import Foundation
import Domain
import CoreLocation
import FirebaseCore
import FirebaseFirestore

public enum PlansRepositoryError: String, Error {
    case uploadError = "계획 업로드를 실패했습니다."
    case readError = "계획 다운로드를 실패했습니다."
    case deleteError = "계획 삭제를 실패했습니다."
    case swapError = "계획 순서 변경을 실패했습니다."
}

/// Firebase Firestore 서비스
public struct DefaultPlansRepository: PlansRepository {
    // MARK: - Private
    private var database: Firestore
    
    // MARK: - Init
    public init() {
        self.database = Firestore.firestore()
    }
    
    // MARK: - Repository logic
    public func upload(at index: Int, plan: Plan) async throws {
        do {
            try await database.collection(DatabasePath.plans).document("\(index)").setData([
                Key.title: plan.title,
                Key.description: plan.description
            ])
            
            for scheduleIndex in plan.schedules.indices {
                let coordinate = GeoPoint(
                    latitude: plan.schedules[scheduleIndex].coordinate.latitude,
                    longitude: plan.schedules[scheduleIndex].coordinate.longitude
                )
                try await database.collection(DatabasePath.plans)
                    .document("\(index)").collection(DocumentConstants.schedulesCollection).document("\(scheduleIndex)")
                    .setData([
                        // Key-Value Pair
                        Key.title:
                            plan.schedules[scheduleIndex].title,
                        Key.description:
                            plan.schedules[scheduleIndex].description,
                        Key.fromDate:
                            DateConverter.dateToString(plan.schedules[scheduleIndex].fromDate),
                        Key.toDate:
                            DateConverter.dateToString(plan.schedules[scheduleIndex].toDate),
                        Key.coordinate:
                            coordinate
                    ])
            }
        } catch {
            throw PlansRepositoryError.uploadError
        }
    }
    
    public func read() async throws -> [Plan] {
        var plans = [Plan]()
        
        do {
            let plansSnapshot = try await database.collection(DatabasePath.plans).getDocuments()
            var documentIndex = NumberConstants.zero
            
            for document in plansSnapshot.documents {
                let data = document.data()
                let scheduleSnapshot = try await database.collection(DatabasePath.plans)
                    .document("\(documentIndex)").collection(DocumentConstants.schedulesCollection).getDocuments()
                var schedules = [Schedule]()
                
                for documentation in scheduleSnapshot.documents {
                    schedules.append(createSchedule(documentation.data()))
                }
                plans.append(createPlan(data, schedules))
                documentIndex += NumberConstants.one
            }
            return plans
        } catch {
            throw PlansRepositoryError.readError
        }
    }
    
    public func delete(at index: Int) async throws {
        do {
            try await database.collection(DatabasePath.plans).document("\(index)").delete()
        } catch {
            throw PlansRepositoryError.deleteError
        }
    }
}

// MARK: - Private
private extension DefaultPlansRepository {
    // Firebase에서 다운로드한 데이터로 Plan을 생성해서 반환
    func createPlan(_ data: Dictionary<String, Any>, _ schedules: [Schedule]) -> Plan {
        Plan(
            title: data[Key.title] as! String,
            description: data[Key.description] as! String,
            schedules: schedules
        )
    }
    
    // Firebase에서 다운로드한 데이터로 Schedule을 생성해서 반환
    func createSchedule(_ data: Dictionary<String, Any>) -> Schedule {
        guard let coordinate = data[Key.coordinate] as? GeoPoint else { fatalError() }
        if let fromDate = data[Key.fromDate] as? String,
           let toDate = data[Key.toDate] as? String {
            return Schedule(
                title: data[Key.title] as! String,
                description: data[Key.description] as! String,
                coordinate: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude),
                fromDate: DateConverter.stringToDate(fromDate),
                toDate: DateConverter.stringToDate(toDate)
            )
        } else {
            return Schedule(
                title: data[Key.title] as! String,
                description: data[Key.description] as! String,
                coordinate: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude),
                fromDate: nil,
                toDate: nil
            )
        }
    }
}

// MARK: - Magic number/string
private extension DefaultPlansRepository {
    @frozen enum NumberConstants {
        static let zero = 0
        static let one = 1
    }
    @frozen enum DocumentConstants {
        static let schedulesCollection = "schedules"
    }

    @frozen enum Key {
        static let title = "title"
        static let description = "description"
        static let fromDate = "fromDate"
        static let toDate = "toDate"
        static let coordinate = "coordinate"
    }

}
