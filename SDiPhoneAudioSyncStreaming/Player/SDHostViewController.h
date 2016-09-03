//
//  SDHostViewController.h
//  SDiPhoneAudioSyncStreaming
//
//  Created by Sana on 9/3/16.
//  Copyright © 2016 Sana Desai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SDHostViewController : UIViewController

- (void)startPlayingSongH;
- (void)PauseSongH;
- (void)ResumeSongH;

- (void)scheduleNotification:(NSDate *)now;
- (void)schedulePauseNotification:(NSDate *)now;
- (void)scheduleResumeNotification:(NSDate *)now;

@end
