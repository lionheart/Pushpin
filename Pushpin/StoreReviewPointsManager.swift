//
//  StoreReviewPointsManager.swift
//  Pushpin
//
//  Created by Daniel Loewenherz on 10/20/17.
//  Copyright © 2017 Lionheart Software. All rights reserved.
//

import Foundation
import StoreKit

@objc enum StoreReviewValue: Int, Codable {
    case high
    case medium
    case low

    var value: NSDecimalNumber {
        switch self {
            case .high: return 100
            case .medium: return 10
            case .low: return 1
        }
    }
}

@objc enum StoreReviewHalfLife: Int {
    case hour
    case day
    case week
    case month

    var seconds: Int {
        switch self {
            case .hour: return 60*60
            case .day: return StoreReviewHalfLife.hour.seconds * 24
            case .week: return StoreReviewHalfLife.day.seconds * 7
            case .month: return StoreReviewHalfLife.week.seconds * 4
        }
    }
}

struct StoreReviewAction: Codable {
    var initialValue: StoreReviewValue
    var halfLife: Int
    var createdOn: Date

    var value: NSDecimalNumber {
        let now = Date()
        let interval = now.timeIntervalSince(createdOn)
        let exponent = NSDecimalNumber(value: pow(0.5, interval))
        return initialValue.value.multiplying(by: exponent)
    }

    init(value: StoreReviewValue, halfLife: Int) {
        self.initialValue = value
        self.halfLife = halfLife
        createdOn = Date()
    }
}

@objc class StoreReviewPointsManager: NSObject {
    var actions: [StoreReviewAction] = []
    var promptThreshold: NSDecimalNumber!

    var data: Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(actions)
    }

    var value: NSDecimalNumber {
        return actions.reduce(NSDecimalNumber.zero, {
            $1.value.adding($0)
        })
    }

    let fileURL: URL = {
        let directories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentsDirectory = directories.first else {
            return URL(fileURLWithPath: "/tmp/points.txt")
        }

        return documentsDirectory.appendingPathComponent("/points.txt")
    }()

    // MARK: -

    @objc init(threshold: NSDecimalNumber) {
        let decoder = JSONDecoder()
        if let data = try? Data(contentsOf: fileURL),
           let _actions = try? decoder.decode([StoreReviewAction].self, from: data) {
            actions = _actions
        }

        promptThreshold = threshold
    }

    // MARK: -

    @objc func save() throws {
        try data?.write(to: fileURL)
    }

    @objc func addAction(value: StoreReviewValue, halfLife: StoreReviewHalfLife) {
        actions.append(StoreReviewAction(value: value, halfLife: halfLife.seconds))

        if self.value.compare(promptThreshold) == .orderedDescending {
            SKStoreReviewController.requestReview()

            actions.removeAll()
        }

        try? save()
    }
}

