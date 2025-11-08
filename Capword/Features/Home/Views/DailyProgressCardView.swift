//
//  DailyProgressCardView.swift
//  Capword
//
//  Created by Ly Hor Sin on 8/11/25.
//

import SwiftUI

struct DailyProgressCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("November")
                .font(AppTheme.TextStyles.title())
                .foregroundColor(AppTheme.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Nov 08")
                    .font(.title2)
                    .foregroundColor(AppTheme.primary)
                
                Text("Can you snap 5 words today?")
                    .foregroundColor(AppTheme.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCardStyle()
        }
    }
}
