import SwiftUI

struct SnowView: View {
    @State private var flakes: [Flake] = []
    let count: Int

    init(count: Int = 20) {
        self.count = count
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(flakes) { f in
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: f.size, height: f.size)
                        .position(x: f.x * geo.size.width, y: f.y * geo.size.height)
                        .opacity(f.opacity)
                }
            }
            .onAppear {
                flakes = (0..<count).map { i in
                    Flake(id: i, x: Double.random(in: 0...1), y: Double.random(in: -0.5...0.0), size: Double.random(in: 4...10), speed: Double.random(in: 0.2...0.9), opacity: Double.random(in: 0.6...1.0))
                }
                withAnimation(.linear.repeatForever(autoreverses: false)) {
                    animateFlakes(geo: geo)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func animateFlakes(geo: GeometryProxy) {
        for i in flakes.indices {
            let fall = Double.random(in: 6...12) * flakes[i].speed
            let delay = Double.random(in: 0...1.5)
            withAnimation(.linear(duration: fall).delay(delay)) {
                flakes[i].y = 1.2 + Double.random(in: 0...0.4)
                flakes[i].x += Double.random(in: -0.1...0.1)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            for i in flakes.indices {
                flakes[i].y = Double.random(in: -0.5...0.0)
                flakes[i].x = Double.random(in: 0...1)
            }
            animateFlakes(geo: geo)
        }
    }

    private struct Flake: Identifiable {
        let id: Int
        var x: Double
        var y: Double
        var size: Double
        var speed: Double
        var opacity: Double
    }
}

struct SnowView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.blue
            SnowView()
        }
        .frame(height: 200)
    }
}
