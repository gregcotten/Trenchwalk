//
//  AppDelegate.m
//  Trenchwalk
//
//  Created by Greg Cotten on 7/12/15.
//  Copyright © 2015 Greg Cotten. All rights reserved.
//

#import "AppDelegate.h"
#import "ServoController.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet ServoController *servoController;


@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    [self.servoController closeConnection];
}

@end
