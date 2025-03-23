import SwiftUI

struct ConfettiView: View {
    @Binding var isShowing: Bool
    let confettiCount: Int
    let confettiSize: CGFloat
    let colors: [Color]
    
    init(
        isShowing: Binding<Bool>,
        confettiCount: Int = 50,
        confettiSize: CGFloat = 10,
        colors: [Color] = [.red, .green, .blue, .yellow, .pink, .purple, .orange]
    ) {
        self._isShowing = isShowing
        self.confettiCount = confettiCount
        self.confettiSize = confettiSize
        self.colors = colors
    }
    
    var body: some View {
        ZStack {
            if isShowing {
                ForEach(0..<confettiCount, id: \.self) { index in
                    ConfettiPiece(
                        color: colors[index % colors.count],
                        size: confettiSize,
                        xSpeed: Double.random(in: 0.7...1.3),
                        ySpeed: Double.random(in: 0.8...1.2),
                        rotation: Double.random(in: 0...360),
                        rotationSpeed: Double.random(in: -90...90)
                    )
                    .offset(
                        x: CGFloat.random(in: -UIScreen.main.bounds.width/2...UIScreen.main.bounds.width/2),
                        y: -UIScreen.main.bounds.height/2 - confettiSize
                    )
                }
            }
        }
        .animation(.none, value: isShowing)
    }
}

struct ConfettiPiece: View {
    let color: Color
    let size: CGFloat
    let xSpeed: Double
    let ySpeed: Double
    let rotation: Double
    let rotationSpeed: Double
    
    @State private var animationCompletionValue: CGFloat = 0
    @State private var showPiece = false
    
    var body: some View {
        Group {
            Rectangle()
                .fill(color)
                .frame(width: size, height: size * 0.4)
                .cornerRadius(2)
                .rotationEffect(.degrees(rotation + (rotationSpeed * Double(animationCompletionValue))))
                .opacity(1.0 - (animationCompletionValue * 0.8))
                .offset(
                    x: xSpeed * size * animationCompletionValue * 8,
                    y: ySpeed * UIScreen.main.bounds.height * animationCompletionValue
                )
        }
        .opacity(showPiece ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.05)) {
                showPiece = true
            }
            
            withAnimation(.easeInOut(duration: Double.random(in: 3...5))) {
                animationCompletionValue = 1
            }
        }
    }
}

struct ConfettiModifier: ViewModifier {
    @Binding var isShowing: Bool
    let confettiSize: CGFloat
    let colors: [Color]
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            ZStack {
                // Primera capa de confeti
                ConfettiView(
                    isShowing: $isShowing,
                    confettiCount: 50,
                    confettiSize: confettiSize,
                    colors: colors
                )
                
                // Segunda capa de confeti (diferente velocidad)
                ConfettiView(
                    isShowing: $isShowing,
                    confettiCount: 30,
                    confettiSize: confettiSize * 1.5,
                    colors: colors
                )
            }
            .allowsHitTesting(false)
        }
    }
}

extension View {
    func confettiCelebration(
        isShowing: Binding<Bool>,
        confettiSize: CGFloat = 10,
        colors: [Color] = [
            Color(hex: "#FF6B6B"), 
            Color(hex: "#4ECDC4"), 
            Color(hex: "#9B5DE5"), 
            Color(hex: "#FEE440"), 
            Color(hex: "#00BBF9")
        ]
    ) -> some View {
        self.modifier(ConfettiModifier(
            isShowing: isShowing,
            confettiSize: confettiSize,
            colors: colors
        ))
    }
}

#Preview {
    VStack {
        Text("¡Meta alcanzada!")
            .font(.largeTitle.bold())
            .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black.opacity(0.1))
    .confettiCelebration(isShowing: .constant(true))
} 