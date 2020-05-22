//
//  WGPlayer.swift
//  WGPlayer
//
//  Created by Wander Grass on 2020/3/25.
//  Copyright © 2020 master. All rights reserved.
//

import UIKit
import PLPlayerKit
import MediaPlayer

/// WGPlayerDelegate to obserbe player state
public protocol WGPlayerDelegate : class {
    func wgPlayer(player: WGPlayer ,playerStateDidChange state: WGPlayerState)
    func wgPlayer(player: WGPlayer ,loadedTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval)
    func wgPlayer(player: WGPlayer ,playTimeDidChange currentTime : TimeInterval, totalTime: TimeInterval)
    func wgPlayer(player: WGPlayer ,playerIsPlaying playing: Bool)
    func wgPlayer(player: WGPlayer, playerOrientChanged isFullscreen: Bool)
}

/**
 Player status emun
 
 - notSetURL:      not set url yet
 - readyToPlay:    player ready to play
 - buffering:      player buffering
 - bufferFinished: buffer finished
 - playedToTheEnd: played to the End
 - error:          error with playing
 */
public enum WGPlayerState {
    case notSetURL
    case readyToPlay
    case buffering
    case bufferFinished
    case playedToTheEnd
    case error
}

enum WGPanDirection: Int {
    case horizontal = 0
    case vertical   = 1
}

open class WGPlayer: UIView {
    open var backBlock:((Bool)->())?
    open var panGesture: UIPanGestureRecognizer!
    open var panGestureCanNotVer: Bool{
        set{
            
        }
        get{
            return WGPlayerConf.enablePlaytimeGestures
        }
    }
    
    /// 计时器
    var timer       : Timer?
    /// 滑动方向
    fileprivate var panDirection = WGPanDirection.horizontal
    /// 音量滑竿
    fileprivate var volumeViewSlider: UISlider!
    
    fileprivate let WGPlayerAnimationTimeInterval:Double                = 4.0
    fileprivate let WGPlayerControlBarAutoFadeOutTimeInterval:Double    = 0.5
    
    /// 用来保存时间状态
    fileprivate var sumTime         : TimeInterval = 0
    
    fileprivate var totalDuration   : TimeInterval{
        return player.totalDuration.seconds
    }
    
    var currentPosition : TimeInterval = 0
    fileprivate var shouldSeekTo    : TimeInterval = 0
    fileprivate var isURLSet        = false
    fileprivate var isSliderSliding = false
    fileprivate var isPauseByUser   = false
    fileprivate var isVolume        = false
    fileprivate var isMaskShowing   = false
    fileprivate var isSlowed        = false
    fileprivate var isMirrored      = false
    private var isPlayToTheEnd = false
    private var playerResource: WGPlayerResource?
    private var player: PLPlayer!
    private var url:URL!
    
    open weak var delegate: WGPlayerDelegate?
    fileprivate var isFullScreen:Bool {
        get {
            return UIApplication.shared.statusBarOrientation.isLandscape
        }
    }
    
    fileprivate var controlView: WGPlayerControlView!
    
    convenience init(controlView: WGPlayerControlView) {
        self.init(frame: CGRect.zero)
        backgroundColor = UIColor.black
        self.controlView = controlView
        self.controlView.delegate = self
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    public func setVideo(url:URL,playerResource: WGPlayerResource){
        self.url = url
        self.playerResource = playerResource
        initPlayer()
        configureVolume()
        controlView.prepareUI(for: playerResource)
    }
    
 
    
}
//open
extension WGPlayer{
    public func play(){
        self.player.play()
    }
    
    public func seek(_ to:TimeInterval, completion: (()->Void)? = nil) {
        player.seek(to: CMTime(seconds: to, preferredTimescale: player.currentTime.timescale))
    }
}

//Action
extension WGPlayer{
    @objc func playButtonAction(){
        if player.isPlaying{
            player.pause()
        }else{
            player.play()
        }
    }
    
    // MARK: - 计时器事件
    @objc fileprivate func playerTimerAction() {
        guard let player = player else {
            return
        }
        if isSliderSliding {
            return
        }
        controlView.playTimeDidChange(currentTime: player.currentTime.seconds, totalTime: player.totalDuration.seconds)
        controlView.totalDuration = player.totalDuration.seconds
    }
    
    // MARK: - Action Response
    
