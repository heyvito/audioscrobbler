//
//  LaunchAtStartup.swift
//  Audioscrobbler
//
//  Created by Victor Gama on 27/11/2022.
//

import Foundation
import ServiceManagement
import Combine

/*
 Portions copyright (c) Sindre Sorhus
 Taken from https://github.com/sindreorhus/LaunchAtLogin
 Licensed under the MIT License:
 Copyright (c) Sindre Sorhus <sindresorhus@gmail.com> (sindresorhus.com)

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 IN THE SOFTWARE.
 */

class LaunchAtStartup {
    static let bundleIdentifier: String = Bundle.main.bundleIdentifier!
    static var launchAtStartup: Bool {
        get {
            if #available(macOS 13, *) {
                return launchAtStartupMacOS13
            } else {
                return launchAtStartupPreMacOS13
            }
        }
        set {
            if #available(macOS 13, *) {
                launchAtStartupMacOS13 = newValue
            } else {
                launchAtStartupPreMacOS13 = newValue
            }
        }
    }
    
    @available(macOS 13, *)
    private static var launchAtStartupMacOS13: Bool {
        get {
            return SMAppService.mainApp.status == .enabled
        }
        set {
            do {
                if newValue {
                    if SMAppService.mainApp.status == .enabled {
                        try? SMAppService.mainApp.unregister()
                    }

                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to \(newValue ? "enable" : "disable") launch at login: \(error.localizedDescription)")
            }
        }
    }
    
    @available(macOS 10.15, *)
    private static var launchAtStartupPreMacOS13: Bool {
        get {
            guard let jobs = (LaunchAtStartup.self as DeprecationWarningWorkaround.Type).launchJobs else {
                return false
            }
            return jobs.first { ($0["Label"] as? String) == bundleIdentifier }?["OnDemand"] as? Bool ?? false
        }
        
        set {
            SMLoginItemSetEnabled(bundleIdentifier as CFString, newValue)
        }
    }
}
    
private protocol DeprecationWarningWorkaround {
    static var launchJobs: [[String: AnyObject]]? { get }
}
    
extension LaunchAtStartup: DeprecationWarningWorkaround {
    // Workaround to silence "'SMCopyAllJobDictionaries' was deprecated in OS X 10.10" warning
    // Radar: https://openradar.appspot.com/radar?id=5033815495933952
    @available(*, deprecated)
    static var launchJobs: [[String: AnyObject]]? {
        SMCopyAllJobDictionaries(kSMDomainUserLaunchd)?.takeRetainedValue() as? [[String: AnyObject]]
    }
}
