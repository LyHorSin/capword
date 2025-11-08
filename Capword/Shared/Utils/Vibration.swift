//
//  Vibration.swift
//  Capword
//
//  Created by Ly Hor Sin on 8/11/25.
//

import AudioToolbox
import UIKit

import UIKit
import AudioToolbox

struct Vibration {

    enum Feedback {
        case impact(UIImpactFeedbackGenerator.FeedbackStyle)
        case selection
        case notification(UINotificationFeedbackGenerator.FeedbackType)
        case vibrate      // legacy full-device vibration
        case none

        fileprivate func trigger() {
            switch self {
            case .impact(let style):
                UIImpactFeedbackGenerator(style: style).impactOccurred()
            case .selection:
                UISelectionFeedbackGenerator().selectionChanged()
            case .notification(let type):
                UINotificationFeedbackGenerator().notificationOccurred(type)
            case .vibrate:
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            case .none:
                break
            }
        }
    }

    /// Requires a Feedback argument each time.
    static func fire(_ feedback: Feedback) {
        feedback.trigger()
    }
}
