//
//  TrenchwalkValueTransformers.m
//  Trenchwalk
//
//  Created by Greg Cotten on 7/21/15.
//  Copyright © 2015 Greg Cotten. All rights reserved.
//

#import "ServoController.h"
#import "TrenchwalkValueTransformers.h"

@implementation ServoWantsUserInput

+ (Class)transformedValueClass {
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)value {
    ServoController *servo = (ServoController *)value;
    return @([servo didInitialize] && ![servo isInPlayback]);
}


@end
