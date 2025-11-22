//
//  SubscriptionHelper.swift
//  Capword
//
//  Helper for managing subscription prompts based on app usage.
//

import Foundation

class SubscriptionHelper {
    static let shared = SubscriptionHelper()
    
    private let firstLaunchKey = "firstLaunchDate"
    private let hasSubscribedKey = "hasSubscribed"
    
    private init() {
        // Track first launch date
        if UserDefaults.standard.object(forKey: firstLaunchKey) == nil {
            UserDefaults.standard.set(Date(), forKey: firstLaunchKey)
        }
    }
    
    /// Check if the subscription offer should be shown (after 3 days of usage)
    func shouldShowSubscription() -> Bool {
        // Don't show if user already subscribed
        if UserDefaults.standard.bool(forKey: hasSubscribedKey) {
            return false
        }
        
        // Check if 3 days have passed since first launch
        guard let firstLaunch = UserDefaults.standard.object(forKey: firstLaunchKey) as? Date else {
            return false
        }
        
        let daysPassed = Calendar.current.dateComponents([.day], from: firstLaunch, to: Date()).day ?? 0
        return daysPassed >= 3
//        return daysPassed == 0
    }
    
    /// Mark that user has subscribed
    func markAsSubscribed() {
        UserDefaults.standard.set(true, forKey: hasSubscribedKey)
    }
    
    /// Check if user has subscribed
    func hasSubscribed() -> Bool {
        return UserDefaults.standard.bool(forKey: hasSubscribedKey)
    }
    
    /// Reset subscription status (for testing)
    func resetSubscriptionStatus() {
        UserDefaults.standard.removeObject(forKey: hasSubscribedKey)
    }
    
    /// Reset first launch date (for testing)
    func resetFirstLaunchDate() {
        UserDefaults.standard.removeObject(forKey: firstLaunchKey)
    }
}
