//
//  SDGuestViewController.m
//  SDiPhoneAudioSyncStreaming
//
//  Created by Sana on 9/3/16.
//  Copyright © 2016 Sana Desai. All rights reserved.
//

@import MediaPlayer;

#import "SDGuestViewController.h"
#import "TDSession.h"
#import "TDAudioStreamer.h"
#import "JTMaterialSpinner.h"

@interface SDGuestViewController () <TDSessionDelegate>
@property (weak, nonatomic) IBOutlet UILabel *LBLSongName;

@property (strong, nonatomic) TDSession *session;
@property (strong, nonatomic) TDAudioInputStreamer *inputStream;

@property (retain, nonatomic) JTMaterialSpinner *spinnerView;

@end

@implementation SDGuestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //session
    self.session = [[TDSession alloc] initWithPeerDisplayName:[[UIDevice currentDevice] name]];
    [self.session startAdvertisingForServiceType:@"dance-party" discoveryInfo:nil];
    self.session.delegate = self;
    
    //loader
    _spinnerView = [[JTMaterialSpinner alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    [_spinnerView setCenter:self.view.center];
    _spinnerView.circleLayer.lineWidth = 2.0;
    _spinnerView.circleLayer.strokeColor = [UIColor blueColor].CGColor;
}

- (void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(startPlayingSongG) name:@"playSong" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(ResumeSongG) name:@"resumeSong" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(PauseSongG) name:@"pauseSong" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.session stopAdvertising];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - set recieved data

- (void)changeSongInfo:(NSDictionary *)info
{
    self.LBLSongName.text = info[@"title"];
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

#pragma mark - TDSessionDelegate

- (void)session:(TDSession *)session didReceiveTimer:(NSData *)data {
    
    NSDictionary *info = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    NSDate *now = (NSDate *)info[@"time"];
    
    if ([info[@"status"]  isEqual: @"pause"])
        [self schedulePauseNotification:now];
    else if ([info[@"status"]  isEqual: @"resume"])
        [self scheduleResumeNotification:now];
    else
        [self scheduleNotification:now];
}

- (void)session:(TDSession *)session didReceiveData:(NSData *)data
{
    NSDictionary *info = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    [self performSelectorOnMainThread:@selector(changeSongInfo:) withObject:info waitUntilDone:NO];
}

- (void)session:(TDSession *)session didReceiveAudioStream:(NSInputStream *)stream
{
    //    if (!self.inputStream) {
    [self.inputStream stop];
    self.inputStream = [[TDAudioInputStreamer alloc] initWithInputStream:stream];
    //    }
}


#pragma mark - notification methods

- (void)startPlayingSongG {
    
    [self.inputStream start];
    [self spinnerStop];
}

- (void)PauseSongG {
    [self.inputStream pause];
    [self spinnerStop];
}

- (void)ResumeSongG {
    [self.inputStream resume];
    [self spinnerStop];
}

- (void)scheduleNotification:(NSDate *)now
{
    dispatch_queue_t myQueue = dispatch_queue_create("My Queue",NULL);
    dispatch_async(myQueue, ^{
        
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
        
        UILocalNotification *notif = [[UILocalNotification alloc] init];
        
        notif.fireDate = now;
        notif.userInfo = [NSDictionary dictionaryWithObject:@"play" forKey:@"type"];
        //    [notif setRepeatInterval:NULL];
        
        [[UIApplication sharedApplication] scheduleLocalNotification:notif];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // Update the UI
            // Start & stop animations
            [self spinnerStart];
        });
    });
}

- (void)scheduleResumeNotification:(NSDate *)now
{
    dispatch_queue_t myQueue = dispatch_queue_create("My Queue",NULL);
    dispatch_async(myQueue, ^{
        // Perform long running process
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
        
        UILocalNotification *notif = [[UILocalNotification alloc] init];
        
        notif.fireDate = now;
        notif.userInfo = [NSDictionary dictionaryWithObject:@"resume" forKey:@"type"];
        
        [[UIApplication sharedApplication] scheduleLocalNotification:notif];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // Update the UI
            // Start & stop animations
            [self spinnerStart];
        });
    });
}

- (void)schedulePauseNotification:(NSDate *)now {
    
    dispatch_queue_t myQueue = dispatch_queue_create("My Queue",NULL);
    dispatch_async(myQueue, ^{
        // Perform long running process
        
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
        
        UILocalNotification *notif = [[UILocalNotification alloc] init];
        
        notif.fireDate = now;
        notif.userInfo = [NSDictionary dictionaryWithObject:@"pause" forKey:@"type"];
        
        [[UIApplication sharedApplication] scheduleLocalNotification:notif];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // Update the UI
            // Start & stop animations
            [self spinnerStart];
        });
    });
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
