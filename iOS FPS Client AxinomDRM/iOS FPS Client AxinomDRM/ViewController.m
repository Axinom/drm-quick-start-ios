//
//  ViewController.m
//  iOS FPS Client AxinomDRM
//
//  Created by Dace Kotlere on 6/13/17.
//  Copyright © 2017 Dace Kotlere. All rights reserved.
//

#import "ViewController.h"
#import "AssetLoaderDelegate.h"
@import AVFoundation;
@import AVKit;

@interface ViewController ()

@property (strong) AVPlayerViewController *avPlayerViewController;
@property (strong) AssetLoaderDelegate  *loaderDelegate;
@property (weak, nonatomic) IBOutlet UIButton *playButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.playButton setTitle:[[NSUserDefaults standardUserDefaults] objectForKey:@"media_url"] forState:UIControlStateNormal];
    self.avPlayerViewController = [[AVPlayerViewController alloc] init];
    self.loaderDelegate = [[AssetLoaderDelegate alloc] init];
}

- (IBAction)onPlay:(id)sender {
    
    NSString *mediaUrl = [[NSUserDefaults standardUserDefaults] objectForKey:@"media_url"];
    AVURLAsset *avUrlAsset = (AVURLAsset*)[AVAsset assetWithURL:[NSURL URLWithString: mediaUrl]];
    [[avUrlAsset resourceLoader] setDelegate:self.loaderDelegate queue:dispatch_get_main_queue()];
    AVPlayerItem *avPlayerItem = [AVPlayerItem playerItemWithAsset:avUrlAsset];
    AVPlayer *avPlayer = [[AVPlayer alloc] initWithPlayerItem:avPlayerItem];
    self.avPlayerViewController.player = avPlayer;
    
    __weak ViewController *vc = self;
    [self presentViewController:self.avPlayerViewController animated:YES completion:^(){
        [vc.avPlayerViewController.player play];
    }];
}

@end
