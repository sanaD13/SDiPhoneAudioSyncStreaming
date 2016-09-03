//
//  SDHostViewController.m
//  SDiPhoneAudioSyncStreaming
//
//  Created by Sana on 9/3/16.
//  Copyright © 2016 Sana Desai. All rights reserved.
//
@import MediaPlayer;
@import MultipeerConnectivity;
@import AVFoundation;

#import "SDHostViewController.h"
#import "TDAudioStreamer.h"
#import "TDSession.h"
#import "JTMaterialSpinner.h"

@interface SDHostViewController () < MPMediaPickerControllerDelegate >
{
    BOOL alreadyPlaying;
}
@property (weak, nonatomic) IBOutlet UILabel *LBLSongName;

@property (strong, nonatomic) MPMediaItem *song;
@property (strong, nonatomic) TDAudioOutputStreamer *outputStreamer;
@property (strong, nonatomic) TDAudioInputStreamer *inputStreamer;
@property (strong, nonatomic) TDSession *session;
@property (strong, nonatomic) AVPlayer *player;

@property (retain, nonatomic) JTMaterialSpinner *spinnerView;

@end

@implementation SDHostViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //session
    self.session = [[TDSession alloc] initWithPeerDisplayName:[[UIDevice currentDevice] name]];
    
    //loader
    _spinnerView = [[JTMaterialSpinner alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    [_spinnerView setCenter:self.view.center];
    _spinnerView.circleLayer.lineWidth = 2.0;
    _spinnerView.circleLayer.strokeColor = [UIColor blueColor].CGColor;
}

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(startPlayingSongH) name:@"playSong" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(ResumeSongH) name:@"resumeSong" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(PauseSongH) name:@"pauseSong" object:nil];
}

-(void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */
- (IBAction)inviteFriends:(id)sender {
    [self presentViewController:[self.session browserViewControllerForSeriviceType:@"dance-party"] animated:YES completion:nil];
    
    NSLog(@"PICKED");
}

- (IBAction)selectSong:(id)sender {
    if (self.session.connectedPeers.count > 0) {
        
        MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic];
        picker.delegate = self;
        [self presentViewController:picker animated:YES completion:nil];
    }
    else {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"No peers connected!"
                                              message:@"Please connect to other iPhone device/s. Select \"Invite\""
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:@"OK"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       NSLog(@"OK action");
                                   }];
        
        [alertController addAction:okAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (IBAction)play:(id)sender {
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    
    NSDate *now = [self getPlayTime:5];
    
    if (alreadyPlaying) {
        
        info[@"status"] = @"resume";
        info[@"type"] = @"timer";
        info[@"time"] = now;
        
        [self.session sendTimer:[NSKeyedArchiver archivedDataWithRootObject:info]];
        [self scheduleResumeNotification:now];
    }
    else {
        //self play
        _player = nil;
        _player = [[AVPlayer alloc] initWithURL:[self.song valueForProperty:MPMediaItemPropertyAssetURL]];
        
        info[@"type"] = @"timer";
        info[@"status"] = @"play";
        info[@"time"] = now;
        
        alreadyPlaying = YES;
        [self.session sendTimer:[NSKeyedArchiver archivedDataWithRootObject:info]];
        [self scheduleNotification:now];
    }
}

- (IBAction)pause:(id)sender {
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    NSDate *now = [self getPlayTime:2];
    
    info[@"type"] = @"timer";
    info[@"status"] = @"pause";
    info[@"time"] = now;
    [self.session sendTimer:[NSKeyedArchiver archivedDataWithRootObject:info]];
    
    [self schedulePauseNotification:now];
    
}

#pragma mark - Media Picker delegate

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if (self.outputStreamer) return;
    
    self.song = mediaItemCollection.items[0];
    
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    info[@"title"] = [self.song valueForProperty:MPMediaItemPropertyTitle] ? [self.song valueForProperty:MPMediaItemPropertyTitle] : @"";
    
    self.LBLSongName.text = info[@"title"];
    
    alreadyPlaying = NO;
    
    [self.session sendData:[NSKeyedArchiver archivedDataWithRootObject:[info copy]]];
    
    NSArray *peers = [self.session connectedPeers];
    
    ///
    int recieverCount = 0;
    
    while (recieverCount < peers.count) {
        
        self.outputStreamer = [[TDAudioOutputStreamer alloc] initWithOutputStream:[self.session outputStreamForPeer:peers[recieverCount]]];
        [self.outputStreamer streamAudioFromURL:[self.song valueForProperty:MPMediaItemPropertyAssetURL]];
        
        [self.outputStreamer start];
        
        recieverCount++;
    }
    if (recieverCount == peers.count) {
        NSLog(@"ALL SEND");
    }
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - notification methods
-(void)startPlayingSongH {
    [_player play];
    [self spinnerStop];
}

-(void)PauseSongH {
    [_player pause];
    [self spinnerStop];
}

-(void)ResumeSongH {
    [_player play];
    [self spinnerStop];
}

#pragma mark - set notifications
- (void)scheduleNotification:(NSDate *)now
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    UILocalNotification *notif = [[UILocalNotification alloc] init];
    
    notif.fireDate = now;
    notif.userInfo = [NSDictionary dictionaryWithObject:@"play" forKey:@"type"];
    
    [[UIApplication sharedApplication] scheduleLocalNotification:notif];
    
    
    //start loader
    // Update the UI
    // Start & stop animations
    [self spinnerStart];
}

- (void)scheduleResumeNotification:(NSDate *)now
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    UILocalNotification *notif = [[UILocalNotification alloc] init];
    
    notif.fireDate = now;
    notif.userInfo = [NSDictionary dictionaryWithObject:@"resume" forKey:@"type"];
    
    [[UIApplication sharedApplication] scheduleLocalNotification:notif];
    
    //start loader
    // Update the UI
    // Start & stop animations
    [self spinnerStart];
}

-(void)schedulePauseNotification:(NSDate *)now {
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    UILocalNotification *notif = [[UILocalNotification alloc] init];
    
    notif.fireDate = now;
    notif.userInfo = [NSDictionary dictionaryWithObject:@"pause" forKey:@"type"];
    
    [[UIApplication sharedApplication] scheduleLocalNotification:notif];
    
    
    //start loader
    
    // Update the UI
    // Start & stop animations
    [self spinnerStart];
    
}

#pragma mark - get manipulated time

-(NSDate *)getPlayTime:(int)delayTime {
    NSLog(@"%@",[NSDate date]);
    NSDate *selectedDateTime = (NSDate *)[[NSDate date] dateByAddingTimeInterval:delayTime];
    NSString *dateString = @"";
    NSDateFormatter* dateFormatter1 = [[NSDateFormatter alloc] init];
    dateFormatter1.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
    dateString = [dateFormatter1 stringFromDate:selectedDateTime];
    NSDate *yourDate = [dateFormatter1 dateFromString:dateString];
    dateFormatter1.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    dateString = [dateFormatter1 stringFromDate:yourDate];
    yourDate = [dateFormatter1 dateFromString:dateString];
    NSLog(@"%@",yourDate);
    
    return yourDate;
}

#pragma mark - spinner methods

-(void)spinnerStart {
    [self.view setUserInteractionEnabled:NO];
    
    [self.view addSubview:_spinnerView];
    [_spinnerView beginRefreshing];
}

-(void)spinnerStop {
    [self.view setUserInteractionEnabled:YES];
    
    [_spinnerView endRefreshing];
    [_spinnerView removeFromSuperview];
}

@end
