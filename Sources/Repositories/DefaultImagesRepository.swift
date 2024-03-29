//
//  MemoryImageRepository.swift
//  FirebasePlatform
//
//  Created by 김동욱 on 2023/02/18.
//

import Foundation
import UIKit
import Domain
import FirebaseStorage

public enum ImagesRepositoryError: String, Error {
    case uploadError = "이미지 업로드를 실패했습니다."
    case readError = "이미지 다운로드를 실패했습니다."
    case deleteError = "이미지 삭제를 실패했습니다."
}

// MARK: - Internal. Cache
protocol ImageCacheable: AnyObject {
    func search(origin: String) -> UIImage?
    func cacheImage(origin: String, image: UIImage)
}

final class ImageCacheManager: ImageCacheable {
    private var images = [String: UIImage]()
    
    func search(origin: String) -> UIImage? {
        if let image = images[origin] {
            return image
        } else {
            return nil
        }
    }
    
    func cacheImage(origin: String, image: UIImage) {
        images[origin] = image
    }
}

// MARK: - Repository
/// Firebase Storage 서비스
public final class DefaultImagesRepository: ImagesRepository {
    // MARK: - Private
    private let storageReference: StorageReference
    // MARK: - Internal
    let imageCacheManager: ImageCacheable
    
    // MARK: - Init
    public init() {
        let storage = Storage.storage()
        self.storageReference = storage.reference()
        self.imageCacheManager = ImageCacheManager()
    }
    
    // MARK: - Repository logic
    public func upload(key: String, _ image: UIImage) async throws {
        if let data = image.pngData() {
            let imageReference = storageReference.child("\(DocumentConstants.memoriesPath)/\(key)")
            do {
                let _ = try await imageReference.putDataAsync(data)
                // using metadata
                imageCacheManager.cacheImage(origin: String(key), image: image)
            } catch {
                throw ImagesRepositoryError.uploadError
            }
        }
    }
    
    /// 이미지 다운로드 함수
    /// - Parameters:
    ///   - index: Memories에서 Memory의 index이자, 이미지의 이름
    ///   - completion: UIImage publish
    public func read(key: String, _ completion: @escaping ((Result<UIImage, Error>) -> Void)) {
        if let image = imageCacheManager.search(origin: String(key)) {
            completion(.success(image))
            return
        }
        
        let imageReference = storageReference.child("\(DocumentConstants.memoriesPath)/\(key)")
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
                
                self.imageCacheManager.cacheImage(origin: key, image: image)
                completion(.success(image))
                return
            } else {
                completion(.failure(ImagesRepositoryError.readError))
                return
            }
        }
    }
    
    public func delete(key: String) async throws {
        let reference = storageReference.child(key)
        do {
            try await reference.delete()
        } catch {
            throw ImagesRepositoryError.deleteError
        }
    }
}

// MARK: - Magic string
private extension DefaultImagesRepository {
    @frozen enum DocumentConstants {
        static let memoriesPath = "memories"
    }
}
