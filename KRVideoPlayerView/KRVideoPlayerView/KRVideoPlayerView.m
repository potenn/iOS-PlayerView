//
//  KRVideoPlayerView.m
//  KnowRecorder
//
//  Created by wenote on 2016. 11. 29..
//  Copyright © 2016년 weMAC. All rights reserved.
//

#import "KRVideoPlayerView.h"

@implementation KRVideoPlayerView
{
    id playbackObserver;
    AVPlayerLayer *playerLayer;
    BOOL viewIsShowing;
}
/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

-(void)setPlayerSettingContentURL:(NSURL*)contentURL{
    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:contentURL];
    self.moviePlayer = [AVPlayer playerWithPlayerItem:playerItem];
    playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.moviePlayer];
    [playerLayer setFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    [self.moviePlayer seekToTime:kCMTimeZero];
    [self.layer addSublayer:playerLayer];
    self.contentURL = contentURL;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerFinishedPlaying) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
    [self.moviePlayer setVolume:0.0f];
    self.playBackTotalTimeLabel.text = [self getStringFromCMTime:self.moviePlayer.currentItem.asset.duration];
    
    [self initializePlayer:self.frame];
}


-(void)awakeFromNib{
    
    [super awakeFromNib];
    
    //Init
    [self.progressBar setValue:0];
    [self.progressBar addTarget:self action:@selector(playerSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.progressBar addTarget:self action:@selector(playerSliderValueEnded:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    
    [self.volumeSlider setValue:0];
    [self.volumeSlider addTarget:self action:@selector(volumeSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.volumeSlider addTarget:self action:@selector(volumeSliderValueEnded:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sliderTapped:)];
    [self.progressBar addGestureRecognizer:tapGesture];
    
    UITapGestureRecognizer *tapGestureForVolumeSlider = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sliderTappedForVolumeSlider:)];
    [self.volumeSlider addGestureRecognizer:tapGestureForVolumeSlider];
    
    
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    //    pinchGesture.delegate = self;
    [self addGestureRecognizer:pinchGesture];
    [self addGestureRecognizer:panGesture];
    
    
    UIColor *whiteColor = [UIColor whiteColor];
    for(UIView *subView in [_volumeControlView subviews]){
        [subView setBackgroundColor:whiteColor];
    }
    
    [self.layer setBorderWidth:1.0f];
    [self.layer setBorderColor:[UIColor colorWithRed:180.f/255.f green:180.f/255.f blue:180.f/255.f alpha:1.0f].CGColor];
    
    
}

-(void)initializePlayer:(CGRect)frame{
    
    self.backgroundColor = [UIColor blackColor];
    viewIsShowing =  NO;
    
    [self.layer setMasksToBounds:YES];
    
    for (UIView *view in [self subviews]) {
        view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    }
    
    CMTime interval = CMTimeMake(10, 1000);
    //    CMTime interval = CMTimeMake(30, 60000);
    __weak __typeof(self) weakself = self;
    
    
    playbackObserver = [self.moviePlayer addPeriodicTimeObserverForInterval:interval queue:dispatch_get_main_queue() usingBlock: ^(CMTime time) {
        
        
        CMTime endTime = CMTimeConvertScale (weakself.moviePlayer.currentItem.asset.duration, weakself.moviePlayer.currentTime.timescale, kCMTimeRoundingMethod_RoundHalfAwayFromZero);
        
        if (CMTimeCompare(endTime, kCMTimeZero) != 0) {
            double normalizedTime = (double) weakself.moviePlayer.currentTime.value / (double) endTime.value;
            weakself.progressBar.value = normalizedTime;
            NSLog(@"Movie Player CurrentTIme Value : %f",(float)weakself.moviePlayer.currentTime.value);
        }
        
        weakself.playBackTimeLabel.text = [weakself getStringFromCMTime:weakself.moviePlayer.currentTime];
    }];
    
    [self showPlayerToolBottomView:NO];
}

- (id)initWithFrame:(CGRect)frame contentURL:(NSURL*)contentURL
{
    self = [super initWithFrame:frame];
    if (self) {
        
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:contentURL];
        self.moviePlayer = [AVPlayer playerWithPlayerItem:playerItem];
        playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.moviePlayer];
        [playerLayer setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [self.moviePlayer seekToTime:kCMTimeZero];
        [self.layer addSublayer:playerLayer];
        self.contentURL = contentURL;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerFinishedPlaying) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
        
        [self initializePlayer:frame];
    }
    return self;
}



