//
//  Data+PKCEEncoding.swift
//  Auth0PKCETest
//
//  Created by Kostiantyn Sokolinskyi on 2018-01-25.
//  Copyright © 2018 Omni Mobile Works Inc. All rights reserved.
//

import Foundation

// MARK: Data extension for codes encoding
extension Data {
    func pkceEncodedString() -> String {
        return self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)

    }
}

