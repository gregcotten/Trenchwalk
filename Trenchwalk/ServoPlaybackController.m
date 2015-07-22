//
//  ServoPlaybackController.m
//  Trenchwalk
//
//  Created by Greg Cotten on 7/21/15.
//  Copyright © 2015 Greg Cotten. All rights reserved.
//

#import "ServoPlaybackController.h"
#import <Cocoa/Cocoa.h>
#import "VVApp.h"

dispatch_source_t CreatePlaybackTimer(double interval, dispatch_queue_t queue, dispatch_block_t block)
{
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    if (timer)
    {
        dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), interval * NSEC_PER_SEC, (1ull * NSEC_PER_SEC) / 10);
        dispatch_source_set_event_handler(timer, block);
        dispatch_resume(timer);
    }
    return timer;
}

double lerp(double beginning, double end, double value01) {
    float range = end - beginning;
    return beginning + range * value01;
}

double clamp(double value, double min, double max){
    return (value > max) ? max : ((value < min) ? min : value);
}

@interface ServoPlaybackController ()

@property (strong) dispatch_queue_t timerSerialQueue;
@property (strong) dispatch_source_t updateTimer;

@property (assign) double playbackStartTime;
@property (weak) IBOutlet NSWindow *ownerWindow;

@end

@implementation ServoPlaybackController

-(IBAction)setStart:(id)sender{
    self.startPosition = self.servoController.servoCurrentPosition;
}

-(IBAction)setEnd:(id)sender{
    self.endPosition = self.servoController.servoCurrentPosition;
}

-(IBAction)startPlaybackButton:(id)sender{
    [VVApp endEditingInWindow:self.ownerWindow];
    [self stopPlayback];
    [self prepAndStartPlayback];
}

-(IBAction)stopPlaybackButton:(id)sender{
    [self stopPlayback];
}

-(void)prepAndStartPlayback{
    if (self.updateTimer) {
        return;
    }
    if (!self.timerSerialQueue) {
        self.timerSerialQueue = dispatch_queue_create("Playback Timer Serial Dispatch", DISPATCH_QUEUE_SERIAL);
    }

    self.playbackDurationInSeconds = clamp(self.playbackDurationInSeconds, 2, 10000);


        self.servoController.isInPlayback = YES;

        self.servoController.servoSpeed = ServoSpeedHone;
        self.servoController.servoTargetPosition = self.startPosition;
        self.servoController.servoState = @"Honing";
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        while (labs(self.servoController.servoCurrentPosition - self.startPosition) > 50 && self.servoController.isInPlayback) {
                //wait and hone that temp
        }

        dispatch_sync(dispatch_get_main_queue(), ^{

            if (!self.servoController.isInPlayback) {
                return;
            }

            self.servoController.servoState = @"Waiting a sec before playback";
            [NSTimer scheduledTimerWithTimeInterval:2
                                             target:self
                                           selector:@selector(startPlayback:)
                                           userInfo:nil
                                            repeats:NO];

        });
    });
}

-(void)startPlayback:(NSTimer *)timer{
    if (!self.servoController.isInPlayback) {
        [self stopPlayback];
        return;
    }
    self.playbackStartTime = CFAbsoluteTimeGetCurrent();
    self.servoController.servoState = @"Playing back";
    self.servoController.servoSpeed = ServoSpeedPlayback;

    self.updateTimer = CreatePlaybackTimer(.05f, self.timerSerialQueue, ^{
        [self timedUpdate];
    });
}

-(void)stopPlayback{
    if (self.updateTimer) {
        dispatch_source_cancel(self.updateTimer);
    }

    [VVApp endEditingInWindow:self.ownerWindow];
    self.servoController.servoSpeed = ServoSpeedCasual;
    self.servoController.servoTargetPosition = self.servoController.servoCurrentPosition;
    self.servoController.isInPlayback = NO;
    self.servoController.servoState = @"Idle";
    self.updateTimer = nil;
}

-(void)timedUpdate{
    double currentPlayheadTimeNormalized = (CFAbsoluteTimeGetCurrent() - self.playbackStartTime)/self.playbackDurationInSeconds;

    if (currentPlayheadTimeNormalized > 1.0 || !self.servoController.isInPlayback) {
        [self stopPlayback];
        return;
    }

    currentPlayheadTimeNormalized = clamp(currentPlayheadTimeNormalized, 0, 1);

    self.servoController.servoTargetPosition = lerp(self.startPosition, self.endPosition, currentPlayheadTimeNormalized);

}

@end