-(void) setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [playerLayer setFrame:frame];
}

-(void)play
{
    [self.moviePlayer play];
    self.isPlaying = YES;
    [self.playPauseButton setSelected:YES];
}

-(void)pause
{
    [self.moviePlayer pause];
    self.isPlaying = NO;
    [self.playPauseButton setSelected:NO];
}

-(void)dealloc
{
    [self.moviePlayer removeTimeObserver:playbackObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)sliderTapped:(UIGestureRecognizer *)tap{
    
    UISlider* slider = (UISlider*)tap.view;
    if (slider.highlighted)
        return; // tap on thumb, let slider deal with it
    CGPoint pt = [tap locationInView:slider];
    CGFloat percentage = pt.x / slider.bounds.size.width;
    CGFloat delta = percentage * (slider.maximumValue - slider.minimumValue);
    CGFloat value = slider.minimumValue + delta;
    [slider setValue:value animated:YES];
    
    NSLog(@"Player Slider Value Changed");
    if (self.isPlaying) {
        [self.playPauseButton setSelected:NO];
        [self.moviePlayer pause];
    }
    
    CMTime seekTime = CMTimeMakeWithSeconds(value * (double)self.moviePlayer.currentItem.asset.duration.value/(double)self.moviePlayer.currentItem.asset.duration.timescale, self.moviePlayer.currentTime.timescale);
    [self.moviePlayer seekToTime:seekTime];
    
}

-(void)sliderTappedForVolumeSlider:(UIGestureRecognizer *)tap{
    
    UISlider* slider = (UISlider*)tap.view;
    if (slider.highlighted)
        return; // tap on thumb, let slider deal with it
    CGPoint pt = [tap locationInView:slider];
    CGFloat percentage = pt.x / slider.bounds.size.width;
    CGFloat delta = percentage * (slider.maximumValue - slider.minimumValue);
    CGFloat value = slider.minimumValue + delta;
    [slider setValue:value animated:YES];
    
    [self.moviePlayer setVolume:value];
    
    [self updateUIForVolumeControl:value];
    
}

-(void)updateUIForVolumeControl:(float)value{
    
    float length = _volumeControlView.frame.size.width + 3;
    float oneVolume = 7.f / length;
    UIColor *blueColor = [UIColor colorWithRed:57.f/255.f green:103.f/255.f blue:191.f/255.f alpha:1.0f];
    UIColor *whiteColor = [UIColor whiteColor];
    
    if(value == 0.0f){
        NSLog(@"Zero Volume");
        for(UIView *subView in [_volumeControlView subviews]){
            [subView setBackgroundColor:whiteColor];
        }
    }
    if(oneVolume <= value){
        NSLog(@"One Volume");
        for(UIView *subView in [_volumeControlView subviews]){
            
            if(subView.tag == 0){
                [subView setBackgroundColor:blueColor];
            }else if (subView.tag == 1){
                [subView setBackgroundColor:whiteColor];
            }else if(subView.tag == 2){
                [subView setBackgroundColor:whiteColor];
            }else if(subView.tag == 3){
                [subView setBackgroundColor:whiteColor];
            }else if(subView.tag == 4){
                [subView setBackgroundColor:whiteColor];
            }
            else if(subView.tag == 5){
                [subView setBackgroundColor:whiteColor];
            }else if(subView.tag == 6){
                [subView setBackgroundColor:whiteColor];
            }else if(subView.tag == 7){
                [subView setBackgroundColor:whiteColor];
            }
        }
        
    }if(oneVolume * 2 <= value){
        NSLog(@"Two Volume");
        for(UIView *subView in [_volumeControlView subviews]){
            
            
            if(subView.tag == 0){
                [subView setBackgroundColor:blueColor];
            }else if (subView.tag == 1){
                [subView setBackgroundColor:blueColor];
            }else if(subView.tag == 2){
                [subView setBackgroundColor:whiteColor];
            }else if(subView.tag == 3){
                [subView setBackgroundColor:whiteColor];
            }else if(subView.tag == 4){
                [subView setBackgroundColor:whiteColor];
            }
            else if(subView.tag == 5){
                [subView setBackgroundColor:whiteColor];
            }else if(subView.tag == 6){
                [subView setBackgroundColor:whiteColor];
            }else if(subView.tag == 7){
                [subView setBackgroundColor:whiteColor];
            }
        }
    }if(oneVolume * 3 <= value){
        NSLog(@"Three Volume");
        for(UIView *subView in [_volumeControlView subviews]){
            
            if(subView.tag == 0){
                [subView setBackgroundColor:blueColor];
            }else if (subView.tag == 1){
                [subView setBackgroundColor:blueColor];
            }else if(subView.tag == 2){
                [subView setBackgroundColor:blueColor];
            }else if(subView.tag == 3){
                [subView setBackgroundColor:whiteColor];
            }else if(subView.tag == 4){
                [subView setBackgroundColor:whiteColor];
            }
            else if(subView.tag == 5){
                [subView setBackgroundColor:whiteColor];
            }else if(subView.tag == 6){
                [subView setBackgroundColor:whiteColor];
            }else if(subView.tag == 7){
                [subView setBackgroundColor:whiteColor];
            }
        }
    }if(oneVolume * 4 <= value){
        NSLog(@"Four Volume");
        for(UIView *subView in [_volumeControlView subviews]){
            
            if(subView.tag == 0){
                [subView setBackgroundColor:blueColor];
            }else if (subView.tag == 1){
                [subView setBackgroundColor:blueColor];
            }else if(subView.tag == 2){
                [subView setBackgroundColor:blueColor];
            }else if(subView.tag == 3){
                [subView setBackgroundColor:blueColor];
            }else if(subView.tag == 4){
                [subView setBackgroundColor:whiteColor];
            }
            else if(subView.tag == 5){
                [subView setBackgroundColor:whiteColor];
            }else if(subView.tag == 6){
                [subView setBackgroundColor:whiteColor];
            }else if(subView.tag == 7){
                [subView setBackgroundColor:whiteColor];
            }
        }
    }if(oneVolume * 5 <= value){
        NSLog(@"Five Volume");
        for(UIView *subView in [_volumeControlView subviews]){
            
            if(subView.tag == 0){
                [subView setBackgroundColor:blueColor];
            }else if (subView.tag == 1){
                [subView setBackgroundColor:blueColor];
            }else if(subView.tag == 2){
                [subView setBackgroundColor:blueColor];
            }else if(subView.tag == 3){
                [subView setBackgroundColor:blueColor];
            }else if(subView.tag == 4){
                [subView setBackgroundColor:blueColor];
            }
            else if(subView.tag == 5){
                [subView setBackgroundColor:whiteColor];
            }else if(subView.tag == 6){
                [subView setBackgroundColor:whiteColor];
            }else if(subView.tag == 7){
                [subView setBackgroundColor:whiteColor];
            }
        }
    }if(oneVolume * 6 <= value){
        NSLog(@"Six Volume");
        for(UIView *subView in [_volumeControlView subviews]){
            
            if(subView.tag == 0){
                [subView setBackgroundColor:blueColor];
            }else if (subView.tag == 1){
                [subView setBackgroundColor:blueColor];
            }else if(subView.tag == 2){
                [subView setBackgroundColor:blueColor];
            }else if(subView.tag == 3){
                [subView setBackgroundColor:blueColor];
            }else if(subView.tag == 4){
                [subView setBackgroundColor:blueColor];
            }
            else if(subView.tag == 5){
                [subView setBackgroundColor:blueColor];
            }else if(subView.tag == 6){
                [subView setBackgroundColor:whiteColor];
            }else if(subView.tag == 7){
                [subView setBackgroundColor:whiteColor];
            }
        }
    }if(oneVolume * 7 <= value){
        NSLog(@"Seven Volume");
        for(UIView *subView in [_volumeControlView subviews]){
            
            if(subView.tag == 0){
                [subView setBackgroundColor:blueColor];
            }else if (subView.tag == 1){
                [subView setBackgroundColor:blueColor];
            }else if(subView.tag == 2){
                [subView setBackgroundColor:blueColor];
            }else if(subView.tag == 3){
                [subView setBackgroundColor:blueColor];
            }else if(subView.tag == 4){
                [subView setBackgroundColor:blueColor];
            }
            else if(subView.tag == 5){
                [subView setBackgroundColor:blueColor];
            }else if(subView.tag == 6){
                [subView setBackgroundColor:blueColor];
            }else if(subView.tag == 7){
                [subView setBackgroundColor:whiteColor];
            }
        }
    }if(oneVolume * 8 <= value){
        NSLog(@"Eight Volume");
        for(UIView *subView in [_volumeControlView subviews]){
            [subView setBackgroundColor:blueColor];
        }
    }
}


- (IBAction)playPrevButtonClicked:(id)sender{
    
    NSLog(@"Player Prev Button Clicked");
    [self playerFinishedPlaying];
}


-(void)layoutSubviews
{
    [super layoutSubviews];
    [playerLayer setFrame:self.frame];
}

-(void)playerFinishedPlaying
{
    [self.moviePlayer pause];
    [self.moviePlayer seekToTime:kCMTimeZero];
    [self.playPauseButton setSelected:NO];
    self.isPlaying = NO;
    if ([self.delegate respondsToSelector:@selector(playerFinishedPlayback:)]) {
        [self.delegate playerFinishedPlayback:self];
    }
}


-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint point = [(UITouch*)[touches anyObject] locationInView:self];
    if (CGRectContainsPoint(playerLayer.frame, point)) {
        
        [self showPlayerToolBottomView:!viewIsShowing];
        
    }
}
-(void)handlePan:(UIPanGestureRecognizer *)panGesture{
    
    CGPoint translation = [panGesture translationInView:self.superview];
    if (UIGestureRecognizerStateBegan == panGesture.state ||UIGestureRecognizerStateChanged == panGesture.state) {
        
        self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
        [panGesture setTranslation:CGPointZero inView:self];
        
    }else if(panGesture.state == UIGestureRecognizerStateEnded){
        
        self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
        [panGesture setTranslation:CGPointZero inView:self];
        
    }
    
}
-(void)handlePinch:(UIPinchGestureRecognizer *)pinchGesture{
    
    if (UIGestureRecognizerStateBegan == pinchGesture.state ||
        UIGestureRecognizerStateChanged == pinchGesture.state) {
        
        float currentScale = [[self.layer valueForKeyPath:@"transform.scale.x"] floatValue];
        
        float minScale = 0.7;
        float maxScale = 1.8;
        float zoomSpeed = .5;
        
        float deltaScale = pinchGesture.scale;
        
        deltaScale = ((deltaScale - 1) * zoomSpeed) + 1;
        
        deltaScale = MIN(deltaScale, maxScale / currentScale);
        deltaScale = MAX(deltaScale, minScale / currentScale);
        
        CGAffineTransform zoomTransform = CGAffineTransformScale(self.transform, deltaScale, deltaScale);
        self.transform = zoomTransform;
        
        pinchGesture.scale = 1;
        
    }
    
    else if(UIGestureRecognizerStateEnded == pinchGesture.state){
        
        float currentScale = [[self.layer valueForKeyPath:@"transform.scale.x"] floatValue];
        
        float minScale = 0.5;
        float maxScale = 2.0;
        float zoomSpeed = .5;
        
        float deltaScale = pinchGesture.scale;
        
        deltaScale = ((deltaScale - 1) * zoomSpeed) + 1;
        
        deltaScale = MIN(deltaScale, maxScale / currentScale);
        deltaScale = MAX(deltaScale, minScale / currentScale);
        
        CGAffineTransform zoomTransform = CGAffineTransformScale(self.transform, deltaScale, deltaScale);
        self.transform = zoomTransform;
        
        pinchGesture.scale = 1;
        
    }
}


