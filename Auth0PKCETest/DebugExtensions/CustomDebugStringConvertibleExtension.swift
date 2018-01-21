//
//  CustomDebugStringConvertibleExtension.swift
//  Auth0PKCETest
//
//  Created by Kostiantyn Sokolinskyi on 2018-01-21.
//  Copyright © 2018 Omni Mobile Works Inc. All rights reserved.
//

import Foundation

extension CustomDebugStringConvertible {
    
    var debugDescription : String {
        var description = "\n*** \(type(of: self)) ***\n"
        let selfMirror = Mirror(reflecting: self)
        for child in selfMirror.children {
            if let propertyName = child.label {
                description += "\(propertyName): '\(child.value)'\n"
            }
        }
        return description
    }
}
