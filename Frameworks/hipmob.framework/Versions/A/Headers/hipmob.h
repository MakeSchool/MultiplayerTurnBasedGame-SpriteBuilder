//
//  hipmobmainvc.h
//  hipmobnew
//
//  Created by Gaurav Namit <gaurav@hipmob.com> on 7/11/12.
//  Maintained by Femi Omojola <femi@hipmob.com>
//  Copyright (c) 2012 Orthogonal Labs Inc. All rights reserved.
//

#ifndef _hipmob_h
#define _hipmob_h
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <Security/SecCertificate.h>
#ifndef SRReadyState
typedef enum {
    SR_CONNECTING   = 0,
    SR_OPEN         = 1,
    SR_CLOSING      = 2,
    SR_CLOSED       = 3,
    
} SRReadyState;

@class SRWebSocket;

extern NSString *const SRWebSocketErrorDomain;

@protocol SRWebSocketDelegate;

@interface SRWebSocket : NSObject <NSStreamDelegate>

@property (nonatomic, assign) id <SRWebSocketDelegate> delegate;

@property (nonatomic, readonly) SRReadyState readyState;
@property (nonatomic, readonly, retain) NSURL *url;

// This returns the negotiated protocol.
// It will be niluntil after the handshake completes.
@property (nonatomic, readonly, copy) NSString *protocol;

// Protocols should be an array of strings that turn into Sec-WebSocket-Protocol
- (id)initWithURLRequest:(NSURLRequest *)request protocols:(NSArray *)protocols;
- (id)initWithURLRequest:(NSURLRequest *)request;

// Some helper constructors
- (id)initWithURL:(NSURL *)url protocols:(NSArray *)protocols;
- (id)initWithURL:(NSURL *)url;

// SRWebSockets are intended one-time-use only.  Open should be called once and only once
- (void)open;

- (void)close;
- (void)closeWithCode:(NSInteger)code reason:(NSString *)reason;

// Send a UTF8 String or Data
- (void)send:(id)data;

@end

@protocol SRWebSocketDelegate <NSObject>

// message will either be an NSString if the server is using text
// or NSData if the server is using binary
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message;

@optional

- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;

@end


@interface NSURLRequest (CertificateAdditions)

@property (nonatomic, retain, readonly) NSArray *SR_SSLPinnedCertificates;

@end


@interface NSMutableURLRequest (CertificateAdditions)

@property (nonatomic, retain) NSArray *SR_SSLPinnedCertificates;

@end
#endif

#ifndef kHipmobAuthURL
#define kHipmobAuthURL @"https://babble.hipmob.com/auth/1"
#endif
#ifndef kHipMObWebSocketURL
#define kHipMobWebSocketURL @"wss://babble.hipmob.com/live/1"
#endif
#ifndef kHipmobPendingURL
#define kHipmobPendingURL @"https://babble.hipmob.com/pending/1"
#endif
#define kPlistIDFileName @"hipmob.plist"
#define kPlistConvoFileName @"hipmobconvo.plist"
#define kHipMobMsgErrorTag 141592
#define defaultHMPopoverLandscape CGRectMake(830, 20, 20, 20)
#define defaultHMPopoverPortrait CGRectMake(590, 20, 20, 20)
#define defaultHMPopoverSize CGSizeMake(320, 245)

@class hipmobView;
@class hipmobPopOver;
@class hipmob;
@protocol hipmobViewDelegate<NSObject>;
//delegate methods
@optional
//delegate call
-(BOOL)launchURL:(NSString*)urlstring;
-(void)willDismissHipmobView:(hipmobView*)hipmobObj;
-(BOOL)receivedMessageFromID:(NSString*)senderid;
@end

@interface hipmob : UIViewController < UINavigationControllerDelegate>

@property (assign) id <hipmobViewDelegate> delegate;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *useremail;
@property (nonatomic, retain) NSString *localdeviceid;
@property (nonatomic, retain) NSString *context;
@property (nonatomic, retain) NSMutableDictionary *statusmessages;
@property (nonatomic, assign) BOOL localWebView;
@property (nonatomic, retain) NSString *peerdeviceid;
@property (nonatomic, retain) NSString *peertoken;

-(void)sendUpdate:(NSString*)variable withStatus:(NSString *)status;
-(void) setAvailabilityStatus:(BOOL)display;

-(id) initWithAppID:(NSString *)appidentifier;
-(id) initWithAppID:(NSString *)appidentifier andTitle:(NSString*)newtitle;

@end


