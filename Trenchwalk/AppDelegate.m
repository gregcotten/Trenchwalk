//
//  AppDelegate.m
//  Trenchwalk
//
//  Created by Greg Cotten on 7/12/15.
//  Copyright © 2015 Greg Cotten. All rights reserved.
//

#import "AppDelegate.h"
#import "ServoController.h"
#import "ServoPlaybackController.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet ServoController *servoController;
@property (weak) IBOutlet ServoPlaybackController *playbackController;


@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [self registerSleepNotifications];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    [self.playbackController stopPlayback];
    [self.servoController closeConnection];
}

- (void) receiveSleepNote: (NSNotification*) note{
    [self.playbackController stopPlayback];
    [self.servoController closeConnection];
}

- (void) receiveWakeNote: (NSNotification*) note{
    
}

- (void) registerSleepNotifications{
    //These notifications are filed on NSWorkspace's notification center, not the default
    // notification center. You will not receive sleep/wake notifications if you file
    //with the default notification center.
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(receiveSleepNote:)
                                                               name: NSWorkspaceWillSleepNotification object: NULL];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(receiveWakeNote:)
                                                               name: NSWorkspaceDidWakeNotification object: NULL];
}

@end
