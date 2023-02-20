//
//  FBMemory.swift
//  FirebasePlatform
//
//  Created by 김동욱 on 2023/02/18.
//

import Foundation
import Domain

/// Data Transfer Object
/// FBMemory(Data) -> Memory(Domain)
struct FBMemory {
    let title: String
    let index: Int
    let uploadDate: Date
}

// MARK: - Mapping to domain
extension FBMemory {
    func toDomain() -> Memory {
        Memory(title: title,
               index: index,
               uploadDate: uploadDate)
    }
}

extension Memory {
    func toData() -> FBMemory {
        FBMemory(title: title,
                  index: index,
                  uploadDate: uploadDate)
    }
}
