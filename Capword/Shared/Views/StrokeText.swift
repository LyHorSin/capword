//
//  StrokeText.swift
//  Capword
//
//  Created by Ly Hor Sin on 15/11/25.
//
import SwiftUI

class StrokeLabel: UILabel {
    @IBInspectable var strokeSize: CGFloat = 0
    @IBInspectable var strokeColor: UIColor = .clear
  
    override func drawText(in rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        let textColor = self.textColor
        context?.setLineWidth(self.strokeSize)
        context?.setLineJoin(.miter)
        context?.setTextDrawingMode(.stroke)
        self.textColor = self.strokeColor
        super.drawText(in: rect)
        context?.setTextDrawingMode(.fill)
        self.textColor = textColor
        super.drawText(in: rect)
    }
}


struct StrokeLabelView: UIViewRepresentable {
    var text: String
    var font: UIFont
    var textColor: UIColor
    var strokeColor: UIColor
    var strokeSize: CGFloat
    var textAlignment: NSTextAlignment = .center
    
    func makeUIView(context: Context) -> StrokeLabel {
        let label = StrokeLabel()
        label.numberOfLines = 0
        label.textAlignment = textAlignment
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }
    
    func updateUIView(_ uiView: StrokeLabel, context: Context) {
        uiView.text = text
        uiView.font = font
        uiView.textColor = textColor
        uiView.strokeColor = strokeColor
        uiView.strokeSize = strokeSize
        uiView.textAlignment = textAlignment
    }
}
