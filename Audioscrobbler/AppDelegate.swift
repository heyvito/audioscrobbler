//
//  AppDelegate.swift
//  Audioscrobbler
//
//  Created by Victor Gama on 25/11/2022.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {

    var popover: NSPopover!
    var statusBarItem: NSStatusItem!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let contentView = MainContentView()
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        popover.delegate = self
        self.popover = popover

        // Create the status item
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))

        if let button = self.statusBarItem.button {

            button.action = #selector(togglePopover(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])

            self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            popover.contentViewController?.view.window?.makeKey()
            Task {
                try? await Task.sleep(nanoseconds: 500_000)
                DispatchQueue.main.async {
                    self.popover.performClose(self)
                }
            }
        }

        self.updateIcon()
        NSApp.activate(ignoringOtherApps: true)
    }

    func updateIcon() {
        if let button = self.statusBarItem.button {
            button.image = NSImage(named: "as-logo-\(Defaults.shared.privateSession ? "alpha" : "opaque")")
        }
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = self.statusBarItem.button {
            let event = NSApp.currentEvent!
            if event.type == NSEvent.EventType.rightMouseUp {
                if self.popover.isShown {
                    self.popover.performClose(sender)
                }

                let statusBarMenu = NSMenu()
                let quitItem = NSMenuItem(title: "Quit Audioscrobbler", action: #selector(self.applicationQuit), keyEquivalent: "")
                quitItem.target = self
                statusBarMenu.addItem(quitItem)

                NSMenu.popUpContextMenu(statusBarMenu, with:event, for: self.statusBarItem.button!)
            } else {
                if self.popover.isShown {
                    self.popover.performClose(sender)
                } else {
                    self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                    popover.contentViewController?.view.window?.makeKey()
                }
            }
        }
    }

    func popoverWillClose(_ notification: Notification) {
        NotificationCenter.default.post(name: NSNotification.Name("AudioscrobblerWillHide"), object: nil)
    }

    @objc func applicationQuit() {
        NSApplication.shared.terminate(self)
    }
}
