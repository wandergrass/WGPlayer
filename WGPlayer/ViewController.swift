//
//  ViewController.swift
//  WGPlayer
//
//  Created by master on 2020/3/18.
//  Copyright © 2020 master. All rights reserved.
//

import UIKit

let multipliedBy:CGFloat = 9/16.0
//是不是齐刘海

/// 屏幕宽
let kScreenWidth = UIScreen.main.bounds.width
/// 屏幕高
let kScreenHeight = UIScreen.main.bounds.height

let ssl_url = "https://vod.haoyishu.org/vod/m3u8/b7b08bd0aa00b052241597e9ec700b38/middle/b7b08bd0aa00b052241597e9ec700b38.m3u8?auth_key=1585036317-0-0-178ba640156f45c064c9dca0c978f74f"
class ViewController: UIViewController {
var offsetIphoneX:CGFloat =  24
    var player: WGPlayer!
    override func viewDidLoad() {
        super.viewDidLoad()
        initPlayer()
 
        // Do any additional setup after loading the view.
    }

    
    func initPlayer() {
        let controllView = WGPlayerControlView()
        player = WGPlayer(controlView: controllView)
        view.addSubview(player)
        player.delegate = self
        let resource = WGPlayerResource(url: URL(string: ssl_url)!, option: PLPlayerOption.default(), isLive: false, aspestRatio: WGPlayerAspectRatio.sixteenToNine, name: "", cover: nil, subtitle: nil)
        player.setVideo(url:URL(string: ssl_url)!,playerResource: resource)
        player.snp.makeConstraints { [unowned self]  (make) in
            make.top.equalToSuperview().offset(offsetIphoneX)
            make.left.right.equalTo(self.view)
            // 注意此处，宽高比 16:9 优先级比 1000 低就行，在因为 iPhone 4S 宽高比不是 16：9
            make.height.equalTo(player.snp.width).multipliedBy(multipliedBy)
        }
        
        player.play()

    }

}


extension ViewController: WGPlayerDelegate{
    func wgPlayer(player: WGPlayer, playerStateDidChange state: WGPlayerState) {
        
    }
    
    func wgPlayer(player: WGPlayer, loadedTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval) {
        
    }
    
    func wgPlayer(player: WGPlayer, playTimeDidChange currentTime: TimeInterval, totalTime: TimeInterval) {
        
    }
    
    func wgPlayer(player: WGPlayer, playerIsPlaying playing: Bool) {
        
    }
    
    func wgPlayer(player: WGPlayer, playerOrientChanged isFullscreen: Bool) {
        if isFullscreen{
            player.snp.remakeConstraints { [unowned self]  (make) in
                make.edges.equalToSuperview()
            }
            
        }else{
            player.snp.remakeConstraints { [unowned self]  (make) in
                make.top.equalToSuperview().offset(offsetIphoneX)
                make.left.right.equalTo(self.view)
                // 注意此处，宽高比 16:9 优先级比 1000 低就行，在因为 iPhone 4S 宽高比不是 16：9
                make.height.equalTo(player.snp.width).multipliedBy(multipliedBy)
            }
        }
    }
    
   

}
