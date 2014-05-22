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

#import "MGWUJsonStreamParserState.h"
#import "MGWUJsonStreamParser.h"

#define SINGLETON \
+ (id)sharedInstance { \
    static id state = nil; \
    if (!state) state = [[self alloc] init]; \
    return state; \
}

@implementation MGWUJsonStreamParserState

+ (id)sharedInstance { return nil; }

- (BOOL)parser:(MGWUJsonStreamParser*)parser shouldAcceptToken:(mgwujson_token_t)token {
	return NO;
}

- (MGWUJsonStreamParserStatus)parserShouldReturn:(MGWUJsonStreamParser*)parser {
	return MGWUJsonStreamParserWaitingForData;
}

- (void)parser:(MGWUJsonStreamParser*)parser shouldTransitionTo:(mgwujson_token_t)tok {}

- (BOOL)needKey {
	return NO;
}

- (NSString*)name {
	return @"<aaiie!>";
}

- (BOOL)isError {
    return NO;
}

@end

#pragma mark -

@implementation MGWUJsonStreamParserStateStart

SINGLETON

- (BOOL)parser:(MGWUJsonStreamParser*)parser shouldAcceptToken:(mgwujson_token_t)token {
	return token == mgwujson_token_array_start || token == mgwujson_token_object_start;
}

- (void)parser:(MGWUJsonStreamParser*)parser shouldTransitionTo:(mgwujson_token_t)tok {

	MGWUJsonStreamParserState *state = nil;
	switch (tok) {
		case mgwujson_token_array_start:
			state = [MGWUJsonStreamParserStateArrayStart sharedInstance];
			break;

		case mgwujson_token_object_start:
			state = [MGWUJsonStreamParserStateObjectStart sharedInstance];
			break;

		case mgwujson_token_array_end:
		case mgwujson_token_object_end:
			if (parser.supportMultipleDocuments)
				state = parser.state;
			else
				state = [MGWUJsonStreamParserStateComplete sharedInstance];
			break;

		case mgwujson_token_eof:
			return;

		default:
			state = [MGWUJsonStreamParserStateError sharedInstance];
			break;
	}


	parser.state = state;
}

- (NSString*)name { return @"before outer-most array or object"; }

@end

#pragma mark -

@implementation MGWUJsonStreamParserStateComplete

SINGLETON

- (NSString*)name { return @"after outer-most array or object"; }

- (MGWUJsonStreamParserStatus)parserShouldReturn:(MGWUJsonStreamParser*)parser {
	return MGWUJsonStreamParserComplete;
}

@end

#pragma mark -

@implementation MGWUJsonStreamParserStateError

SINGLETON

- (NSString*)name { return @"in error"; }

- (MGWUJsonStreamParserStatus)parserShouldReturn:(MGWUJsonStreamParser*)parser {
	return MGWUJsonStreamParserError;
}

- (BOOL)isError {
    return YES;
}

@end

#pragma mark -

@implementation MGWUJsonStreamParserStateObjectStart

SINGLETON

- (NSString*)name { return @"at beginning of object"; }

- (BOOL)parser:(MGWUJsonStreamParser*)parser shouldAcceptToken:(mgwujson_token_t)token {
	switch (token) {
		case mgwujson_token_object_end:
		case mgwujson_token_string:
			return YES;
			break;
		default:
			return NO;
			break;
	}
}

- (void)parser:(MGWUJsonStreamParser*)parser shouldTransitionTo:(mgwujson_token_t)tok {
	parser.state = [MGWUJsonStreamParserStateObjectGotKey sharedInstance];
}

- (BOOL)needKey {
	return YES;
}

@end

#pragma mark -

@implementation MGWUJsonStreamParserStateObjectGotKey

SINGLETON

- (NSString*)name { return @"after object key"; }

- (BOOL)parser:(MGWUJsonStreamParser*)parser shouldAcceptToken:(mgwujson_token_t)token {
	return token == mgwujson_token_keyval_separator;
}

- (void)parser:(MGWUJsonStreamParser*)parser shouldTransitionTo:(mgwujson_token_t)tok {
	parser.state = [MGWUJsonStreamParserStateObjectSeparator sharedInstance];
}

@end

#pragma mark -

