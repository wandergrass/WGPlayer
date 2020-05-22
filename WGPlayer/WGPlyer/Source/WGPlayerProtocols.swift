//
//  WGPlayerProtocols.swift
//  WGPlayer
//
//  Created by Wander Grass on 2020/3/26.
//  Copyright © 2020 master. All rights reserved.
//

import UIKit

extension WGPlayerControlView {
    public enum ButtonType: Int {
        case play       = 101
        case pause      = 102
        case back       = 103
        case fullscreen = 105
        case replay     = 106
    }
}

extension WGPlayer {
    static func formatSecondsToString(_ secounds: TimeInterval) -> String {
        if secounds.isNaN {
            return "00:00"
        }
        let Min = Int(secounds / 60)
        let Sec = Int(secounds.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", Min, Sec)
    }
}
