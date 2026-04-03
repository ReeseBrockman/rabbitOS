//
//  StatusBarController.swift
//  rabbitOs
//
//  Created by Reese Brockman on 3/31/26.
//

import AppKit
import SwiftUI

class StatusBarController {
    private var statusItem: NSStatusItem
    private var window: NSWindow?
    private var mouseMonitor: Any?
    private var dismissTimer: Timer?
    private var isShowing = false

    let panelWidth: CGFloat = 179
    let panelHeight: CGFloat = 300
    let xPosition: CGFloat = 646
    let startY: CGFloat = 956
    let targetY: CGFloat = 800

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "🐇"
        }
        setupWindow()
        startMouseTracking()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showWindow()
        }
    }

    func getScreen() -> NSScreen {
        return NSScreen.screens.first(where: { $0.frame.origin == .zero }) ?? NSScreen.main!
    }

    func setupWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: xPosition, y: startY, width: panelWidth, height: panelHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.level = .mainMenu
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.isReleasedWhenClosed = false

        let hostingView = NSHostingView(rootView:
            RabbitView()
                .frame(width: panelWidth, height: panelHeight)
        )
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = CGColor.clear
        window.contentView = hostingView

        self.window = window
        print("Window created")
    }

    func startMouseTracking() {
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self else { return }
            let mouse = NSEvent.mouseLocation
            let screen = self.getScreen()
            let sw = screen.frame.width
            let sh = screen.frame.height

            let inNotchZone = mouse.y > sh - 30 &&
                              mouse.x > (sw / 2) - 150 &&
                              mouse.x < (sw / 2) + 150

            if inNotchZone && !self.isShowing {
                DispatchQueue.main.async {
                    self.showWindow()
                }
            }
        }
    }

    func showWindow() {
        guard let window = window, !isShowing else { return }
        isShowing = true

        window.setFrameOrigin(NSPoint(x: xPosition, y: startY))
        window.orderFrontRegardless()

        NotificationCenter.default.post(name: NSNotification.Name("PanelDidShow"), object: nil)

        let steps = 40
        let stepSize = (startY - targetY) / CGFloat(steps)

        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.01) {
                let y = self.startY - (stepSize * CGFloat(i))
                window.setFrameOrigin(NSPoint(x: self.xPosition, y: y))
            }
        }

        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: false) { [weak self] _ in
            self?.hideWindow()
        }
    }

    func hideWindow() {
        guard let window = window, isShowing else { return }

        let steps = 40
        let stepSize = (startY - targetY) / CGFloat(steps)

        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.01) {
                let y = self.targetY + (stepSize * CGFloat(i))
                window.setFrameOrigin(NSPoint(x: self.xPosition, y: y))
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            window.orderOut(nil)
            self.isShowing = false
        }
    }
}
