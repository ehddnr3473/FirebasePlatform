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
//    public func upload(key: String, plan: Plan) async throws {
//        do {
//            try await database.collection(DatabasePath.plans).document(key).setData([
//                Key.title: plan.title,
//                Key.description: plan.description
//            ])
//
//            for index in plan.schedules.indices {
//                let coordinate = GeoPoint(
//                    latitude: plan.schedules[index].coordinate.latitude,
//                    longitude: plan.schedules[index].coordinate.longitude
//                )
//                try await database.collection(DatabasePath.plans)
//                    .document(key).collection(DocumentConstants.schedulesCollection).document("\(index)")
//                    .setData([
//                        // Key-Value Pair
//                        Key.title:
//                            plan.schedules[index].title,
//                        Key.description:
//                            plan.schedules[index].description,
//                        Key.fromDate:
//                            DateConverter.dateToString(plan.schedules[index].fromDate),
//                        Key.toDate:
//                            DateConverter.dateToString(plan.schedules[index].toDate),
//                        Key.coordinate:
//                            coordinate
//                    ])
//            }
//        } catch {
//            throw PlansRepositoryError.uploadError
//        }
//    }
    
    public func upload(key: String, plan:Plan, completion: @escaping ((Result<Bool, PlansRepositoryError>) -> Void)) async throws {
        database.runTransaction({ (transaction, errorPointer) in
            transaction.setData([
                Key.title: plan.title,
                Key.description: plan.description
            ], forDocument: database.collection(DatabasePath.plans).document(key))
            
            for index in plan.schedules.indices {
                let coordinate = GeoPoint(
                    latitude: plan.schedules[index].coordinate.latitude,
                    longitude: plan.schedules[index].coordinate.longitude
                )
                transaction.setData([
                    // Key-Value Pair
                    Key.title:
                        plan.schedules[index].title,
                    Key.description:
                        plan.schedules[index].description,
                    Key.fromDate:
                        DateConverter.dateToString(plan.schedules[index].fromDate),
                    Key.toDate:
                        DateConverter.dateToString(plan.schedules[index].toDate),
                    Key.coordinate:
                        coordinate
                ], forDocument: database.collection(DatabasePath.plans)
                    .document(key).collection(DocumentConstants.schedulesCollection).document("\(index)"))
            }
            
            completion(.success(true))
        }, completion: { (_, error) in
            if error != nil {
                completion(.failure(PlansRepositoryError.uploadError))
            }
        })
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
    
    public func delete(key: String) async throws {
        do {
            try await database.collection(DatabasePath.plans).document(key).delete()
        } catch {
            throw PlansRepositoryError.deleteError
        }
    }
    
    public func deleteWithSort(key: String, plans: [Plan]) async throws {
        do {
            try await database.collection(DatabasePath.plans).document(key).delete()
            
            guard let deletedKey = Int(key) else { return }
            try await sort(from: deletedKey, plans: plans)
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
    
    func sort(from deletedIndex: Int, plans: [Plan]) async throws {
        guard deletedIndex < plans.count - 1 else { return }
        
        for index in deletedIndex..<plans.count - 1 {
            try await upload(key: String(index), plan: plans[index + 1])
        }
        
        try await database.collection(DatabasePath.plans).document("\(plans.count - 1)").delete()
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
