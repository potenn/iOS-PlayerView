//
//  ViewController.m
//  KRVideoPlayerView
//
//  Created by KimMinki on 2016. 12. 2..
//  Copyright © 2016년 potenn. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)videoCreateButtonClicked:(id)sender {
    
    NSString *videoURLString = @"http://www.ithinknext.com/mydata/board/files/F201308021823010.mp4";
    NSString *urlString = [videoURLString stringByAddingPercentEscapesUsingEncoding : NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:urlString];
    
    KRVideoPlayerView *krVideoView = [[[NSBundle mainBundle] loadNibNamed:@"KRVideoPlayerView" owner:nil options:nil] objectAtIndex:0];
    [krVideoView setPlayerSettingContentURL:url];
    
    [krVideoView setFrame:CGRectMake(0, 0, krVideoView.frame.size.width,krVideoView.frame.size.height)];
    
    [self.view addSubview:krVideoView];
    
}
@end