-(void)showPlayerToolBottomView:(BOOL)show{
    
    __weak __typeof(self) weakself = self;
    if(show) {
        CGRect frame = self.playerToolBottomView.frame;
        frame.origin.y = self.bounds.size.height;
        
        [UIView animateWithDuration:0.3 animations:^{
            weakself.playerToolBottomView.frame = frame;
            weakself.playPauseButton.layer.opacity = 0;
            viewIsShowing = show;
        }];
    } else {
        CGRect frame = self.playerToolBottomView.frame;
        frame.origin.y = self.bounds.size.height-self.playerToolBottomView.frame.size.height;
        
        [UIView animateWithDuration:0.3 animations:^{
            weakself.playerToolBottomView.frame = frame;
            weakself.playPauseButton.layer.opacity = 1;
            viewIsShowing = show;
        }];
    }
    
}


-(NSString*)getStringFromCMTime:(CMTime)time
{
    Float64 currentSeconds = CMTimeGetSeconds(time);
    int mins = currentSeconds/60.0;
    int secs = fmodf(currentSeconds, 60.0);
    NSString *minsString = mins < 10 ? [NSString stringWithFormat:@"0%d", mins] : [NSString stringWithFormat:@"%d", mins];
    NSString *secsString = secs < 10 ? [NSString stringWithFormat:@"0%d", secs] : [NSString stringWithFormat:@"%d", secs];
    return [NSString stringWithFormat:@"%@:%@", minsString, secsString];
}

