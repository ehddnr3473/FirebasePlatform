//
//  MemoryRepository.swift
//  FirebasePlatform
//
//  Created by 김동욱 on 2023/02/18.
//

import Foundation
import Domain
import FirebaseFirestore

public enum MemoryRepositoryError: String, Error {
    case uploadError = "메모리 업로드를 실패했습니다."
    case readError = "메모리 다운로드를 실패했습니다."
    case deleteError = "메모리 삭제를 실패했습니다."
}

/// Memory 관련 Firebase Firestore 연동
public struct MemoryRepository: AbstractRepository {
    private var database: Firestore

    public init(_ database: Firestore) {
        self.database = database
    }
    
    // write
    public func upload(at index: Int, entity: Memory) async throws {
        let object = entity.toData()
        do {
            try await database.collection(DatabasePath.memories).document("\(DocumentPrefix.memory)\(object.index)").setData([
                Key.title: object.title,
                Key.index: object.index,
                Key.uploadDate: DateConverter.dateToString(object.uploadDate)
            ])
        } catch {
            throw MemoryRepositoryError.uploadError
        }
    }
    
    // read & return
    public func read() async throws -> [Memory] {
        var memories = [FBMemory]()
        do {
            let memoriesSnapshot = try await database.collection(DatabasePath.memories).getDocuments()
            
            for document in memoriesSnapshot.documents {
                let data = document.data()
                memories.append(self.createMemoryDTO(data))
            }
            
            return memories.map { $0.toDomain() }
        } catch {
            throw MemoryRepositoryError.readError
        }
    }
    
    // delete
    public func delete(at index: Int) async throws {
        do {
            try await database.collection(DatabasePath.memories).document("\(index)").delete()
        } catch {
            throw MemoryRepositoryError.deleteError
        }
    }
    
    // 다운로드한 데이터로 MemoryDTO 생성하여 반환
    private func createMemoryDTO(_ data: Dictionary<String, Any>) -> FBMemory {
        let memories = FBMemory(title: data[Key.title] as! String,
                              index: data[Key.index] as! Int,
                              uploadDate: DateConverter.stringToDate(data[Key.uploadDate] as! String)!)
        return memories
    }
}

private enum Key {
    static let title = "title"
    static let index = "index"
    static let uploadDate = "date"
}

private enum DocumentPrefix {
    static let memory = "memory"
}
