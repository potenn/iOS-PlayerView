//
//  KRVideoPlayerView.h
//  KnowRecorder
//
//  Created by wenote on 2016. 11. 29..
//  Copyright © 2016년 weMAC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

@class KRVideoPlayerView;

@protocol playerViewDelegate <NSObject>
@optional
-(void)playerViewZoomButtonClicked:(KRVideoPlayerView*)view;
-(void)playerFinishedPlayback:(KRVideoPlayerView*)view;
@end


@interface KRVideoPlayerView : UIView

@property (assign, nonatomic) id <playerViewDelegate> delegate;
@property (retain, nonatomic) NSURL *contentURL;
@property (retain, nonatomic) AVPlayer *moviePlayer;
@property (assign, nonatomic) BOOL isPlaying;

@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UIButton *playPrevButton;

- (IBAction)playPrevButtonClicked:(id)sender;
- (IBAction)playPauseButtonClicked:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *playBackTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *playBackTotalTimeLabel;

@property (weak, nonatomic) IBOutlet UISlider *progressBar;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;

@property (weak, nonatomic) IBOutlet UIView *volumeControlView;

-(IBAction)playerSliderValueChanged:(UISlider*)sliderSender;
-(void)playerSliderValueEnded:(UISlider*)sliderSender;
-(IBAction)volumeSliderValueChanged:(UISlider*)sliderSender;
-(void)volumeSliderValueEnded:(UISlider*)sliderSender;

@property (weak, nonatomic) IBOutlet UIView *playerToolBottomView;

-(id)initWithFrame:(CGRect)frame contentURL:(NSURL*)contentURL;
-(id)initWithFrame:(CGRect)frame playerItem:(AVPlayerItem*)playerItem;
-(void)play;
-(void)pause;
-(void) setupConstraints;
-(void)setPlayerSettingContentURL:(NSURL*)contentURL;

@end
