//
//  ImageCacheManagerTests.swift
//  
//
//  Created by 김동욱 on 2023/03/07.
//

import XCTest
@testable import FirebasePlatform

final class ImageCacheManagerTests: XCTestCase {
    var imageCacheManager: ImageCacheable!
    
    override func setUp() {
        super.setUp()
        imageCacheManager = ImageCacheManager()
    }
    
    override func tearDown() {
        imageCacheManager = nil
        super.tearDown()
    }
    
    func testCacheImage() {
        // given
        let index = 3
        let image = UIImage(systemName: "photo")!
        
        XCTAssertNil(imageCacheManager.search(origin: String(index)))
        
        // when
        imageCacheManager.cacheImage(origin: String(index), image: image)
        
        // then
        XCTAssertNotNil(imageCacheManager.search(origin: String(index)))
    }
}