@implementation MGWUJsonStreamParserStateObjectSeparator

SINGLETON

- (NSString*)name { return @"as object value"; }

- (BOOL)parser:(MGWUJsonStreamParser*)parser shouldAcceptToken:(mgwujson_token_t)token {
	switch (token) {
		case mgwujson_token_object_start:
		case mgwujson_token_array_start:
		case mgwujson_token_true:
		case mgwujson_token_false:
		case mgwujson_token_null:
		case mgwujson_token_number:
		case mgwujson_token_string:
			return YES;
			break;

		default:
			return NO;
			break;
	}
}

- (void)parser:(MGWUJsonStreamParser*)parser shouldTransitionTo:(mgwujson_token_t)tok {
	parser.state = [MGWUJsonStreamParserStateObjectGotValue sharedInstance];
}

@end

#pragma mark -

@implementation MGWUJsonStreamParserStateObjectGotValue

SINGLETON

- (NSString*)name { return @"after object value"; }

- (BOOL)parser:(MGWUJsonStreamParser*)parser shouldAcceptToken:(mgwujson_token_t)token {
	switch (token) {
		case mgwujson_token_object_end:
		case mgwujson_token_separator:
			return YES;
			break;
		default:
			return NO;
			break;
	}
}

- (void)parser:(MGWUJsonStreamParser*)parser shouldTransitionTo:(mgwujson_token_t)tok {
	parser.state = [MGWUJsonStreamParserStateObjectNeedKey sharedInstance];
}


@end

#pragma mark -

@implementation MGWUJsonStreamParserStateObjectNeedKey

SINGLETON

- (NSString*)name { return @"in place of object key"; }

- (BOOL)parser:(MGWUJsonStreamParser*)parser shouldAcceptToken:(mgwujson_token_t)token {
    return mgwujson_token_string == token;
}

- (void)parser:(MGWUJsonStreamParser*)parser shouldTransitionTo:(mgwujson_token_t)tok {
	parser.state = [MGWUJsonStreamParserStateObjectGotKey sharedInstance];
}

- (BOOL)needKey {
	return YES;
}

@end

#pragma mark -

@implementation MGWUJsonStreamParserStateArrayStart

SINGLETON

- (NSString*)name { return @"at array start"; }

- (BOOL)parser:(MGWUJsonStreamParser*)parser shouldAcceptToken:(mgwujson_token_t)token {
	switch (token) {
		case mgwujson_token_object_end:
		case mgwujson_token_keyval_separator:
		case mgwujson_token_separator:
			return NO;
			break;

		default:
			return YES;
			break;
	}
}

- (void)parser:(MGWUJsonStreamParser*)parser shouldTransitionTo:(mgwujson_token_t)tok {
	parser.state = [MGWUJsonStreamParserStateArrayGotValue sharedInstance];
}

@end

#pragma mark -

@implementation MGWUJsonStreamParserStateArrayGotValue

SINGLETON

- (NSString*)name { return @"after array value"; }


- (BOOL)parser:(MGWUJsonStreamParser*)parser shouldAcceptToken:(mgwujson_token_t)token {
	return token == mgwujson_token_array_end || token == mgwujson_token_separator;
}

- (void)parser:(MGWUJsonStreamParser*)parser shouldTransitionTo:(mgwujson_token_t)tok {
	if (tok == mgwujson_token_separator)
		parser.state = [MGWUJsonStreamParserStateArrayNeedValue sharedInstance];
}

@end

#pragma mark -

@implementation MGWUJsonStreamParserStateArrayNeedValue

SINGLETON

- (NSString*)name { return @"as array value"; }


- (BOOL)parser:(MGWUJsonStreamParser*)parser shouldAcceptToken:(mgwujson_token_t)token {
	switch (token) {
		case mgwujson_token_array_end:
		case mgwujson_token_keyval_separator:
		case mgwujson_token_object_end:
		case mgwujson_token_separator:
			return NO;
			break;

		default:
			return YES;
			break;
	}
}

- (void)parser:(MGWUJsonStreamParser*)parser shouldTransitionTo:(mgwujson_token_t)tok {
	parser.state = [MGWUJsonStreamParserStateArrayGotValue sharedInstance];
}

@end

