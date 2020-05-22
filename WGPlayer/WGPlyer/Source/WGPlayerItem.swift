//
//  WGPlayerItem.swift
//  WGPlayer
//
//  Created by Wander Grass on 2020/3/26.
//  Copyright © 2020 master. All rights reserved.
//

import Foundation
import AVFoundation

public enum WGPlayerAspectRatio: Int{
    case `default` = 0
    case sixteenToNine
    case fourToThree
}

public class WGPlayerResource {
    public let name  : String
    public let cover : URL?
    public var subtitle: WGSubtitles?
    public let definitions: [WGPlayerResourceDefinition]
    public var option: PLPlayerOption = PLPlayerOption.default()
    public var isLive: Bool = false
    public var aspestRatio = WGPlayerAspectRatio.sixteenToNine
    /**
     Player recource item with url, used to play single difinition video
     
     - parameter name:      video name
     - parameter url:       video url
     - parameter cover:     video cover, will show before playing, and hide when play
     - parameter subtitles: video subtitles
     */
    public convenience init(
        url: URL
        , option: PLPlayerOption =  PLPlayerOption.default()
        , isLive:Bool = false
        , aspestRatio: WGPlayerAspectRatio = WGPlayerAspectRatio.sixteenToNine
        , name: String = ""
        , cover: URL? = nil
        , subtitle: URL? = nil
    ) {
        let definition = WGPlayerResourceDefinition(url: url, definition: "")
        
        var subtitles: WGSubtitles? = nil
        if let subtitle = subtitle {
            subtitles = WGSubtitles(url: subtitle)
        }
        
        self.init(option:option,isLive:isLive,aspestRatio: aspestRatio,name: name, definitions: [definition], cover: cover, subtitles: subtitles)
    }
    
    /**
     Play resouce with multi definitions
     
     - parameter name:        video name
     - parameter definitions: video definitions
     - parameter cover:       video cover
     - parameter subtitles:   video subtitles
     */
    public init(option:PLPlayerOption
        ,isLive:Bool
        ,aspestRatio:WGPlayerAspectRatio
        , name: String = ""
        , definitions: [WGPlayerResourceDefinition]
        , cover: URL? = nil
        , subtitles: WGSubtitles? = nil) {
        self.name        = name
        self.cover       = cover
        self.subtitle    = subtitles
        self.definitions = definitions
        self.option      = option
        self.isLive      = isLive
        self.aspestRatio = aspestRatio
    }
}


public class WGPlayerResourceDefinition {
    public let url: URL
    public let definition: String
    
    /// An instance of NSDictionary that contains keys for specifying options for the initialization of the AVURLAsset. See AVURLAssetPreferPreciseDurationAndTimingKey and AVURLAssetReferenceRestrictionsKey above.
    public var options: [String : Any]?
    
    var avURLAsset: AVURLAsset {
        get {
            return WGPlayerManager.asset(for: self)
        }
    }
    
    /**
     Video recource item with defination name and specifying options
     
     - parameter url:        video url
     - parameter definition: url deifination
     - parameter options:    specifying options for the initialization of the AVURLAsset
     
     you can add http-header or other options which mentions in https://developer.apple.com/reference/avfoundation/avurlasset/initialization_options
     
     to add http-header init options like this
     ```
     let header = ["User-Agent":"WGPlayer"]
     let definiton.options = ["AVURLAssetHTTPHeaderFieldsKey":header]
     ```
     */
    public init(url: URL, definition: String, options: [String : Any]? = nil) {
        self.url        = url
        self.definition = definition
        self.options    = options
    }
}
