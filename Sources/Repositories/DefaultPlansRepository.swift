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
import FirebaseFirestoreSwift

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
    public func upload(plan: Plan) throws {
        let planDTO = PlanDTO(plan: plan)
        
        do {
            try database.collection(DatabasePath.plans).document(planDTO.title).setData(from: planDTO)
        } catch {
            throw PlansRepositoryError.uploadError
        }
    }
    
    public func read() async throws -> [Plan] {
        var planDTOs = [PlanDTO]()
        
        do {
            let querySnapshot = try await database.collection(DatabasePath.plans).getDocuments()
            
            for document in querySnapshot.documents {
                let id = document.documentID
                let reference = database.collection(DatabasePath.plans).document(id)
                let planDTO = try await reference.getDocument(as: PlanDTO.self)
                planDTOs.append(planDTO)
            }
            
            return planDTOs.sorted(by: { $0.updatedDate > $1.updatedDate }).map { $0.toDomain() }
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
