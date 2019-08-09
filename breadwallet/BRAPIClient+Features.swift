//
//  BRAPIClient+Features.swift
//  breadwallet
//
//  Created by Samuel Sutch on 4/2/17.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import Foundation

extension BRAPIClient {
    static func defaultsKeyForFeatureFlag(_ name: String) -> String {
        return "ff:\(name)"
    }
    
    func updateFeatureFlags() {
        
    }
    
    static func featureEnabled(_ flag: BRFeatureFlags) -> Bool {
        if E.isDebug || E.isTestFlight { return true }
        let defaults = UserDefaults.standard
        return defaults.bool(forKey: BRAPIClient.defaultsKeyForFeatureFlag(flag.description))
    }
}
