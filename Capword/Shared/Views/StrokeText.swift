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

    // Ensure multiline wrapping respects the label's current width when used
    // inside SwiftUI. UIKit uses `preferredMaxLayoutWidth` for multiline
    // intrinsic sizing — update it whenever the label's bounds change so
    // SwiftUI layout and autolayout can compute correct height.
    override func layoutSubviews() {
        super.layoutSubviews()

        // Only update when width actually changed to avoid unnecessary redraws
        let currentWidth = bounds.size.width
        if preferredMaxLayoutWidth != currentWidth {
            preferredMaxLayoutWidth = currentWidth
            // Redraw text (stroke) for the new wrapping / layout
            setNeedsDisplay()
            invalidateIntrinsicContentSize()
        }
    }

    // Provide an intrinsic content size based on current `preferredMaxLayoutWidth`
    // so SwiftUI can measure the view's height correctly when the width is constrained
    // by parent layout. We use `sizeThatFits(_:)` to compute the appropriate height
    // for multiline text and return `noIntrinsicMetric` for width so SwiftUI can
    // drive the width from its layout constraints (e.g. `.frame(width:)`).
    override var intrinsicContentSize: CGSize {
        // If we don't have a width yet, fall back to the preferredMaxLayoutWidth
        // or a reasonable default to avoid returning zero height during initial layout.
        let width = max(preferredMaxLayoutWidth, bounds.width, 10)
        let fitting = CGSize(width: width, height: .greatestFiniteMagnitude)
        let size = self.sizeThatFits(fitting)
        // Return flexible width (so SwiftUI can set width) and concrete height
        return CGSize(width: UIView.noIntrinsicMetric, height: ceil(size.height))
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
        // Allow unlimited lines and wrapping so the label can display multi-line text
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = textAlignment
        label.backgroundColor = .clear
        label.clipsToBounds = false
        label.translatesAutoresizingMaskIntoConstraints = false
        // Ensure the label resists being compressed so SwiftUI sizing works predictably
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
        uiView.numberOfLines = 0
        uiView.lineBreakMode = .byWordWrapping
    }
}
