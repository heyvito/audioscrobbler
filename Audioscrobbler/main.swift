//
//  main.swift
//  Audioscrobbler
//
//  Created by Victor Gama on 25/11/2022.
//

import Cocoa

let app = NSApplication.shared
let appDelegate = AppDelegate()
app.delegate = appDelegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
