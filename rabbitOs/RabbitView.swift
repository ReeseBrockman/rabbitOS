//
//  RabbitView.swift
//  rabbitOs
//
//  Created by Reese Brockman on 3/31/26.
//

import SwiftUI
import Combine

struct RabbitView: View {
    @State private var mouseX: CGFloat = 0
    @State private var mouseY: CGFloat = 0
    @State private var stars: [Star] = Star.generate(count: 80)
    @State private var shootingStars: [ShootingStar] = []
    @State private var clouds: [Cloud] = [
        Cloud(x: 89, y: 210, speed: 25, shape: Cloud.shapes[0]),
        Cloud(x: 89, y: 240, speed: 30, shape: Cloud.shapes[1])
    ]
    
    let panelWidth: CGFloat = 178
    let panelHeight: CGFloat = 300
    let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()
    
    private var isDay: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 6 && hour < 18
    }
    
    private var eyeChar: String {
        let center: CGFloat = 89
        if mouseX < center - 20 { return "(•.-)" }
        if mouseX > center + 20 { return "(-.•)" }
        return "(•.•)"
    }
    
    private var bunnyFace: String {
        let eyes = eyeChar
        if isDay {
            return """
            /)/)
            \(eyes)
            O_(")(")
            """
        } else {
            return """
            (\\(\\
            (-.-) 
            O_(")(")
            """
        }
    }
    
    var body: some View {
        ZStack {
            (isDay ? Color.white : Color.black)
            
            // Stars (night only)
            if !isDay {
                ForEach(stars) { star in
                    Text(star.char)
                        .font(.system(size: star.size, design: .monospaced))
                        .foregroundColor(.white)
                        .opacity(star.opacity)
                        .position(x: star.x, y: star.y)
                }
            }
            
            // Shooting stars (night only)
            if !isDay {
                ForEach(shootingStars) { s in
                    Text("_")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white)
                        .opacity(s.opacity)
                        .position(x: s.x, y: s.y)
                        .rotationEffect(.degrees(45))
                }
            }
            
            // Clouds (day only)
            if isDay {
                ForEach(clouds) { cloud in
                    Text(cloud.shape)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Color(red: 0, green: 0.443, blue: 0.890))
                        .fixedSize()
                        .position(x: cloud.x, y: cloud.y)
                }
            }

            // Bunny
            Text(bunnyFace)
                .font(.system(size: 16, design: .monospaced))
                .foregroundColor(isDay ? Color(red: 0, green: 0.443, blue: 0.890) : .white)
                .multilineTextAlignment(.center)
                .position(x: panelWidth / 2, y: panelHeight / 1.2)
        }
        .frame(width: panelWidth, height: panelHeight)
        .onReceive(timer) { _ in
            updateStars()
            updateShootingStars()
            updateClouds()
            trackMouse()
        }
    }
    
    func trackMouse() {
        let mouse = NSEvent.mouseLocation
        if let screen = NSScreen.main {
            mouseX = mouse.x - (screen.frame.width / 2 - panelWidth / 2)
            mouseY = mouse.y
        }
    }
    
    func updateStars() {
        for i in stars.indices {
            stars[i].phase += 0.02
            let wave = (sin(stars[i].phase) + 1) / 2
            stars[i].opacity = 0.2 + wave * 0.7
        }
    }
    
    func updateShootingStars() {
        for i in shootingStars.indices {
            shootingStars[i].x += shootingStars[i].dx
            shootingStars[i].y += shootingStars[i].dy
            shootingStars[i].elapsed += 0.05
            let progress = shootingStars[i].elapsed / shootingStars[i].life
            if progress < 0.2 {
                shootingStars[i].opacity = progress / 0.2 * 0.85
            } else if progress > 0.75 {
                shootingStars[i].opacity = (1 - (progress - 0.75) / 0.25) * 0.85
            } else {
                shootingStars[i].opacity = 0.85
            }
        }
        shootingStars.removeAll { $0.elapsed >= $0.life }
        if shootingStars.count < 2 && Double.random(in: 0...1) < 0.02 {
            shootingStars.append(ShootingStar.spawn(in: CGSize(width: panelWidth, height: panelHeight)))
        }
    }
    
    func updateClouds() {
        guard isDay else {
            clouds.removeAll()
            return
        }
        for i in clouds.indices {
            clouds[i].x += clouds[i].speed * 0.016
        }
        clouds.removeAll { $0.x > panelWidth + 150 }
        if clouds.count < 3 {
            let lastX = clouds.map { $0.x }.max() ?? 0
            if lastX > 60 || clouds.isEmpty {
                clouds.append(Cloud(
                    x: -50,
                    y: CGFloat.random(in: 205...245),
                    speed: CGFloat.random(in: 25...35),
                    shape: Cloud.shapes.randomElement()!
                ))
            }
        }
    }
}

// MARK: - Models

struct Star: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let char: String
    let size: CGFloat
    var phase: CGFloat
    var opacity: CGFloat = 0.5

    static func generate(count: Int) -> [Star] {
        let chars = ["*", "+", "."]
        return (0..<count).map { _ in
            Star(
                x: CGFloat.random(in: 0...178),
                y: CGFloat.random(in: 0...300),
                char: chars.randomElement()!,
                size: CGFloat.random(in: 8...14),
                phase: CGFloat.random(in: 0...CGFloat.pi * 2)
            )
        }
    }
}

struct ShootingStar: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let dx: CGFloat
    let dy: CGFloat
    var opacity: CGFloat = 0
    var elapsed: CGFloat = 0
    let life: CGFloat

    static func spawn(in size: CGSize) -> ShootingStar {
        let angle = CGFloat.random(in: 28...50) * .pi / 180
        let speed = CGFloat.random(in: 40...80)
        return ShootingStar(
            x: CGFloat.random(in: 0...size.width),
            y: CGFloat.random(in: 0...size.height * 0.6),
            dx: cos(angle) * speed * 0.05,
            dy: sin(angle) * speed * 0.05,
            life: CGFloat.random(in: 2.5...4.5)
        )
    }
}

struct Cloud: Identifiable {
    let id = UUID()
    var x: CGFloat
    let y: CGFloat
    let speed: CGFloat
    let shape: String

    static let shapes = [
        "  ____\n.(      ).__\n(_____(   ).__\n     (______)",
        "  ____\n _(    )__\n(____(  )_\n  (______)",
        " ____\n_(    )____\n (_____(  )__\n      (_____)"
    ]

    static func spawn(panelWidth: CGFloat) -> Cloud {
        Cloud(
            x: -50,
            y: CGFloat.random(in: 200...260),
            speed: CGFloat.random(in: 20...40),
            shape: shapes.randomElement()!
        )
    }
}