    @objc fileprivate func panDirection(_ pan: UIPanGestureRecognizer) {
        // 根据在view上Pan的位置，确定是调音量还是亮度
        let locationPoint = pan.location(in: self)
        
        // 我们要响应水平移动和垂直移动
        // 根据上次和本次移动的位置，算出一个速率的point
        let velocityPoint = pan.velocity(in: self)
        
        // 判断是垂直移动还是水平移动
        switch pan.state {
        case UIGestureRecognizerState.began:
            // 使用绝对值来判断移动的方向
            let x = abs(velocityPoint.x)
            let y = abs(velocityPoint.y)
            
            if x > y {
                self.panDirection = WGPanDirection.horizontal
                // 给sumTime初值
                self.sumTime = CMTimeGetSeconds(self.player.currentTime)
            } else {
                self.panDirection = WGPanDirection.vertical
                if locationPoint.x > self.bounds.size.width / 2 {
                    self.isVolume = true
                } else {
                    self.isVolume = false
                }
            }
            
        case UIGestureRecognizerState.changed:
            switch self.panDirection {
            case WGPanDirection.horizontal:
                self.horizontalMoved(velocityPoint.x)
            case WGPanDirection.vertical:
                self.verticalMoved(velocityPoint.y)
            }
            
        case UIGestureRecognizerState.ended:
            // 移动结束也需要判断垂直或者平移
            // 比如水平移动结束时，要快进到指定位置，如果这里没有判断，当我们调节音量完之后，会出现屏幕跳动的bug
            switch (self.panDirection) {
            case WGPanDirection.horizontal:
                controlView.hideSeekToView()
                if isPlayToTheEnd {
                    isPlayToTheEnd = false
                    seek(self.sumTime, completion: {
                        self.isSliderSliding = false
                        self.play()
                    })
                } else {
                    seek(self.sumTime) {

                        self.isSliderSliding = false
                        self.play()
                    }
                }
                // 把sumTime滞空，不然会越加越多
                self.sumTime = 0.0
                
            case WGPanDirection.vertical:
                self.isVolume = false
            }
        default:
            break
        }
    }
    
    fileprivate func verticalMoved(_ value: CGFloat) {
        self.isVolume ? (self.volumeViewSlider.value -= Float(value / 10000)) : (UIScreen.main.brightness -= value / 10000)
    }
    
    fileprivate func horizontalMoved(_ value: CGFloat) {
        if panGestureCanNotVer{
            return
        }
        isSliderSliding = true
        // 每次滑动需要叠加时间，通过一定的比例，使滑动一直处于统一水平
        self.sumTime = self.sumTime + TimeInterval(value) / 100.0 * (TimeInterval(self.totalDuration)/400)
        let totalTime       = self.player.totalDuration
        // 防止出现NAN
        if totalTime.timescale == 0 { return }
        let totalDuration   = TimeInterval(totalTime.value) / TimeInterval(totalTime.timescale)
        if (self.sumTime >= totalDuration) { self.sumTime = totalDuration}
        if (self.sumTime <= 0){ self.sumTime = 0}
        
        controlView.showSeekToView(to: sumTime, total: totalDuration, isAdd: value > 0)
        
    }
    
    @objc func onOrientationChanged(){
        controlView.updateUI(isFullScreen)
        delegate?.wgPlayer(player: self, playerOrientChanged: isFullScreen)
        
//        if isFullScreen{
//            if let aspestRatio = self.playerResource?.aspestRatio{
//                var rate:CGFloat = 16/9
//                switch aspestRatio {
//                c
//                    rate = 4 / 3
//                case .sixteenToNine:
//                    rate = 16 / 9
//                default:
//                    rate = 0
//                }
//                if rate > 0{
//                    print("kScreenHeight=\(kScreenHeight),kScreenWidth=\(kScreenWidth)")
//                    if (kScreenWidth/kScreenHeight) >= rate{
//                        player.playerView!.snp.remakeConstraints { (make) in
//                            make.height.equalTo(kScreenHeight)
//                            make.center.equalToSuperview()
//                            make.width.equalTo(kScreenHeight*16/9)
//                        }
//                    }else{
//                        player.playerView!.snp.remakeConstraints { (make) in
//                            make.height.equalTo(kScreenWidth*9/16)
//                            make.center.equalToSuperview()
//                            make.width.equalTo(kScreenWidth)
//                        }
//                    }
//                }
//            }
//
//        }else{
//           player.playerView!.snp.makeConstraints { (make) in
//                make.edges.equalToSuperview()
//            }
//        }
        
    }
    
    @objc fileprivate func fullScreenButtonPressed() {
        controlView.updateUI(!self.isFullScreen)
    }
    
    
}

//UI
extension WGPlayer{
    fileprivate func configureVolume() {
        let volumeView = MPVolumeView()
        for view in volumeView.subviews {
            if let slider = view as? UISlider {
                self.volumeViewSlider = slider
            }
        }
    }
    
