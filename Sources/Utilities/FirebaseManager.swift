//
//  FirebaseConfigure.swift
//  FirebasePlatform
//
//  Created by 김동욱 on 2023/02/20.
//

import Foundation
import FirebaseCore

public final class FirebaseManager {
    public static func configure() {
        DispatchQueue.main.async {
            FirebaseApp.configure()
        }
    }
}
