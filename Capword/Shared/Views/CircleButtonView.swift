//
//  CircleButtonView.swift
//  Capword
//
//  Created by Ly Hor Sin on 8/11/25.
//

import SwiftUI

struct CircleButtonView: View {
    
    var systemNameIcon: String
    var action: () -> Void
    
    var body: some View {
        Button(action: {
            Vibration.fire(.impact(.soft))
            action()
        }) {
            CircleButtonLabel(systemNameIcon: systemNameIcon)
        }
    }
}


struct CircleButtonLabel: View {
    var systemNameIcon: String

    var body: some View {
        Image(systemName: systemNameIcon)
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(AppTheme.primary)
            .frame(width: 32, height: 32)
            .background(Color.white)
            .clipShape(Circle())
            .contentShape(Circle())
    }
}
