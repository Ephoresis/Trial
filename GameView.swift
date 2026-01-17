import SwiftUI

struct Prey: Identifiable {
    enum PreyType {
        case air
        case ground
    }

    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var speed: CGFloat
    var type: PreyType
}

struct GameView: View {
    @State private var falconX: CGFloat = 0
    @State private var falconY: CGFloat = 0
    @State private var preys: [Prey] = []
    @State private var score: Int = 0
    @State private var time: Double = 0
    @State private var isGameOver: Bool = false
    @State private var difficulty: Double = 1.0

    // Timer de jogo (60 FPS aproximado)
    let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Fundo
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.green.opacity(0.6)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Solo
                Rectangle()
                    .fill(Color.brown.opacity(0.8))
                    .frame(height: geo.size.height * 0.2)
                    .position(x: geo.size.width / 2,
                              y: geo.size.height * 0.9)

                // Presas
                ForEach(preys) { prey in
                    Circle()
                        .fill(prey.type == .air ? Color.yellow : Color.orange)
                        .frame(width: 24, height: 24)
                        .position(x: prey.x, y: prey.y)
                }

                // Falcão (personagem principal)
                FalconView()
                    .frame(width: 60, height: 60)
                    .position(x: geo.size.width / 2 + falconX,
                              y: geo.size.height / 2 + falconY)

                // HUD
                VStack {
                    HStack {
                        Text("Score: \(score)")
                            .font(.headline)
                            .padding(8)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(8)
                            .foregroundColor(.white)

                        Spacer()

                        Text("Dificuldade: \(Int(difficulty))")
                            .font(.headline)
                            .padding(8)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                    .padding()

                    Spacer()
                }

                // Controlo por arrasto (drag) para mover o falcão
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let centerX = geo.size.width / 2
                                let centerY = geo.size.height / 2
                                falconX = value.location.x - centerX
                                falconY = value.location.y - centerY
                            }
                    )

                if isGameOver {
                    VStack(spacing: 16) {
                        Text("Game Over")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)

                        Text("Score final: \(score)")
                            .foregroundColor(.white)

                        Button("Recomeçar") {
                            restartGame(in: geo.size)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(16)
                }
            }
            .onAppear {
                startGame(in: geo.size)
            }
            .onReceive(timer) { _ in
                updateGame(in: geo.size)
            }
        }
    }

    // MARK: - Lógica de jogo

    private func startGame(in size: CGSize) {
        falconX = 0
        falconY = 0
        preys = []
        score = 0
        time = 0
        difficulty = 1.0
        isGameOver = false
        spawnInitialPreys(in: size)
    }

    private func restartGame(in size: CGSize) {
        startGame(in: size)
    }

    private func spawnInitialPreys(in size: CGSize) {
        for _ in 0..<5 {
            spawnPrey(in: size)
        }
    }

    private func spawnPrey(in size: CGSize) {
        let isAir = Bool.random()
        let type: Prey.PreyType = isAir ? .air : .ground

        let xPos = CGFloat.random(in: 20...(size.width - 20))
        let yPos: CGFloat
        if isAir {
            yPos = CGFloat.random(in: size.height * 0.2...(size.height * 0.6))
        } else {
            yPos = size.height * 0.8
        }

        let baseSpeed: CGFloat = isAir ? 1.0 : 0.5
        let speed = baseSpeed * CGFloat(difficulty)

        let prey = Prey(
            x: xPos,
            y: yPos,
            speed: speed,
            type: type
        )
        preys.append(prey)
    }

    private func updateGame(in size: CGSize) {
        guard !isGameOver else { return }

        time += 1.0 / 60.0

        // Aumentar dificuldade com o tempo
        if Int(time) % 10 == 0 { // a cada ~10s
            difficulty = min(difficulty + 0.01, 10.0)
        }

        // Atualizar posição das presas (voam horizontalmente; as do solo movem-se menos)
        preys = preys.compactMap { prey in
            var newPrey = prey
            let direction: CGFloat = Bool.random() ? 1 : -1
            let delta = newPrey.speed * direction

            newPrey.x += delta

            // Rebater nas margens
            if newPrey.x < 10 { newPrey.x = 10 }
            if newPrey.x > size.width - 10 { newPrey.x = size.width - 10 }

            return newPrey
        }

        // Detetar colisões
        let falconPos = CGPoint(x: size.width / 2 + falconX,
                                y: size.height / 2 + falconY)

        var newPreys: [Prey] = []
        for prey in preys {
            let preyPos = CGPoint(x: prey.x, y: prey.y)
            let distance = hypot(falconPos.x - preyPos.x, falconPos.y - preyPos.y)

            if distance < 40 {
                // Apanhou presa
                score += prey.type == .air ? 2 : 1
                // Não adiciona esta presa, “desaparece”
            } else {
                newPreys.append(prey)
            }
        }
        preys = newPreys

        // Garantir que há sempre presas
        if preys.count < 5 + Int(difficulty) {
            spawnPrey(in: size)
        }

        // Condição simples de game over: tempo limite ou score alvo
        if time > 120 { // 2 minutos
            isGameOver = true
        }
    }
}
