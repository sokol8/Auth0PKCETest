//
//  ViewController+SFSafariViewControllerDelegate.swift
//  Auth0PKCETest
//
//  Created by Kostiantyn Sokolinskyi on 2018-01-31.
//  Copyright © 2018 Omni Mobile Works Inc. All rights reserved.
//

import Foundation
import SafariServices
import CocoaLumberjack

// MARK: - SFSafariViewControllerDelegate
extension ViewController : SFSafariViewControllerDelegate {
    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool){
        DDLogInfo("completed initial load of \(controller)")
    }
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        DDLogInfo("user closed Safari View Controller")
    }
}
