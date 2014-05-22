/*
 Copyright (c) 2010, Stig Brautaset.
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are
 met:

 Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.

 Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.

 Neither the name of the the author nor the names of its contributors
 may be used to endorse or promote products derived from this software
 without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "MGWUJsonStreamParser.h"
#import "MGWUJsonTokeniser.h"
#import "MGWUJsonStreamParserState.h"
#import <limits.h>

@implementation MGWUJsonStreamParser

@synthesize supportMultipleDocuments;
@synthesize error;
@synthesize delegate;
@synthesize maxDepth;
@synthesize state;
@synthesize stateStack;

#pragma mark Housekeeping

- (id)init {
	self = [super init];
	if (self) {
		maxDepth = 32u;
        stateStack = [[NSMutableArray alloc] initWithCapacity:maxDepth];
        state = [MGWUJsonStreamParserStateStart sharedInstance];
		tokeniser = [[MGWUJsonTokeniser alloc] init];
	}
	return self;
}


#pragma mark Methods

- (NSString*)tokenName:(mgwujson_token_t)token {
	switch (token) {
		case mgwujson_token_array_start:
			return @"start of array";
			break;

		case mgwujson_token_array_end:
			return @"end of array";
			break;

		case mgwujson_token_number:
			return @"number";
			break;

		case mgwujson_token_string:
			return @"string";
			break;

		case mgwujson_token_true:
		case mgwujson_token_false:
			return @"boolean";
			break;

		case mgwujson_token_null:
			return @"null";
			break;

		case mgwujson_token_keyval_separator:
			return @"key-value separator";
			break;

		case mgwujson_token_separator:
			return @"value separator";
			break;

		case mgwujson_token_object_start:
			return @"start of object";
			break;

		case mgwujson_token_object_end:
			return @"end of object";
			break;

		case mgwujson_token_eof:
		case mgwujson_token_error:
			break;
	}
	NSAssert(NO, @"Should not get here");
	return @"<aaiiie!>";
}

- (void)maxDepthError {
    self.error = [NSString stringWithFormat:@"Input depth exceeds max depth of %u", maxDepth];
    self.state = [MGWUJsonStreamParserStateError sharedInstance];
}

- (void)handleObjectStart {
	if (stateStack.count >= maxDepth) {
        [self maxDepthError];
        return;
	}

    [delegate parserFoundObjectStart:self];
    [stateStack addObject:state];
    self.state = [MGWUJsonStreamParserStateObjectStart sharedInstance];
}

- (void)handleObjectEnd: (mgwujson_token_t) tok  {
    self.state = [stateStack lastObject];
    [stateStack removeLastObject];
    [state parser:self shouldTransitionTo:tok];
    [delegate parserFoundObjectEnd:self];
}

- (void)handleArrayStart {
	if (stateStack.count >= maxDepth) {
        [self maxDepthError];
        return;
    }
	
	[delegate parserFoundArrayStart:self];
    [stateStack addObject:state];
    self.state = [MGWUJsonStreamParserStateArrayStart sharedInstance];
}

- (void)handleArrayEnd: (mgwujson_token_t) tok  {
    self.state = [stateStack lastObject];
    [stateStack removeLastObject];
    [state parser:self shouldTransitionTo:tok];
    [delegate parserFoundArrayEnd:self];
}

- (void) handleTokenNotExpectedHere: (mgwujson_token_t) tok  {
    NSString *tokenName = [self tokenName:tok];
    NSString *stateName = [state name];

    self.error = [NSString stringWithFormat:@"Token '%@' not expected %@", tokenName, stateName];
    self.state = [MGWUJsonStreamParserStateError sharedInstance];
}

- (MGWUJsonStreamParserStatus)parse:(NSData *)data_ {
    @autoreleasepool {
        [tokeniser appendData:data_];
        
        for (;;) {
            
            if ([state isError])
                return MGWUJsonStreamParserError;
            
            NSObject *token;
            mgwujson_token_t tok = [tokeniser getToken:&token];
            switch (tok) {
                case mgwujson_token_eof:
                    return [state parserShouldReturn:self];
                    break;
                    
                case mgwujson_token_error:
                    self.state = [MGWUJsonStreamParserStateError sharedInstance];
                    self.error = tokeniser.error;
                    return MGWUJsonStreamParserError;
                    break;
                    
                default:
                    
                    if (![state parser:self shouldAcceptToken:tok]) {
                        [self handleTokenNotExpectedHere: tok];
                        return MGWUJsonStreamParserError;
                    }
                    
                    switch (tok) {
                        case mgwujson_token_object_start:
                            [self handleObjectStart];
                            break;
                            
                        case mgwujson_token_object_end:
                            [self handleObjectEnd: tok];
                            break;
                            
                        case mgwujson_token_array_start:
                            [self handleArrayStart];
                            break;
                            
                        case mgwujson_token_array_end:
                            [self handleArrayEnd: tok];
                            break;
                            
                        case mgwujson_token_separator:
                        case mgwujson_token_keyval_separator:
                            [state parser:self shouldTransitionTo:tok];
                            break;
                            
                        case mgwujson_token_true:
                            [delegate parser:self foundBoolean:YES];
                            [state parser:self shouldTransitionTo:tok];
                            break;
                            
                        case mgwujson_token_false:
                            [delegate parser:self foundBoolean:NO];
                            [state parser:self shouldTransitionTo:tok];
                            break;
                            
                        case mgwujson_token_null:
                            [delegate parserFoundNull:self];
                            [state parser:self shouldTransitionTo:tok];
                            break;
                            
                        case mgwujson_token_number:
                            [delegate parser:self foundNumber:(NSNumber*)token];
                            [state parser:self shouldTransitionTo:tok];
                            break;
                            
                        case mgwujson_token_string:
                            if ([state needKey])
                                [delegate parser:self foundObjectKey:(NSString*)token];
                            else
                                [delegate parser:self foundString:(NSString*)token];
                            [state parser:self shouldTransitionTo:tok];
                            break;
                            
                        default:
                            break;
                    }
                    break;
            }
        }
        return MGWUJsonStreamParserComplete;
    }
}

@end