- (IBAction)playPauseButtonClicked:(id)sender{
    NSLog(@"Player Pause Button Clicked");
    
    if(!_playPauseButton.isSelected){
        NSLog(@"Player is play");
        [_playPauseButton setSelected:YES];
        [self play];
    }else{
        NSLog(@"Player is pause");
        [_playPauseButton setSelected:NO];
        if(self.isPlaying){
            [self pause];
        }
    }
}

-(IBAction)playerSliderValueChanged:(UISlider*)sliderSender{
    
    self.progressBar.value = sliderSender.value;
    if (self.isPlaying) {
        self.isPlaying = NO;
        [self.playPauseButton setSelected:NO];
        [self.moviePlayer pause];
    }
    
    CMTime seekTime = CMTimeMakeWithSeconds(sliderSender.value * (double)self.moviePlayer.currentItem.asset.duration.value / (double)self.moviePlayer.currentItem.asset.duration.timescale, self.moviePlayer.currentTime.timescale);
    [self.moviePlayer seekToTime:seekTime];
    
    self.playBackTimeLabel.text = [self getStringFromCMTime:seekTime];
}
-(void)playerSliderValueEnded:(UISlider*)sliderSender{
    
    if(sliderSender.value == 1.0f){
        
        CMTime seekTime = CMTimeMakeWithSeconds(sliderSender.value * (double)self.moviePlayer.currentItem.asset.duration.value / (double)self.moviePlayer.currentItem.asset.duration.timescale, self.moviePlayer.currentTime.timescale);
        
        CMTime lastTime = CMTimeRangeMake(kCMTimeZero, seekTime).duration;
        [self.moviePlayer seekToTime:lastTime];
    }
}

-(IBAction)volumeSliderValueChanged:(UISlider*)sliderSender{
    
    float value = sliderSender.value;
    [self.moviePlayer setVolume:value];
    
    [self updateUIForVolumeControl:value];
    
}
-(void)volumeSliderValueEnded:(UISlider*)sliderSender{
    NSLog(@"Volumde Slider Value Ended : %f",sliderSender.value);
}



@end
