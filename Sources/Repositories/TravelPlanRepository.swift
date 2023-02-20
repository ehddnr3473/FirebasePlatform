//
//  TravelPlanRepository.swift
//  FirebasePlatform
//
//  Created by 김동욱 on 2023/02/18.
//

import Foundation
import Domain
import CoreLocation
import FirebaseFirestore

public enum TravelPlanRepositoryError: String, Error {
    case uploadError = "계획 업로드를 실패했습니다."
    case readError = "계획 다운로드를 실패했습니다."
    case deleteError = "계획 삭제를 실패했습니다."
    case swapError = "계획 순서 변경을 실패했습니다."
}

public struct TravelPlanRepository: AbstractRepository {
    private var database: Firestore
    
    public init(_ database: Firestore) {
        self.database = database
    }
    
    // create & update
    public func upload(at index: Int, entity: TravelPlan) async throws {
        let object = entity.toData()
        do {
            try await database.collection(DatabasePath.plans).document("\(index)").setData([
                Key.title: object.title,
                Key.description: object.description
            ])
            
            for scheduleIndex in object.schedules.indices {
                let coordinate = GeoPoint(
                    latitude: object.schedules[scheduleIndex].coordinate.latitude,
                    longitude: object.schedules[scheduleIndex].coordinate.longitude
                )
                try await database.collection(DatabasePath.plans)
                    .document("\(index)").collection(DocumentConstants.schedulesCollection).document("\(scheduleIndex)")
                    .setData([
                        // Key-Value Pair
                        Key.title:
                            object.schedules[scheduleIndex].title,
                        Key.description:
                            object.schedules[scheduleIndex].description,
                        Key.fromDate:
                            DateConverter.dateToString(object.schedules[scheduleIndex].fromDate),
                        Key.toDate:
                            DateConverter.dateToString(object.schedules[scheduleIndex].toDate),
                        Key.coordinate:
                            coordinate
                    ])
            }
        } catch {
            throw TravelPlanRepositoryError.uploadError
        }
    }
    
    // read
    // Firebase에서 다운로드한 데이터로 TravelPlanDTO를 생성해서 반환
    public func read() async throws -> [TravelPlan] {
        var travelPlans = [FBTravelPlan]()
        
        do {
            let travelPlansSnapshot = try await database.collection(DatabasePath.plans).getDocuments()
            var documentIndex = NumberConstants.zero
            
            for document in travelPlansSnapshot.documents {
                let data = document.data()
                let scheduleSnapshot = try await database.collection(DatabasePath.plans)
                    .document("\(documentIndex)").collection(DocumentConstants.schedulesCollection).getDocuments()
                var schedules = [FBSchedule]()
                
                for documentation in scheduleSnapshot.documents {
                    schedules.append(self.createSchedule(documentation.data()))
                }
                travelPlans.append(self.createTravelPlan(data, schedules))
                documentIndex += NumberConstants.one
            }
            return travelPlans.map { $0.toDomain() }
        } catch {
            throw TravelPlanRepositoryError.readError
        }
    }
    
    // delete
    public func delete(at index: Int) async throws {
        do {
            try await database.collection(DatabasePath.plans).document("\(index)").delete()
        } catch {
            throw TravelPlanRepositoryError.deleteError
        }
    }
    
    // Firebase에서 다운로드한 데이터로 TravelPlan을 생성해서 반환
    private func createTravelPlan(_ data: Dictionary<String, Any>, _ schedules: [FBSchedule]) -> FBTravelPlan {
        FBTravelPlan(
            title: data[Key.title] as! String,
            description: data[Key.description] as! String,
            schedules: schedules
        )
    }
    
    // Firebase에서 다운로드한 데이터로 Schedule을 생성해서 반환
    private func createSchedule(_ data: Dictionary<String, Any>) -> FBSchedule {
        guard let coordinate = data[Key.coordinate] as? GeoPoint else { fatalError() }
        if let fromDate = data[Key.fromDate] as? String,
           let toDate = data[Key.toDate] as? String {
            return FBSchedule(
                title: data[Key.title] as! String,
                description: data[Key.description] as! String,
                coordinate: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude),
                fromDate: DateConverter.stringToDate(fromDate),
                toDate: DateConverter.stringToDate(toDate)
            )
        } else {
            return FBSchedule(
                title: data[Key.title] as! String,
                description: data[Key.description] as! String,
                coordinate: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude),
                fromDate: nil,
                toDate: nil
            )
        }
    }
}

private enum NumberConstants {
    static let zero = 0
    static let one = 1
}
private enum DocumentConstants {
    static let schedulesCollection = "schedules"
}

private enum Key {
    static let title = "title"
    static let description = "description"
    static let fromDate = "fromDate"
    static let toDate = "toDate"
    static let coordinate = "coordinate"
}
