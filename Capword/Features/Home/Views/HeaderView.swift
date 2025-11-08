//
//  HeaderView.swift
//  Capword
//
//  Created by Ly Hor Sin on 8/11/25.
//

import SwiftUI

struct HeaderView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Nov 08")
                .font(AppTheme.TextStyles.caption())
                .foregroundColor(AppTheme.secondary)
            
            Text("Good Morning")
                .font(AppTheme.TextStyles.header())
                .foregroundColor(AppTheme.primary)
            
            Text("Start your day with a new word!")
                .font(AppTheme.TextStyles.subtitle())
                .foregroundColor(AppTheme.secondary)
        }
    }
}