typedef enum  {
    redimage =0,
    yellowimage=1,
    greenimage=2,
} operatorImageColor;
typedef enum  {
	disconnected = 0,
    connecting = 1,
    fullyconnected =2
} connectionState;

@protocol hipmobStaticDelegate<NSObject>;
@required
-(void)hipmobReceivedAuthError:(NSObject*)errorObj;
-(void)hipmobReceivedMessage;
-(void)hipmobConnectionChanged:(BOOL)connectionState;
-(void)hipmobIconStatusImage:(operatorImageColor)newcolor;
-(void)hipmobRespondToURL:(NSString *)urlString;

@end
@interface hipmobstatic : NSObject<NSURLConnectionDelegate, SRWebSocketDelegate>
{
    NSMutableDictionary *info;
    NSMutableDictionary *statusmessages;
    NSMutableArray *messages;
    id <hipmobViewDelegate> delegate;
    
}
@property (nonatomic, assign) NSMutableDictionary *info;
@property (assign) id<hipmobStaticDelegate>staticdelegate;
@property (assign) id <hipmobViewDelegate> delegate;
@property (nonatomic, retain) NSMutableArray *messages;
@property (nonatomic, assign) NSMutableDictionary *statusmessages;
-(BOOL) connectToHipmob;
-(id) initWithAppID:(NSString *)appidentifier;
- (BOOL)sendTxt:(NSString *)txtToSend;
-(void)dismissObj;
-(void)sendUpdate:(NSString*)variable withStatus:(NSString *)status;

@end


@interface hipmobvc : UIViewController < UIAlertViewDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate,hipmobStaticDelegate>
{
    NSString *useremail;
    NSString *localdeviceid;
    NSString *context;
    NSMutableDictionary *statusmessages;
    NSString *username;
    BOOL localWebView;
    NSString *peerdeviceid;
    NSString *peertoken;
    
    id <hipmobViewDelegate> delegate;
}
@property (nonatomic, assign) BOOL localWebView;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *useremail;
@property (nonatomic, retain) NSString *localdeviceid;
@property (nonatomic, retain) NSString *context;
@property (nonatomic, retain) NSMutableDictionary *statusmessages;
@property (nonatomic, retain) NSString *peerdeviceid;
@property (nonatomic, retain) NSString *peertoken;
-(void)sendUpdate:(NSString*)variable withStatus:(NSString *)status;

-(void) setAvailabilityStatus:(BOOL)display;
@property(nonatomic, retain) id <hipmobViewDelegate>delegate;
-(id) initWithAppID:(NSString *)appidentifier;
-(id) initWithAppID:(NSString *)appidentifier andTitle:(NSString*)newtitle;
@end

@interface hipmobvc ()
{
}
-(void) setNavBarItem:(UIBarButtonItem*)newitem;
-(void) rotateToPortrait;
-(void) sizeToCGSize:(CGSize)size supressLog:(BOOL)log;
-(void) setupFrames:(BOOL)hasStatus;
-(void) rotateToOrient:(UIInterfaceOrientation)orient;
@end

@interface hipmob()
{
    hipmobvc * vc;
    BOOL iPadObject;
    //Putting a callback object for ios4 to be able to have viewwillappear be triggered on hipmobVCObject
    UIViewController *parentVC;
}
@property(nonatomic, retain) UIViewController *parentVC;
@property (nonatomic, assign) BOOL iPadObject;
@property(nonatomic, retain)hipmobvc *vc;
@end


@interface hipmobView : UIViewController
{
    hipmob * service;
    BOOL displayed;
    
}
@property (nonatomic, readonly) BOOL displayed;
@property(nonatomic,retain) hipmob *service;
-(id) initWithAppID:(NSString *)appidentifier;
-(id) initWithAppID:(NSString *)appidentifier andTitle:(NSString*)newtitle;

@end

typedef enum{
    allOrientations=0,
    portraitonly=1,
    landscapeonly=2
}orientationChoices;
@interface hipmobPopOver : UIPopoverController<UIPopoverControllerDelegate>
{
    hipmob * service;
    UIView * parentView;
    orientationChoices orientation;
}
@property (nonatomic, assign) orientationChoices orientation;
@property (nonatomic, retain) UIView *parentView;
@property (nonatomic, retain) hipmob *service;
-(id) initWithAppID:(NSString *)appidentifier;
-(id) initWithAppID:(NSString *)appidentifier andTitle:(NSString*)newtitle;
-(void) setPosition:(CGRect)newPortrait andLandscape:(CGRect)newLandscape;
-(void)startChat;
-(void)setSize:(CGSize)newSize;

@end

#endif
