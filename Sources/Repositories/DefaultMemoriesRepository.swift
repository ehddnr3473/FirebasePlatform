//
//  DefaultMemoriesRepository.swift
//  FirebasePlatform
//
//  Created by 김동욱 on 2023/02/18.
//

import Foundation
import Domain
import FirebaseFirestore

public enum MemoriesRepositoryError: String, Error {
    case uploadError = "메모리 업로드를 실패했습니다."
    case readError = "메모리 다운로드를 실패했습니다."
    case deleteError = "메모리 삭제를 실패했습니다."
}

/// Firebase Firestore 서비스
public struct DefaultMemoriesRepository: MemoriesRepository {
    // MARK: - Private
    private var database: Firestore

    // MARK: - Init
    public init() {
        self.database = Firestore.firestore()
    }
    
    // MARK: - Repository logic
    public func upload(at index: Int, memory: Memory) async throws {
        do {
            try await database.collection(DatabasePath.memories).document("\(DocumentPrefix.memory)\(memory.index)").setData([
                Key.title: memory.title,
                Key.index: memory.index,
                Key.uploadDate: DateConverter.dateToString(memory.uploadDate)
            ])
        } catch {
            throw MemoriesRepositoryError.uploadError
        }
    }
    
    public func read() async throws -> [Memory] {
        var memories = [Memory]()
        do {
            let memoriesSnapshot = try await database.collection(DatabasePath.memories).getDocuments()
            
            for document in memoriesSnapshot.documents {
                let data = document.data()
                memories.append(self.createMemory(data))
            }
            
            return memories
        } catch {
            throw MemoriesRepositoryError.readError
        }
    }
    
    public func delete(at index: Int) async throws {
        do {
            try await database.collection(DatabasePath.memories).document("\(index)").delete()
        } catch {
            throw MemoriesRepositoryError.deleteError
        }
    }
}

// MARK: - Private
private extension DefaultMemoriesRepository {
    // 다운로드한 데이터로 Memory를 생성하여 반환
    func createMemory(_ data: Dictionary<String, Any>) -> Memory {
        let memories = Memory(title: data[Key.title] as! String,
                              index: data[Key.index] as! Int,
                              uploadDate: DateConverter.stringToDate(data[Key.uploadDate] as! String)!)
        return memories
    }
}

// MARK: - Magic string
private extension DefaultMemoriesRepository {
    @frozen enum Key {
        static let title = "title"
        static let index = "index"
        static let uploadDate = "date"
    }

    @frozen enum DocumentPrefix {
        static let memory = "memory"
    }
}
