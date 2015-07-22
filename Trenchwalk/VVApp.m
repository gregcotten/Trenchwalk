//
//  VVApp.m
//  Trenchwalk
//
//  Created by Greg Cotten on 7/21/15.
//  Copyright © 2015 Greg Cotten. All rights reserved.
//

#import "VVApp.h"

@implementation VVApp

+ (BOOL)endEditingInWindow:(NSWindow *)window{
    bool success;
    id responder = [window firstResponder];

    // If we're dealing with the field editor, the real first responder is
    // its delegate.

    if ( (responder != nil) && [responder isKindOfClass:[NSTextView class]] && [(NSTextView*)responder isFieldEditor] )
        responder = ( [[responder delegate] isKindOfClass:[NSResponder class]] ) ? [responder delegate] : nil;

    success = [window makeFirstResponder:nil];

    // Return first responder status.

    if ( success && responder != nil )
        [window makeFirstResponder:responder];

    return success;
    
}

@end
