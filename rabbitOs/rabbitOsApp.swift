//
//  rabbitOsApp.swift
//  rabbitOs
//
//  Created by Reese Brockman on 3/31/26.
//

import AppKit
import SwiftUI

@main
struct rabbitOsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusBarController = StatusBarController()
    }
}
