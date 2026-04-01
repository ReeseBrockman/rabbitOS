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

    let panelWidth: CGFloat = 178
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
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.isReleasedWhenClosed = false

        let hostingView = NSHostingView(rootView:
            RabbitView()
                .frame(width: panelWidth, height: panelHeight)
                .clipShape(RoundedCorners(radius: 16))
        )
        hostingView.wantsLayer = true
        hostingView.layer?.cornerRadius = 16
        hostingView.layer?.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        hostingView.layer?.masksToBounds = true
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

        let steps = 40
        let stepSize = (startY - targetY) / CGFloat(steps)

        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.01) {
                let y = self.startY - (stepSize * CGFloat(i))
                window.setFrameOrigin(NSPoint(x: self.xPosition, y: y))
            }
        }

        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
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

    struct RoundedCorners: Shape {
        var radius: CGFloat
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height - radius))
            path.addQuadCurve(to: CGPoint(x: rect.width - radius, y: rect.height), control: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: radius, y: rect.height))
            path.addQuadCurve(to: CGPoint(x: 0, y: rect.height - radius), control: CGPoint(x: 0, y: rect.height))
            path.closeSubpath()
            return path
        }
    }
}
