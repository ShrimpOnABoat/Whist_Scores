//
//  DealerButton.swift
//  Whist Scores
//
//  Created by Tony Buffard on 2025-04-05.
//

//
//  DealerButton.swift
//  Whist
//
//  Created by Tony Buffard on 2024-12-14.
//

import SwiftUI

struct DealerButton: View {
    // Add a size variable to control the button's overall size
    var size: CGFloat = 50
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 1)
                )

            Text("D")
                .font(.system(size: size * 0.6, weight: .bold))
                .foregroundColor(.black)
        }
    }
}

struct TwoCardsIcon: View {
    var size: CGFloat = 30

    var body: some View {
        ZStack {
            // Second card (back)
            RoundedRectangle(cornerRadius: size * 0.1)
                .fill(Color.white)
                .frame(width: size * 0.7, height: size)
                .shadow(color: .gray.opacity(0.3), radius: size * 0.1, x: size * 0.05, y: size * 0.05)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.1)
                        .stroke(Color.black.opacity(0.6), lineWidth: 1)
                )
                .rotationEffect(.degrees(-10))
                .offset(x: -size * 0.1)

            // Front card
            RoundedRectangle(cornerRadius: size * 0.1)
                .fill(Color.white)
                .frame(width: size * 0.7, height: size)
                .shadow(color: .gray.opacity(0.3), radius: size * 0.1, x: size * 0.05, y: size * 0.05)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.1)
                        .stroke(Color.black.opacity(0.6), lineWidth: 1)
                )
                .overlay(
                    Text("♥️")
                        .font(.system(size: size * 0.6))
                )
                .rotationEffect(.degrees(10))
                .offset(x: size * 0.1)
        }
        .background(Color.clear)
    }
}

struct OneCardIcon: View {
    var size: CGFloat = 30

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.1)
                .fill(Color.white)
                .frame(width: size * 0.7, height: size)
                .shadow(color: .gray.opacity(0.3), radius: size * 0.1, x: size * 0.05, y: size * 0.05)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.1)
                        .stroke(Color.black.opacity(0.6), lineWidth: 1)
                )

            Text("♠️")
                .font(.system(size: size * 0.6))
        }
        .background(Color.clear)
    }
}

struct DealerButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            DealerButton(size: 25) // Large size
            TwoCardsIcon(size: 40) // Sample CardIcon
            OneCardIcon(size: 40) // Sample CardIcon
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
