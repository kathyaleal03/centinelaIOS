import SwiftUI

struct RainView: View {
    @State private var drops: [Drop] = []
    let count: Int

    init(count: Int = 20) {
        self.count = count
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(drops) { drop in
                    Rectangle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 1, height: drop.length)
                        .position(x: drop.x * geo.size.width, y: drop.y * geo.size.height)
                        .rotationEffect(.degrees(-20))
                        .blendMode(.screen)
                }
            }
            .onAppear {
                drops = (0..<count).map { i in
                    Drop(id: i, x: Double.random(in: 0...1), y: Double.random(in: -0.5...0.0), length: Double.random(in: 8...18), speed: Double.random(in: 0.6...1.6))
                }
                withAnimation(.linear.repeatForever(autoreverses: false).speed(1)) {
                    animateDrops(geo: geo)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func animateDrops(geo: GeometryProxy) {
        for i in drops.indices {
            let fall = Double.random(in: 1.2...2.0) * drops[i].speed
            let delay = Double.random(in: 0...1.0)
            withAnimation(.linear(duration: fall).delay(delay)) {
                drops[i].y = 1.2 + Double.random(in: 0...0.3)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            // reset
            for i in drops.indices {
                drops[i].y = Double.random(in: -0.5...0.0)
                drops[i].x = Double.random(in: 0...1)
            }
            animateDrops(geo: geo)
        }
    }

    private struct Drop: Identifiable {
        let id: Int
        var x: Double
        var y: Double
        var length: Double
        var speed: Double
    }
}

struct RainView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.blue
            RainView()
        }
        .frame(height: 200)
    }
}
