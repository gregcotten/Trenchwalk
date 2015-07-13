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

@end

@implementation ServoController

-(instancetype)init{
    if (self = [super init]){
        self.servoState = @"Not Connected";
        self.isInPlayback = NO;
        self.didHandshake = NO;
    }
    return self;
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

    self.servoState = @"Idle";

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

-(void)updateTargetPosition{

}




-(void)serialPortWasOpened:(nonnull ORSSerialPort *)serialPort{
    self.servoState = @"Connected";
    [self handshakeServo];
}

-(void)serialPortWasRemovedFromSystem:(nonnull ORSSerialPort *)serialPort{
    self.didHandshake = NO;
    self.isInPlayback = NO;
    self.servoState = @"Disconnnected";
}

-(void)serialPort:(nonnull ORSSerialPort *)serialPort requestDidTimeout:(nonnull ORSSerialRequest *)request{
    NSLog(@"request timed out: %@", request.userInfo);
}

-(void)serialPort:(nonnull ORSSerialPort *)serialPort didEncounterError:(nonnull NSError *)error{
    NSLog(@"serial port error: %@", error);
}

-(void)serialPort:(nonnull ORSSerialPort *)serialPort didReceiveResponse:(nonnull NSData *)responseData toRequest:(nonnull ORSSerialRequest *)request{
    NSInteger requestID = [request.userInfo integerValue];
    Byte *responseBytes = (Byte*)responseData.bytes;

    if (requestID == MocoJoServoHandshakeRequest) {
        self.servoState = @"Handshake Success";
        self.didHandshake = YES;
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
