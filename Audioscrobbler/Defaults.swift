//
//  Defaults.swift
//  Audioscrobbler
//
//  Created by Victor Gama on 25/11/2022.
//

import Foundation
import AppKit

class Defaults: ObservableObject {
    static var shared: Defaults = {
        let instance = Defaults()
        return instance
    }()
    
    let defaults: UserDefaults
    
    init() {
        defaults = UserDefaults.standard
        token = defaults.string(forKey: "token")
        name = defaults.string(forKey: "name")
        pro = defaults.bool(forKey: "pro")
        url = defaults.string(forKey: "url")
        picture = defaults.data(forKey: "picture")
        privateSession = defaults.bool(forKey: "privateSession")
    }
    
    @Published var token: String? {
        didSet {
            defaults.set(token, forKey: "token")
        }
    }
    
    @Published var name: String? {
        didSet {
            defaults.set(name, forKey: "name")
        }
    }
    
    @Published var pro: Bool? {
        didSet {
            defaults.set(pro, forKey: "pro")
        }
    }

    @Published var url: String? {
        didSet {
            defaults.set(url, forKey: "url")
        }
    }

    @Published var picture: Data? {
        didSet {
            defaults.set(picture, forKey: "picture")
        }
    }

    @Published var privateSession: Bool {
        didSet {
            defaults.set(privateSession, forKey: "privateSession")
            let del = NSApplication.shared.delegate as! AppDelegate
            del.updateIcon()
        }
    }

    func reset() {
        token = ""
        name = ""
        pro = false
        url = nil
        picture = nil
        privateSession = false
    }
}
