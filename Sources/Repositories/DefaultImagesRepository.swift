//
//  MemoryImageRepository.swift
//  FirebasePlatform
//
//  Created by 김동욱 on 2023/02/18.
//

import Foundation
import Domain
import UIKit
import FirebaseStorage

public enum ImagesRepositoryError: String, Error {
    case uploadError = "이미지 업로드를 실패했습니다."
    case readError = "이미지 다운로드를 실패했습니다."
    case deleteError = "이미지 삭제를 실패했습니다."
}

/// Firebase Storage 서비스
/// 이미지를 다운로드하고 캐시 도입
public final class DefaultImagesRepository: ImagesRepository {
    // MARK: - Private
    private let storageReference: StorageReference
    private var cachedImages = [String: UIImage]()
    
    // MARK: - Init
    public init() {
        let storage = Storage.storage()
        self.storageReference = storage.reference()
    }
    
    // MARK: - Repository logic
    public func upload(at index: Int, _ image: UIImage) async throws {
        if let data = image.pngData() {
            let imageReference = storageReference.child("\(DocumentConstants.memoriesPath)/\(index)")
            do {
                let _ = try await imageReference.putDataAsync(data)
                // using metadata
                cacheImage(index, image: image)
            } catch {
                throw ImagesRepositoryError.uploadError
            }
        }
    }
    
    /// 이미지 다운로드 함수
    /// - Parameters:
    ///   - index: Memories에서 Memory의 index이자, 이미지의 이름
    ///   - completion: UIImage publish
    public func read(at index: Int, _ completion: @escaping ((Result<UIImage, Error>) -> Void)) {
        if let image = cachedImage(index) {
            completion(.success(image))
            return
        }
        
        let imageReference = storageReference.child("\(DocumentConstants.memoriesPath)/\(index)")
        imageReference.getData(maxSize: .max) { data, error in
            if error != nil {
                completion(.failure(ImagesRepositoryError.readError))
                return
            }
            if let data = data {
                guard let image = UIImage(data: data) else {
                    completion(.failure(ImagesRepositoryError.readError))
                    return
                }
                self.cacheImage(index, image: image)
                completion(.success(image))
                return
            } else {
                completion(.failure(ImagesRepositoryError.readError))
                return
            }
        }
    }
    
    public func delete(at index: Int) async throws {
        let reference = storageReference.child("\(index)")
        do {
            try await reference.delete()
        } catch {
            throw ImagesRepositoryError.deleteError
        }
    }
}

// MARK: - Private. Cach
private extension DefaultImagesRepository {
    func cachedImage(_ index: Int) -> UIImage? {
        if let image = cachedImages["\(index)"] {
            return image
        } else {
            return nil
        }
    }
    
    func cacheImage(_ index: Int, image: UIImage) {
        cachedImages["\(index)"] = image
    }
}

// MARK: - Magic string
private extension DefaultImagesRepository {
    @frozen enum DocumentConstants {
        static let memoriesPath = "memories"
    }
}
