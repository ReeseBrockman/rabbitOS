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
    @State private var zFloats: [ZFloat] = []
    @State private var lastZSpawn: CFTimeInterval = CACurrentMediaTime()
    @State private var lastStar1Fire: CFTimeInterval = 0
    @State private var lastStar2Fire: CFTimeInterval = 0
    
    let panelWidth: CGFloat = 179
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
            (isDay ? Color.white : Color(red: 0.05, green: 0.05, blue: 0.05, opacity: 1.0))
            
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
            
            // Shooting stars
            ForEach(shootingStars) { s in
                Text("_")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white)
                    .opacity(s.opacity)
                    .position(x: s.x, y: s.y)
                    .rotationEffect(.degrees(45))
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

            // Floating Z's (night only)
            if !isDay {
                ForEach(zFloats) { z in
                    Text("z")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.white)
                        .opacity(z.opacity)
                        .scaleEffect(z.scale)
                        .position(x: z.x, y: z.y)
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
        .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: 16,
            bottomTrailingRadius: 16,
            topTrailingRadius: 0
        ))
        .onReceive(timer) { _ in
            updateStars()
            updateShootingStars()
            updateClouds()
            updateZFloats()
            trackMouse()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PanelDidShow"))) { _ in
            let now = CACurrentMediaTime()
            if lastStar1Fire == 0 {
                lastStar1Fire = now-10
                lastStar2Fire = now-10
            }
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
        let bunnyX = panelWidth / 2
        let bunnyY = panelHeight / 1.2
        let clearRadius: CGFloat = 35

        for i in stars.indices {
            let dx = stars[i].x - bunnyX
            let dy = stars[i].y - bunnyY
            let dist = sqrt(dx * dx + dy * dy)
            if dist < clearRadius {
                stars[i].opacity = 0
                continue
            }
            stars[i].phase += 0.04
            let wave = (sin(stars[i].phase) + 1) / 2
            stars[i].opacity = 0.2 + wave * 0.7
        }
    }
    
    func updateShootingStars() {
        guard lastStar1Fire > 0 else { return }
        let now = CACurrentMediaTime()

        for i in shootingStars.indices {
            shootingStars[i].x += shootingStars[i].dx
            shootingStars[i].y += shootingStars[i].dy
            shootingStars[i].elapsed += 0.016
            let progress = shootingStars[i].elapsed / shootingStars[i].life
            if progress < 0.3 {
                shootingStars[i].opacity = progress / 0.3 * 0.9
            } else if progress > 0.7 {
                shootingStars[i].opacity = (1 - (progress - 0.7) / 0.3) * 0.9
            } else {
                shootingStars[i].opacity = 0.9
            }
        }
        shootingStars.removeAll { $0.elapsed >= $0.life }

        if now - lastStar1Fire >= 10 {
            lastStar1Fire = now
            shootingStars.append(ShootingStar(x: 10, y: 170, dx: 1.5, dy: 0.0, life: 2.0))
        }

        if now - lastStar2Fire >= 10 {
            lastStar2Fire = now
            shootingStars.append(ShootingStar(x: 10, y: 240, dx: 1.5, dy: 0.0, life: 1.0))
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

    func updateZFloats() {
        guard !isDay else {
            zFloats.removeAll()
            return
        }
        for i in zFloats.indices {
            zFloats[i].elapsed += 0.016
            zFloats[i].y -= 0.4
            zFloats[i].x += zFloats[i].dx * 0.016
            let progress = zFloats[i].elapsed / zFloats[i].life
            if progress < 0.15 {
                zFloats[i].opacity = progress / 0.15 * 0.9
            } else if progress > 0.85 {
                zFloats[i].opacity = (1 - (progress - 0.85) / 0.15) * 0.9
            } else {
                zFloats[i].opacity = 0.9
            }
            zFloats[i].scale = 0.8 + progress * 0.3
        }
        zFloats.removeAll { $0.elapsed >= $0.life }

        let now = CACurrentMediaTime()
        if now - lastZSpawn >= 1.75 {
            lastZSpawn = now
            // First Z
            zFloats.append(ZFloat(
                x: panelWidth / 2 + 10,
                y: panelHeight / 1.2 - 20,
                dx: CGFloat.random(in: 5...12)
            ))
            // Second Z spawns slightly after and to the right
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                zFloats.append(ZFloat(
                    x: panelWidth / 2 + 22,
                    y: panelHeight / 1.2 - 30,
                    dx: CGFloat.random(in: 5...12)
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
                x: CGFloat.random(in: 0...179),
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
}

struct ZFloat: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var opacity: CGFloat = 0
    var scale: CGFloat = 0.8
    var elapsed: CGFloat = 0
    let life: CGFloat = 3.5
    let dx: CGFloat
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
