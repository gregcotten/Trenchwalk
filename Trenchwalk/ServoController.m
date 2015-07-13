//
//  ServoController.m
//  Trenchwalk
//
//  Created by Greg Cotten on 7/12/15.
//  Copyright © 2015 Greg Cotten. All rights reserved.
//

#import "ServoController.h"
#import <ORSSerialPort/ORSSerialPortManager.h>
#import <ORSSerialPort/ORSSerialRequest.h>

#import "MocoJoServoProtocol.h"
#import "MocoProtocolConstants.h"

@interface ServoController ()

@property (strong) NSTimer *updateTimer;

@end

@implementation ServoController

-(instancetype)init{
    if (self = [super init]){
        self.servoState = @"Not Connected";
        self.isInPlayback = NO;
        self.didInitialize = NO;
    }
    return self;
}

-(IBAction)connect:(id)sender{
    [self openConnection];
}

-(void)openConnection{
    self.serialPort = (ORSSerialPort *)[[ORSSerialPortManager sharedSerialPortManager] availablePorts].firstObject;
    self.serialPort.delegate = self;
    [self.serialPort setBaudRate:@(MocoJoServoBaudRate)];//this actually doesn't matter - teensy always communicates at USB 2.0 speeds

    self.servoState = [NSString stringWithFormat:@"Connecting to %@...", self.serialPort.path];
    self.servoID = MocoAxisJibLift;
    [self.serialPort open];
}

-(void)handshakeServo{
    self.servoState = @"Handshaking...";

    NSData *command = [self.class servoDataPacketFromArray:@[@(self.servoID), @(MocoJoServoInitializeRequest)]];
    ORSSerialRequest *request =
    [ORSSerialRequest requestWithDataToSend:command
                                   userInfo:@(MocoJoServoHandshakeRequest)
                            timeoutInterval:2
                          responseEvaluator:^BOOL(NSData *data) {
                              if (data.length != 6) {
                                  return NO;
                              }
                              return ((char *)data.bytes)[1] == MocoJoServoHandshakeSuccessfulResponse;
                          }];
    [self.serialPort sendRequest:request];
}

-(void)initializeServo{
    self.servoState = @"Initializing...";

    NSData *command = [self.class servoDataPacketFromArray:@[@(self.servoID), @(MocoJoServoInitializeRequest)]];

    ORSSerialRequest *request =
    [ORSSerialRequest requestWithDataToSend:command
                                   userInfo:@(MocoJoServoInitializeRequest)
                            timeoutInterval:2
                          responseEvaluator:nil];
    [self.serialPort sendRequest:request];

    usleep(1000*500);
    self.didInitialize = YES;
    [self beginTimedUpdate];
    self.servoState = @"Idle";

}

-(BOOL)beginTimedUpdate{
    if (self.updateTimer) {
        return NO;
    }
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:.02f
                                                        target:self
                                                      selector:@selector(timedUpdate:)
                                                      userInfo:nil
                                                       repeats:YES];
    return YES;
}

-(void)endTimedUpdate{
    if (self.updateTimer) {
        [self.updateTimer invalidate];
    }
    self.updateTimer = nil;
}

-(void)timedUpdate:(NSTimer*)timer{
    if (self.serialPort.isOpen && self.didInitialize) {
        [self updateCurrentPosition];
    }
}

-(void)updateCurrentPosition{
    NSData *command = [self.class servoDataPacketFromArray:@[@(self.servoID), @(MocoJoServoGetCurrentPosition)]];
    ORSSerialRequest *request =
    [ORSSerialRequest requestWithDataToSend:command
                                   userInfo:@(MocoJoServoHandshakeRequest)
                            timeoutInterval:2
                          responseEvaluator:^BOOL(NSData *data) {
                              if (data.length != 6) {
                                  return NO;
                              }
                              return ((char *)data.bytes)[1] == MocoJoServoCurrentPosition;
                          }];
    [self.serialPort sendRequest:request];
}

-(void)setServoTargetPosition:(NSInteger)servoTargetPosition{
    _servoTargetPosition = servoTargetPosition;

//    NSData *command = [self.class servoDataPacketFromArray:@[@(self.servoID), @(MocoJoServoSetTargetPosition)]];
//    ORSSerialRequest *request =
//    [ORSSerialRequest requestWithDataToSend:command
//                                   userInfo:@(MocoJoServoSetTargetPosition)
//                            timeoutInterval:2
//                          responseEvaluator:nil];
//    [self.serialPort sendRequest:request];
}

-(void)serialPortWasOpened:(nonnull ORSSerialPort *)serialPort{
    sleep(5);
    [self handshakeServo];
}

- (void)disconnect{
    self.servoState = @"Not Connected";
    [self.serialPort close];
    [self endTimedUpdate];

    self.didInitialize = NO;
    self.isInPlayback = NO;
}

-(void)serialPortWasRemovedFromSystem:(nonnull ORSSerialPort *)serialPort{
    [self disconnect];
}

-(void)serialPort:(nonnull ORSSerialPort *)serialPort requestDidTimeout:(nonnull ORSSerialRequest *)request{
    NSLog(@"request timed out: %@", request);
    [self disconnect];
}

-(void)serialPort:(nonnull ORSSerialPort *)serialPort didEncounterError:(nonnull NSError *)error{
    NSLog(@"serial port error: %@", error);
}

-(void)serialPort:(nonnull ORSSerialPort *)serialPort didReceiveResponse:(nonnull NSData *)responseData toRequest:(nonnull ORSSerialRequest *)request{
    NSInteger requestID = [request.userInfo integerValue];
    Byte *responseBytes = (Byte*)responseData.bytes;

    if (requestID == MocoJoServoHandshakeRequest) {
        self.servoState = @"Handshake Success";
        [self initializeServo];
    }
    else if (requestID == MocoJoServoGetCurrentPosition) {
        Byte fourbytes[4];
        fourbytes[0] = responseBytes[2];
        fourbytes[1] = responseBytes[3];
        fourbytes[2] = responseBytes[4];
        fourbytes[3] = responseBytes[5];

        self.servoCurrentPosition = [self.class longIntFromFourBytes:fourbytes];

    }
}

+(long int)longIntFromFourBytes:(Byte *)fourBytes {
    return     ( (fourBytes[0] << 24)
                + (fourBytes[1] << 16)
                + (fourBytes[2] << 8)
                + (fourBytes[3] ) );
}

+ (NSData *)longIntAsFourBytes: (long int)longInt {
    unsigned char byteArray[4];

    // convert from an unsigned long int to a 4-byte array
    byteArray[0] = (int)((longInt >> 24) & 0xFF) ;
    byteArray[1] = (int)((longInt >> 16) & 0xFF) ;
    byteArray[2] = (int)((longInt >> 8) & 0XFF);
    byteArray[3] = (int)((longInt & 0XFF));

    return [NSData dataWithBytes:byteArray length:4];
}

+(NSData *)servoDataPacketFromArray:(NSArray *)array{
    char data[6];
    data[0] = array.count >= 1 ? [array[0] integerValue] : 0;
    data[1] = array.count >= 2 ? [array[1] integerValue] : 0;
    data[2] = array.count >= 3 ? [array[2] integerValue] : 0;
    data[3] = array.count >= 4 ? [array[3] integerValue] : 0;
    data[4] = array.count >= 5 ? [array[4] integerValue] : 0;
    data[5] = array.count >= 6 ? [array[5] integerValue] : 0;

    return [NSData dataWithBytes:data length:6];
}

@end
