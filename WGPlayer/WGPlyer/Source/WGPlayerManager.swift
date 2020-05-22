//
//  WGPlayerManager.swift
//  WGPlayer
//
//  Created by Wander Grass on 2020/3/26.
//  Copyright © 2020 master. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation


public let WGPlayerConf = WGPlayerManager.shared

public enum WGPlayerTopBarShowCase: Int {
    case always         = 0 /// 始终显示
    case horizantalOnly = 1 /// 只在横屏界面显示
    case none           = 2 /// 不显示
}

open class WGPlayerManager {
    /// 单例
    public static let shared = WGPlayerManager()
    
    /// tint color
    open var tintColor   = UIColor("FF6E27")
    
    /// Loader
    open var loaderType  = NVActivityIndicatorType.ballRotateChase
    
    /// should auto play
    open var shouldAutoPlay = true
    
    open var topBarShowInCase = WGPlayerTopBarShowCase.always
    
    open var animateDelayTimeInterval = TimeInterval(5)
    
    /// should show log
    open var allowLog  = false
    
    /// use gestures to set brightness, volume and play position
    open var enableBrightnessGestures = true
    open var enableVolumeGestures = true
    open var enablePlaytimeGestures = true
    open var enableChooseDefinition = true
    
    internal static func asset(for resouce: WGPlayerResourceDefinition) -> AVURLAsset {
        return AVURLAsset(url: resouce.url, options: resouce.options)
    }
    
    /**
     打印log
     
     - parameter info: log信息
     */
    func log(_ info:String) {
        if allowLog {
            print(info)
        }
    }
}


//MARK: color fun extention
extension UIColor{
    //16进制颜色 UIColor("ffeeaa")
    public convenience init(_ hexColor: String,_ alpha:CGFloat = 1){
        var colorString = hexColor
        if colorString.hasPrefix("#"){
            colorString.removeFirst()
        }
        // 存储转换后的数值
        var red:UInt32 = 0, green:UInt32 = 0, blue:UInt32 = 0
        // 分别转换进行转换
        Scanner(string: colorString[0..<2]).scanHexInt32(&red)
        Scanner(string: colorString[2..<4]).scanHexInt32(&green)
        Scanner(string: colorString[4..<6]).scanHexInt32(&blue)
        self.init(red: CGFloat(red)/255.0, green: CGFloat(green)/255.0, blue: CGFloat(blue)/255.0, alpha: alpha)
    }
}

extension String {
    subscript (r: Range<Int>) -> String {//自定义下标
        get {
            let startIndex = self.index(self.startIndex, offsetBy: r.lowerBound)
            let endIndex = self.index(self.startIndex, offsetBy: r.upperBound)
            return String(self[startIndex..<endIndex])
        }
    }
}