    func setupTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(playerTimerAction), userInfo: nil, repeats: true)
        timer?.fireDate = Date()
    }
    
    func initPlayer(){
        setupTimer()
        guard let playerResource = self.playerResource  else {
            return
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.onOrientationChanged), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        print(self.url.absoluteString)
        var format = kPLPLAY_FORMAT_UnKnown
        if self.url.absoluteString.contains(".mp4") {
            format = kPLPLAY_FORMAT_MP4
        } else if self.url.absoluteString.hasPrefix("rtmp:") {
            format = kPLPLAY_FORMAT_FLV
        } else if self.url.absoluteString.contains(".mp3") {
            format = kPLPLAY_FORMAT_MP3
        } else if self.url.absoluteString.contains("m3u8") {
            format = kPLPLAY_FORMAT_M3U8
        }
        playerResource.option.setOptionValue(NSNumber(value: format.rawValue), forKey: PLPlayerOptionKeyVideoPreferFormat)
        player = playerResource.isLive ? PLPlayer(liveWith: self.url, option: playerResource.option) : PLPlayer(url: self.url, option: playerResource.option)
        addSubview(player.playerView!)
        addSubview(controlView)
        player.playerView!.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        controlView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.panDirection(_:)))
        self.addGestureRecognizer(panGesture)
        player.setVolume(AVAudioSession.sharedInstance().outputVolume)
        player.delegateQueue = DispatchQueue.main
        player.delegate = self
        player.loopPlay = false
    }
    
    func unsetPlayer(){
        
    }
}


extension WGPlayer: WGPlayerControlViewDelegate {
    open func controlView(controlView: WGPlayerControlView,
                          didChooseDefition index: Int) {
        
    }
    
    open func controlView(controlView: WGPlayerControlView,
                          didPressButton button: UIButton) {
        if let action = WGPlayerControlView.ButtonType(rawValue: button.tag) {
            switch action {
            case .back:
                backBlock?(isFullScreen)
                if isFullScreen {
                    fullScreenButtonPressed()
                } else {
                    player.stop()
                }
                
            case .play:
                if button.isSelected {
                    player.pause()
                } else {
                    if isPlayToTheEnd {
                        seek(0, completion: {
                            self.play()
                        })
                        controlView.hidePlayToTheEndView()
                        isPlayToTheEnd = false
                    }
                    play()
                }
                
            case .replay:
                isPlayToTheEnd = false
                seek(0)
                play()
                
            case .fullscreen:
                fullScreenButtonPressed()
            default:
                print("[Error] unhandled Action")
            }
        }
    }
    
    open func controlView(
        controlView: WGPlayerControlView,
        slider: UISlider,
        onSliderEvent event: UIControl.Event) {
        switch event {
        case UIControl.Event.touchDown:
            if self.player.status == .statusReady{
                self.timer?.fireDate = Date.distantFuture
            }
            isSliderSliding = true
        case UIControl.Event.touchUpInside :
            isSliderSliding = false
            let target = self.totalDuration * Double(slider.value)
            if isPlayToTheEnd {
                isPlayToTheEnd = false
                seek(target, completion: {
                    self.play()
                })
                controlView.hidePlayToTheEndView()
            } else {
                seek(target) {
                    self.play()
                }
            }
        default:
            break
        }
    }
    
    open func controlView(controlView: WGPlayerControlView, didChangeVideoAspectRatio: WGPlayerAspectRatio) {
    }
    
    open func controlView(controlView: WGPlayerControlView, didChangeVideoPlaybackRate rate: Float) {
        
    }
    
}

extension WGPlayer:PLPlayerDelegate{
    public func player(_ player: PLPlayer, firstRender firstRenderType: PLPlayerFirstRenderType) {
        if firstRenderType == PLPlayerFirstRenderType.video{
            print("width=\(player.width)\n,height=\(player.height)")
        }
    }
    
    public func player(_ player: PLPlayer, width: Int32, height: Int32) {
        
    }
    
    public func player(_ player: PLPlayer, stoppedWithError error: Error?) {
        
    }
    
    public func playerWillEndBackgroundTask(_ player: PLPlayer) {
        
    }
    
    public func playerWillBeginBackgroundTask(_ player: PLPlayer) {
        
    }
    
    public func player(_ player: PLPlayer, loadedTimeRange timeRange: CMTime) {
        
    }
    
    public func player(_ player: PLPlayer, seekToCompleted isCompleted: Bool) {
        
    }
    
    public func player(_ player: PLPlayer, seiData SEIData: Data?, ts: Int64) {
        
    }
    
    public func player(_ player: PLPlayer, statusDidChange state: PLPlayerStatus) {
        controlView.playStateDidChange(isPlaying: state == .statusPlaying)
        delegate?.wgPlayer(player: self, playerIsPlaying: state == .statusPlaying)
    }
    
    
    public func player(_ player: PLPlayer, willRenderFrame frame: CVPixelBuffer?, pts: Int64, sarNumerator: Int32, sarDenominator: Int32) {
        
    }
    
}
