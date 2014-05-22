//
//  MGWU.m
//  mgwuSDK
//
//  Created by Ashu Desai on 4/7/12.
//  Copyright (c) 2012 makegameswithus inc. All rights reserved.
//

#define MGWU_BUILD_NUMBER 428

#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>

#ifndef APPORTABLE
#include <sys/types.h>
#include <sys/sysctl.h>
#import "MGWUSecureUDID.h"

#import <Social/Social.h>
#import <Twitter/Twitter.h>
#import <MessageUI/MessageUI.h>
#import <Crashlytics/Crashlytics.h>
#import <hipmob/hipmob.h>
#import <AWSS3/AWSS3.h>
#import "TapjoyConnect.h"
#import "MGWUAppirater.h"
#endif

#import "MGWU.h"
#import "MGWUServerRequest.h"
#import "MGWUMBProgressHUD.h"

#import "MGWUJsonParser.h"
#import "MGWUJsonWriter.h"
#import "Facebook.h"
#import "MGWUFBLoginViewController.h"
#import "MGWURainbow.h"
#import "MGWUIAPHelper.h"

#import "MGWUNotificationHandler.h"

#import "CrossPromoViewController.h"

#define GET_LEADERBOARDS 0
#define GET_MY_INFO 1
#define MAKE_MOVE 2

#define CROSSPROMO 0
#define ABOUT 1

#ifndef APPORTABLE
@interface MGWU () <UIWebViewDelegate, MGWUMBProgressHUDDelegate, MGWUIAPHelperDelegate, UIAlertViewDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, FBDialogDelegate>
#else
@interface MGWU () <UIWebViewDelegate, MGWUMBProgressHUDDelegate, MGWUIAPHelperDelegate, UIAlertViewDelegate, FBDialogDelegate>
#endif

+(BOOL)connectedToNetwork;
+(NSObject*)jsonObjectWithData:(NSData *)d;
+(NSData*)jsonDataWithObject:(NSObject*)o;
+(NSData*)symmetricEncrypt:(NSData*)d withKey:(NSData*)k;
+(NSData*)symmetricDecrypt:(NSData*)d withKey:(NSData*)k;
-(void)showHUDWithParams:(NSMutableDictionary*)params;
+(void)showError;
-(void)entering;
-(void)exiting;
@end

static NSString *server_url = @"https://dev.makegameswith.us/";
static NSString *link_url = @"https://www.mgw.us/";
static NSString *bucket_name;
static MGWU *mgwu;
static NSString *devId;
static NSString *deviceType;
static NSString *deviceVersion;
static NSString *deviceModel;
static NSString *playerId;
static NSString *appId;
static NSString *shortcode;
static NSString *appVersion;
static NSString *jailbroken;
static NSString *deviceToken;
static NSString *username;
static NSString *fbtoken;
static NSNumber *fbexp;
static NSData *unicorn;
static UIViewController *delegate;
static BOOL dark;
static UIWebView *wview;
static UIView *aboutview;
static int view;
static UIButton *closeButton;
static MGWUMBProgressHUD *HUD;
static long long opentime;
static id serverData;
static NSString *serverError;
static id target;
static SEL method;
static NSArray *leaderboards;
static NSString *leaderboard;
static NSMutableArray *logs;
static MGWUFBLoginViewController *fvc;
static NSDictionary *me;
static Facebook *facebook;
static BOOL fbOptional;
static BOOL noFacebook;
static BOOL noFacebookPrompt;
static BOOL preFacebook;
static BOOL noOpenGraph;
static int numOpens;
static NSNumber *build;
static UIBackgroundTaskIdentifier bgTask;
static MGWUIAPHelper *iAPHelper;
#ifndef APPORTABLE
static hipmob *supportvc;
#endif
static id testiAP;
static BOOL initialWebViewLoad;
static NSString *reminderMessage;
static UILocalNotification *dayReminder;
static UILocalNotification *threeDayReminder;
static UILocalNotification *weekReminder;
static UILocalNotification *twoWeekReminder;
static UILocalNotification *monthReminder;
static NSString *gameLink;
static UIAlertView *pastAlertView;
static NSString *gameLinkId;
static BOOL paused;
static AmazonS3Client *s3;

@implementation MGWU

+ (void)debug
{
	server_url = @"https://dev.makegameswith.us/";
	[MGWUServerRequest setServerURL:server_url andUnicorn:unicorn];
}

+ (void)logEvents:(NSString *)eventName withParams:(NSString *)params
{
	server_url = @"https://app.makegameswith.us/";
	[MGWUServerRequest setServerURL:server_url andUnicorn:unicorn];
}

+ (void)test
{
	server_url = @"http://test.makegameswith.us/";
	[MGWUServerRequest setServerURL:server_url andUnicorn:unicorn];
}

+ (void)local
{
	server_url = @"http://10.0.1.4:5000/";
	[MGWUServerRequest setServerURL:server_url andUnicorn:unicorn];
}

+ (void)invisiblePause
{
	paused = FALSE;
	UIButton *invisibleButton = [[UIButton alloc] init];
	invisibleButton = [UIButton buttonWithType:UIButtonTypeCustom];
	//[invisibleButton setImage:[UIImage imageNamed:@"MGWUClose.png"] forState:UIControlStateNormal];
	[invisibleButton addTarget:mgwu action:@selector(pause) forControlEvents:UIControlEventTouchUpInside];
	invisibleButton.frame = CGRectMake(5, 5, 50, 50);
	[[[UIApplication sharedApplication] keyWindow] addSubview:invisibleButton];
}

- (void)pause
{
	Class ccdir = NSClassFromString(@"CCDirector");
	if (ccdir)
	{
		id dir = [ccdir performSelector:@selector(sharedDirector)];
		if (paused)
			[dir performSelector:@selector(resume)];
		else
			[dir performSelector:@selector(pause)];
		paused = !paused;
	}
}

+ (NSString*)bundleIdentifier
{
	NSString *b = [[[NSBundle mainBundle] bundleIdentifier] stringByReplacingOccurrencesOfString:@"." withString:@"_"];
	NSArray *temp = [b componentsSeparatedByString:@"_"];
	if ([temp count] > 3)
		b = [[temp objectAtIndex:0] stringByAppendingFormat:@"_%@_%@", [temp objectAtIndex:1], [temp objectAtIndex:2]];
	return b;
}

+ (void)loadMGWU:(NSString*)dev
{
	NSAssert(dev, @"[MGWU] Need Developer Key");
	
	if (!mgwu)
		mgwu = [[MGWU alloc] initWithNibName:nil bundle:nil];
	
	initialWebViewLoad = true;
	
	build = [NSNumber numberWithInt:MGWU_BUILD_NUMBER];
	
	devId = dev;
	
#ifndef APPORTABLE //APPORTABLE TODO: replace with android functions
	deviceType = [[UIDevice currentDevice] model];
	deviceVersion = [[UIDevice currentDevice] systemVersion];
	deviceModel = [MGWU deviceModel];
	
	if ([deviceVersion floatValue] > 6.0)
		playerId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
	else
		playerId = [MGWUSecureUDID UDIDForMakeGamesWithUs];
	
	appId = [MGWU bundleIdentifier];
	shortcode = [appId stringByReplacingOccurrencesOfString:@"com_mgwu_" withString:@""];
	appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
#endif
	
	jailbroken = [MGWU isJailBroken];
	deviceToken = @"fail";
	opentime = 0;
	
	view = 0;
	dark = FALSE;
		
	HUD = nil;
	target = nil;
	method = nil;
	serverData = nil;
	leaderboards = nil;
	leaderboard = nil;
	
	fbOptional = TRUE;
	noFacebook = [[[NSUserDefaults standardUserDefaults] objectForKey:@"mgwu_nofacebook"] boolValue];
	noOpenGraph = [[[NSUserDefaults standardUserDefaults] objectForKey:@"mgwu_noopengraph"] boolValue];
	preFacebook = FALSE;
	noFacebookPrompt = FALSE;
	
	me = [[NSUserDefaults standardUserDefaults] objectForKey:@"mgwu_fbobject_self"];
	username = [me objectForKey:@"username"];
	if (!username)
		username = [me objectForKey:@"id"];

	fbtoken = [[NSUserDefaults standardUserDefaults] objectForKey:@"mgwu_fbtoken"];
	fbexp = [[NSUserDefaults standardUserDefaults] objectForKey:@"mgwu_fbexp"];
	
	unicorn = [[MGWURainbow rainbows] dataUsingEncoding:NSUTF8StringEncoding];
	[MGWUServerRequest setServerURL:server_url andUnicorn:unicorn];
	[MGWUServerRequest setGenericParams:@{@"mgwubuild":build, @"mgid":playerId, @"appid":appId, @"appver":appVersion, @"devid":devId}];
	
	logs = [[NSUserDefaults standardUserDefaults] objectForKey:@"mgwu_logs"];
	if (!logs)
		logs = [NSMutableArray new];
	
	//[mgwu preloadWebView];
	initialWebViewLoad = false;
	
	[[NSNotificationCenter defaultCenter] addObserver:mgwu
											 selector:@selector(entering)
												 name:UIApplicationDidBecomeActiveNotification
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:mgwu
											 selector:@selector(exiting)
												 name:UIApplicationWillResignActiveNotification
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:mgwu
											 selector:@selector(closefbsession)
												 name:UIApplicationWillTerminateNotification
											   object:nil];
	
	[[UIApplication sharedApplication]
     registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeAlert |
      UIRemoteNotificationTypeBadge |
      UIRemoteNotificationTypeSound)];

}


+ (void)dark
{
	dark = true;
}

+ (void)setReminderMessage:(NSString*)message
{
	reminderMessage = message;
}

//- (void)preloadWebView
//{
//
//	
//	NSString *u = [NSString stringWithFormat:@"%@blankpage", server_url];
//	//Post Request With ID
//	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:server_url] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30];
//	
////	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
////	
////	[params setObject:build forKey:@"mgwubuild"];
////	
////	[params setObject:playerId forKey:@"mgid"];
////	[params setObject:appId forKey:@"appid"];
////	[params setObject:devId forKey:@"devid"];
////	
////	NSData* dparam = [MGWU jsonDataWithObject:params];
////	NSData* dp = [MGWU symmetricEncrypt:dparam withKey:unicorn];
//	
//	//[request setHTTPMethod:@"POST"];
//	//[request setValue:@"application/mgwu" forHTTPHeaderField:@"content-type"];
//	//[request setHTTPBody:dp];
//	[wview loadRequest:request];
//	
////	[wview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
//}

+ (void)forceFacebook
{
	fbOptional = FALSE;
}

+ (void)preFacebook
{
	preFacebook = TRUE;
}

+ (void)noFacebookPrompt
{
	noFacebookPrompt = TRUE;
}

+ (void)useIAPs
{
	iAPHelper = [[MGWUIAPHelper alloc] init];
	iAPHelper.delegate = mgwu;
	[[SKPaymentQueue defaultQueue] addTransactionObserver:iAPHelper];
}

+ (void)useS3WithAccessKey:(NSString*)accessKey andSecretKey:(NSString*)secretKey
{
	if ([server_url isEqualToString:@"https://app.makegameswith.us/"])
	{
		s3 = [[AmazonS3Client alloc] initWithAccessKey:accessKey withSecretKey:secretKey];
		bucket_name = [appId stringByAppendingString:@"_game_files"];
	}
	else
	{
		s3 = [[AmazonS3Client alloc] initWithAccessKey:@"AKIAJR5BHIEUYF3UJZTQ" withSecretKey:@"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"];
		bucket_name = @"com_mgwu_dev_game_files";
	}
	[MGWUServerRequest setS3:s3 andBucketName:bucket_name];
}

+ (void)useCrashlytics
{
#ifndef APPORTABLE
	[Crashlytics startWithAPIKey:@"54f14897828d5bb9163762c28df2ab3b1296a1cc"];
#endif
}

+ (void)useCrashlyticsWithApiKey:(NSString*)apiKey
{
#ifndef APPORTABLE //APPORTABLE TODO: replace with android crash reporting
	[Crashlytics startWithAPIKey:apiKey];
#endif
}

+ (void)debugCrashlytics
{
#ifndef APPORTABLE
	[Crashlytics sharedInstance].debugMode = TRUE;
#endif
}

+ (void)forceCrash
{
#ifndef APPORTABLE
	[[Crashlytics sharedInstance] crash];
#endif
}

+ (void)setHipmobAppId:(NSString*)hipmobappid andAwayMessage:(NSString*)awaymessage
{
#ifndef APPORTABLE
	NSAssert(hipmobappid && awaymessage, @"[MGWU] Need AppID and Away Message");
	
	supportvc = [[hipmob alloc] initWithAppID:hipmobappid andTitle:@"Hipmob Support Chat"];
	[supportvc.statusmessages setValue:awaymessage forKey:@"operatoroffline"];
	[supportvc.statusmessages setValue:@"Hi there, how can I help you? Any feedback on the game is appreciated!" forKey:@"operatoronline"];
	[supportvc.statusmessages removeObjectForKey:@"connecting"];
	[supportvc.statusmessages removeObjectForKey:@"connected"];
	[supportvc.statusmessages removeObjectForKey:@"disconnected"];
#endif
}

+ (void)displayHipmob
{
#ifndef APPORTABLE
	//NSAssert(supportvc, @"[MGWU] You must initialize hipmob");
	
	if (!supportvc)
		return;
	
	[[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:supportvc animated:YES];
#endif
}

+ (void)setTapjoyAppId:(NSString*)tapappid andSecretKey:(NSString*)tapseckey
{
#ifndef APPORTABLE //APPORTABLE TODO: replace with android tapjoy
	NSAssert(tapappid && tapseckey, @"[MGWU] Need AppID and Secret Key");
	
	[TapjoyConnect requestTapjoyConnect:tapappid secretKey:tapseckey];
#endif
}

+ (void)setAppiraterAppId:(NSString*)appappid andAppName:(NSString*)appappname
{
#ifndef APPORTABLE
	NSAssert(appappid && appappname, @"[MGWU] Need AppID and AppName");
	
	[MGWUAppirater setAppId:appappid andAppName:appappname];
#endif
}

+ (void)launchAppStorePage
{
#ifndef APPORTABLE
	[MGWUAppirater openAppStore];
#endif
}

- (void)entering {
	
	numOpens = [[[NSUserDefaults standardUserDefaults] objectForKey:@"mgwu_numopens"] intValue];
	numOpens++;
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:numOpens] forKey:@"mgwu_numopens"];
	
	opentime = [[NSDate date] timeIntervalSince1970];
	[MGWU logEvent:@"open"];

#ifndef APPORTABLE
	[MGWUAppirater appEnteredForeground:YES];
#endif
	
	if (reminderMessage)
	{
		for (UILocalNotification* note in [[UIApplication sharedApplication] scheduledLocalNotifications])
		{
			if ([[note.userInfo allKeys] containsObject:@"source"] && [[note.userInfo objectForKey:@"source"] isEqualToString:@"mgwuSDK"])
				[[UIApplication sharedApplication] cancelLocalNotification:note];
		}
		
		//[[UIApplication sharedApplication] cancelAllLocalNotifications];
//		if (dayReminder)
//			[[UIApplication sharedApplication] cancelLocalNotification:dayReminder];
//		if (threeDayReminder)
//			[[UIApplication sharedApplication] cancelLocalNotification:threeDayReminder];
//		if (weekReminder)
//			[[UIApplication sharedApplication] cancelLocalNotification:weekReminder];
//		if (twoWeekReminder)
//			[[UIApplication sharedApplication] cancelLocalNotification:twoWeekReminder];
//		if (monthReminder)
//			[[UIApplication sharedApplication] cancelLocalNotification:monthReminder];
		
//		dayReminder = [MGWU sendPushMessage:reminderMessage afterMinutes:1 withData:@{@"type":@"day"}];
//		threeDayReminder = [MGWU sendPushMessage:reminderMessage afterMinutes:2 withData:@{@"type":@"3day"}];
//		weekReminder = [MGWU sendPushMessage:reminderMessage afterMinutes:(60*24*7) withData:@{@"type":@"week"}];
//		twoWeekReminder = [MGWU sendPushMessage:reminderMessage afterMinutes:(60*24*14) withData:@{@"type":@"2week"}];
//		monthReminder = [MGWU sendPushMessage:reminderMessage afterMinutes:(60*24*30) withData:@{@"type":@"month"}];
		
//		[MGWU sendPushMessage:@"one" afterMinutes:1 withData:@{@"source":@"mgwuSDK"}];
//		[MGWU sendPushMessage:@"two" afterMinutes:2 withData:@{@"source":@"mgwuSDK"}];
//		[MGWU sendPushMessage:@"three" afterMinutes:3 withData:@{@"source":@"mgwuSDK"}];
		
		dayReminder = [MGWU sendPushMessage:reminderMessage afterMinutes:(60*24) withData:@{@"type":@"day", @"source":@"mgwuSDK"}];
		threeDayReminder = [MGWU sendPushMessage:reminderMessage afterMinutes:(60*24*3) withData:@{@"type":@"3day", @"source":@"mgwuSDK"}];
		weekReminder = [MGWU sendPushMessage:reminderMessage afterMinutes:(60*24*7) withData:@{@"type":@"week", @"source":@"mgwuSDK"}];
		twoWeekReminder = [MGWU sendPushMessage:reminderMessage afterMinutes:(60*24*14) withData:@{@"type":@"2week", @"source":@"mgwuSDK"}];
		monthReminder = [MGWU sendPushMessage:reminderMessage afterMinutes:(60*24*30) withData:@{@"type":@"month", @"source":@"mgwuSDK"}];
	}
	
	if (pastAlertView)
		[pastAlertView show];
	
	if (preFacebook || (noFacebook && numOpens != 12 && numOpens != 24))
		return;
	
	if (!FBSession.activeSession.isOpen) {
		
		NSArray *perms = [[NSUserDefaults standardUserDefaults] objectForKey:@"mgwu_fbpermissions"];
		if (!perms)
			perms = @[@"email", @"publish_actions"];
        // create a fresh session object
        FBSession.activeSession = [[FBSession alloc] initWithPermissions:perms];
        
        // if we don't have a cached token, a call to open here would cause UX for login to
        // occur; we don't want that to happen unless the user clicks the login button, and so
        // we check here to make sure we have a token before calling open
        if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
            // even though we had a cached token, we need to login to make the session usable
            [FBSession.activeSession openWithCompletionHandler:^(FBSession *session,
																 FBSessionState status,
																 NSError *error) {
				
				facebook = [[Facebook alloc]
							initWithAppId:FBSession.activeSession.appID
							andDelegate:nil];
				
                // Store the Facebook session information
                facebook.accessToken = FBSession.activeSession.accessToken;
                facebook.expirationDate = FBSession.activeSession.expirationDate;
				
				fbtoken = FBSession.activeSession.accessToken;
				long long time = [FBSession.activeSession.expirationDate timeIntervalSince1970];
				fbexp = [NSNumber numberWithLongLong:time];

				[[NSUserDefaults standardUserDefaults] setObject:fbtoken forKey:@"mgwu_fbtoken"];
				[[NSUserDefaults standardUserDefaults] setObject:fbexp forKey:@"mgwu_fbexp"];
								
				FBRequestConnection *c = [[FBRequestConnection alloc] init];
				
				FBRequest *r1 = [FBRequest requestForMe];
				[c addRequest:r1 completionHandler:^(FBRequestConnection *connection, id result, NSError *error){
					if (result)
					{
						
						if ([[result allKeys] containsObject:@"username"])
						{
							[result setObject:[[result objectForKey:@"username"] stringByReplacingOccurrencesOfString:@"." withString:@"_"] forKey:@"username"];
							username = [result objectForKey:@"username"];
						}
						else
							username = [result objectForKey:@"id"];
						
						me = result;
						[[NSUserDefaults standardUserDefaults] setObject:result forKey:@"mgwu_fbobject_self"];
						
						//NSLog(@"got self");
					}
				}];
				
				FBRequest *r2 = [[FBRequest alloc] initWithSession:FBSession.activeSession graphPath:@"me/friends" parameters:@{ @"fields" : @"id,name,username,installed,devices" } HTTPMethod:nil];
				
				[c addRequest:r2 completionHandler:^(FBRequestConnection *connection, id result, NSError *error){
					if (result)
					{
						NSMutableArray* friendsPlaying = [[NSMutableArray alloc] init];
						NSMutableArray* friendsToInvite = [[NSMutableArray alloc] init];
						NSMutableDictionary* usernameToId = [[NSMutableDictionary alloc] init];
						NSMutableArray *friendsPlayingGame = [[NSMutableArray alloc] init];
						
						NSArray *dd = [result objectForKey:@"data"];
						
						NSArray *d = [dd sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
							NSString *first = [a objectForKey:@"name"];
							NSString *second = [b objectForKey:@"name"];
							return [first compare:second];
						}];
						
						for (NSMutableDictionary *f in d)
						{
							if (![[f allKeys] containsObject:@"username"])
								[f setObject:[f objectForKey:@"id"] forKey:@"username"];
							else
								[f setObject:[[f objectForKey:@"username"] stringByReplacingOccurrencesOfString:@"." withString:@"_"] forKey:@"username"];
							
							[usernameToId setObject:[f objectForKey:@"id"] forKey:[f objectForKey:@"username"]];
							
							if ([[f allKeys] containsObject:@"installed"] && [[f objectForKey:@"installed"] boolValue] == YES)
							{
								[friendsPlaying addObject:[f objectForKey:@"id"]];
								[f removeObjectForKey:@"id"];
								[friendsPlayingGame addObject:f];
							}
							else
							{
								for (NSDictionary *d in [f objectForKey:@"devices"])
								{
#ifndef APPORTABLE
									if ([[d objectForKey:@"os"] isEqualToString:@"iOS"])
									{
										[f removeObjectForKey:@"id"];
										[friendsToInvite addObject:f];
										break;
									}
#else
									if ([[d objectForKey:@"os"] isEqualToString:@"iOS"] || [[d objectForKey:@"os"] isEqualToString:@"Android"])
									{
										[f removeObjectForKey:@"id"];
										[friendsToInvite addObject:f];
										break;
									}
#endif
								}
							}
						}
						
						[[NSUserDefaults standardUserDefaults] setObject:friendsPlayingGame forKey:@"mgwu_friendsplayinggame"];
						[[NSUserDefaults standardUserDefaults] setObject:friendsPlaying forKey:@"mgwu_friendsplaying"];
						[[NSUserDefaults standardUserDefaults] setObject:friendsToInvite forKey:@"mgwu_friendstoinvite"];
						[[NSUserDefaults standardUserDefaults] setObject:usernameToId forKey:@"mgwu_usernametoid"];
						[[NSUserDefaults standardUserDefaults] synchronize];
						//NSLog(@"got friends");
					}
				}];
				
				[c start];
                // we recurse here, in order to update buttons and labels
				// [self updateView];
            }];
        }
		else if (!noFacebookPrompt)
		{
			if (!fvc)
			{
				if (UIDeviceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]))
				{
					if (dark)
						fvc = [[MGWUFBLoginViewController alloc] initWithNibName:@"MGWUFacebookLoginPortraitDark" bundle:nil];
					else
						fvc = [[MGWUFBLoginViewController alloc] initWithNibName:@"MGWUFacebookLoginPortrait" bundle:nil];
				}
				else
				{
					if (dark)
						fvc = [[MGWUFBLoginViewController alloc] initWithNibName:@"MGWUFacebookLoginLandscapeDark" bundle:nil];
					else
						fvc = [[MGWUFBLoginViewController alloc] initWithNibName:@"MGWUFacebookLoginLandscape" bundle:nil];
				}
				
				fvc.mgwu = mgwu;
				fvc.fbOptional = fbOptional;
				
				delegate = [[UIApplication sharedApplication] keyWindow].rootViewController;
				[delegate presentModalViewController:fvc animated:YES];

				[MGWU logEvent:@"facebook_loggingin"];
			}
			//Show Facebook Login View
		}
	}
}

- (void)sendFacebookToServer
{
	if (username)
	{
		NSString *u = [NSString stringWithFormat:@"%@savefb", server_url];
		NSMutableURLRequest *request = [NSMutableURLRequest
										requestWithURL:[NSURL URLWithString:u]];
		
		NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
		
		[params setObject:build forKey:@"mgwubuild"];
		
		[params setObject:playerId forKey:@"mgid"];
		[params setObject:appId forKey:@"appid"];
		[params setObject:devId forKey:@"devid"];
		[params setObject:username forKey:@"username"];
		[params setObject:[me objectForKey:@"name"] forKey:@"fbname"];
		[params setObject:[me objectForKey:@"id"] forKey:@"fbid"];
		[params setObject:fbtoken forKey:@"fbtoken"];
		[params setObject:fbexp forKey:@"fbexp"];
		
		
		NSData* dparam = [MGWU jsonDataWithObject:params];
		NSData* dp = [MGWU symmetricEncrypt:dparam withKey:unicorn];
		
		[request setHTTPMethod:@"POST"];
		[request setValue:@"application/mgwu" forHTTPHeaderField:@"content-type"];
		[request setHTTPBody:dp];
		[NSURLConnection connectionWithRequest:request delegate:nil];
		
		NSDictionary *event_params;
		NSArray *perms = [[NSUserDefaults standardUserDefaults] objectForKey:@"mgwu_fbpermissions"];
		if (perms && [perms containsObject:@"publish_actions"])
			event_params = @{@"publish_permission":@TRUE};
		else
			event_params = @{@"publish_permission":@FALSE};
		[MGWU logEvent:@"facebook_loggedin" withParams:event_params];
	}
}

+ (void)loginToFacebook
{
	[mgwu login];
}

+ (void)loginToFacebookWithCallback:(SEL)m onTarget:(id)t
{
	NSAssert(m && t, @"[MGWU] Need Callback Method and Target");
	
	method = m;
	target = t;
	
	[mgwu login];
}

- (void)login
{
	[MGWU logEvent:@"facebook_login_tapped"];
	
	NSArray *perms = [[NSUserDefaults standardUserDefaults] objectForKey:@"mgwu_fbpermissions"];
	if (!perms)
		perms = @[@"email", @"publish_actions"];
	// create a fresh session object
	FBSession.activeSession = [[FBSession alloc] initWithPermissions:perms];
	
	[FBSession.activeSession openWithCompletionHandler:^(FBSession *session,
														 FBSessionState status,
														 NSError *error) {
		
		if (session.state == FBSessionStateClosedLoginFailed)
		{
			[MGWU showError];
			
			serverData = nil;
			
			if (target && method)
			{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
				[target performSelector:method withObject:serverData];
#pragma clang diagnostic pop
				target = nil;
				method = nil;
			}
			
			return;
		}
		
		HUD = [MGWUMBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] keyWindow] animated:YES];
		HUD.labelText = @"Loading...";
		
		noFacebook = FALSE;
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:noFacebook] forKey:@"mgwu_nofacebook"];
		
		facebook = [[Facebook alloc]
					initWithAppId:FBSession.activeSession.appID
					andDelegate:nil];
		
		// Store the Facebook session information
		facebook.accessToken = FBSession.activeSession.accessToken;
		facebook.expirationDate = FBSession.activeSession.expirationDate;
		
		fbtoken = FBSession.activeSession.accessToken;
		long long time = [FBSession.activeSession.expirationDate timeIntervalSince1970];
		fbexp = [NSNumber numberWithLongLong:time];

		[[NSUserDefaults standardUserDefaults] setObject:fbtoken forKey:@"mgwu_fbtoken"];
		[[NSUserDefaults standardUserDefaults] setObject:fbexp forKey:@"mgwu_fbexp"];
		
		FBRequestConnection *c = [[FBRequestConnection alloc] init];
		
		FBRequest *r1 = [FBRequest requestForMe];
		[c addRequest:r1 completionHandler:^(FBRequestConnection *connection, id result, NSError *error){
			if (result)
			{
				if ([[result allKeys] containsObject:@"username"])
				{
					[result setObject:[[result objectForKey:@"username"] stringByReplacingOccurrencesOfString:@"." withString:@"_"] forKey:@"username"];
					username = [result objectForKey:@"username"];
				}
				else
					username = [result objectForKey:@"id"];
				
				me = result;
				[[NSUserDefaults standardUserDefaults] setObject:result forKey:@"mgwu_fbobject_self"];
				
				//NSLog(@"got self");
			}
		}];
		
		FBRequest *r3 = [[FBRequest alloc] initWithSession:FBSession.activeSession graphPath:@"me/permissions" parameters:nil HTTPMethod:nil];
		[c addRequest:r3 completionHandler:^(FBRequestConnection *connection, id result, NSError *error){
			if (result)
			{
				NSDictionary *p = [[result objectForKey:@"data"] objectAtIndex:0];
				NSMutableArray *perms = [[NSMutableArray alloc] init];
				if ([[p allKeys] containsObject:@"email"])
					[perms addObject:@"email"];
				if ([[p allKeys] containsObject:@"publish_actions"])
					[perms addObject:@"publish_actions"];
				[[NSUserDefaults standardUserDefaults] setObject:perms forKey:@"mgwu_fbpermissions"];
			}
		}];
		
		FBRequest *r2 = [[FBRequest alloc] initWithSession:FBSession.activeSession graphPath:@"me/friends" parameters:@{ @"fields" : @"id,name,username,installed,devices" } HTTPMethod:nil];
		
		[c addRequest:r2 completionHandler:^(FBRequestConnection *connection, id result, NSError *error){
			if (result)
			{
				NSMutableArray *friendsPlaying = [[NSMutableArray alloc] init];
				NSMutableArray *friendsToInvite = [[NSMutableArray alloc] init];
				NSMutableArray *friendsPlayingGame = [[NSMutableArray alloc] init];
				
				NSMutableDictionary *usernameToId = [[NSMutableDictionary alloc] init];
				
				NSArray *dd = [result objectForKey:@"data"];
				
				NSArray *d = [dd sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
					NSString *first = [a objectForKey:@"name"];
					NSString *second = [b objectForKey:@"name"];
					return [first compare:second];
				}];
				
				for (NSMutableDictionary *f in d)
				{
					if (![[f allKeys] containsObject:@"username"])
						[f setObject:[f objectForKey:@"id"] forKey:@"username"];
					else
						[f setObject:[[f objectForKey:@"username"] stringByReplacingOccurrencesOfString:@"." withString:@"_"] forKey:@"username"];
					
					[usernameToId setObject:[f objectForKey:@"id"] forKey:[f objectForKey:@"username"]];
					
					if ([[f allKeys] containsObject:@"installed"] && [[f objectForKey:@"installed"] boolValue] == YES)
					{
						[friendsPlaying addObject:[f objectForKey:@"id"]];
						[f removeObjectForKey:@"id"];
						[friendsPlayingGame addObject:f];
					}
					else
					{
						for (NSDictionary *d in [f objectForKey:@"devices"])
						{
#ifndef APPORTABLE
							if ([[d objectForKey:@"os"] isEqualToString:@"iOS"])
							{
								[f removeObjectForKey:@"id"];
								[friendsToInvite addObject:f];
								break;
							}
#else
							if ([[d objectForKey:@"os"] isEqualToString:@"iOS"] || [[d objectForKey:@"os"] isEqualToString:@"Android"])
							{
								[f removeObjectForKey:@"id"];
								[friendsToInvite addObject:f];
								break;
							}
#endif
						}
					}
				}
				
				[[NSUserDefaults standardUserDefaults] setObject:friendsPlayingGame forKey:@"mgwu_friendsplayinggame"];
				[[NSUserDefaults standardUserDefaults] setObject:friendsPlaying forKey:@"mgwu_friendsplaying"];
				[[NSUserDefaults standardUserDefaults] setObject:friendsToInvite forKey:@"mgwu_friendstoinvite"];
				[[NSUserDefaults standardUserDefaults] setObject:usernameToId forKey:@"mgwu_usernametoid"];
				[[NSUserDefaults standardUserDefaults] synchronize];
//				NSLog(@"got friends");
				
				serverData = @"Success";
				[HUD removeFromSuperview];
				HUD = nil;
				[self close];
				[self sendFacebookToServer];
			}
			else
			{
				serverData = nil;
				[HUD removeFromSuperview];
				HUD = nil;
				[MGWU showError];
			}
			
			if (target && method)
			{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
				[target performSelector:method withObject:serverData];
#pragma clang diagnostic pop
				target = nil;
				method = nil;
			}
			
			serverData = nil;
			
		}];
		
		[c start];
	}];
}

- (void)exiting {
	
	bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        // Clean up any unfinished task business by marking where you.
        // stopped or ending the task outright.
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
	
	int sessionLength = [[NSDate date] timeIntervalSince1970] - opentime;
	NSDictionary *d = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:sessionLength], @"session_length", nil];
	[MGWU logEventBackground:@"close" withParams:d];
	opentime = 0;
	
    // Start the long-running task and return immediately.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		
		// Do the work associated with the task, preferably in chunks.
		@synchronized(logs)
		{
			if ([logs count] > 0)
			{
				NSString *u = [NSString stringWithFormat:@"%@logevents", server_url];
				NSMutableURLRequest *request = [NSMutableURLRequest
												requestWithURL:[NSURL URLWithString:u]];
				
				NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
				
				[params setObject:build forKey:@"mgwubuild"];
				
				[params setObject:playerId forKey:@"mgid"];
				[params setObject:deviceToken forKey:@"deviceToken"];
				[params setObject:appId forKey:@"appid"];
				[params setObject:devId forKey:@"devid"];
				[params setObject:logs forKey:@"logs"];
				
				if ([MGWU isFacebookActive])
				{
					[params setObject:username forKey:@"username"];
					[params setObject:[me objectForKey:@"id"] forKey:@"fbid"];
					[params setObject:fbtoken forKey:@"fbtoken"];
					[params setObject:fbexp forKey:@"fbexp"];
					if ([[me allKeys] containsObject:@"email"])
						[params setObject:[me objectForKey:@"email"] forKey:@"email"];
				}
				
				NSData* dparam = [MGWU jsonDataWithObject:params];
				NSData* dp = [MGWU symmetricEncrypt:dparam withKey:unicorn];
				
				[request setHTTPMethod:@"POST"];
				[request setValue:@"application/mgwu" forHTTPHeaderField:@"content-type"];
				[request setHTTPBody:dp];
				
				NSURLResponse *urlResponse = nil;
				NSError *urlError = nil;
				
				NSData *urlData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&urlError];
				
				if (!urlError && urlData && urlResponse && [[urlResponse MIMEType] isEqualToString:@"application/mgwu"])
				{
					[logs removeAllObjects];
					[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"mgwu_logs"];
					[[NSUserDefaults standardUserDefaults] synchronize];
				}
			}
		}

        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    });
	
}

+ (void)logEvent:(NSString*)eventName{
	
	NSAssert(eventName, @"[MGWU] Need Event Name");
	
	[MGWU logEvent:eventName withParams:nil];
}

+ (void)logEvent:(NSString*)eventName withParams:(NSDictionary*)params{
	
	NSAssert(eventName, @"[MGWU] Need Event Name");
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[MGWU logEventBackground:eventName withParams:params];
	});

}

+ (void)logEventBackground:(NSString*)eventName withParams:(NSDictionary*)params{
	//	NSString *timestamp = [NSString stringWithFormat:@"%0.0f", [[NSDate date] timeIntervalSince1970]];
	long long time = [[NSDate date] timeIntervalSince1970];
	NSNumber *timestamp = [NSNumber numberWithLongLong:time];
	
	NSMutableDictionary *d;
	
	if (params)
		d = [[NSMutableDictionary alloc] initWithDictionary:params];
	else
		d = [[NSMutableDictionary alloc] init];
	
	[d setObject:eventName forKey:@"event"];
	[d setObject:timestamp forKey:@"time"];
	[d setObject:playerId forKey:@"mgid"];
	[d setObject:deviceType forKey:@"devicetype"];
	[d setObject:deviceVersion forKey:@"devicever"];
	[d setObject:deviceModel forKey:@"devicemodel"];
	[d setObject:jailbroken forKey:@"jailbroken"];
	[d setObject:appId forKey:@"appid"];
	[d setObject:appVersion forKey:@"appver"];
	[d setObject:build forKey:@"mgwubuild"];
	
	@synchronized(logs)
	{
		[logs addObject:d];
		
		[[NSUserDefaults standardUserDefaults] setObject:logs forKey:@"mgwu_logs"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	
}

+ (UILocalNotification*)sendPushMessage:(NSString*)message afterMinutes:(int)minutes withData:(NSDictionary*)data
{
	NSDate *today = [NSDate date];
	
    UILocalNotification *localNotif = [[UILocalNotification alloc] init];

	localNotif.fireDate = [today dateByAddingTimeInterval:(minutes*60)];
    localNotif.timeZone = [NSTimeZone defaultTimeZone];
	
    localNotif.alertBody = message;
    localNotif.soundName = UILocalNotificationDefaultSoundName;
	
	if (data)
	{
		localNotif.userInfo = data;
//		if ([[data allKeys] containsObject:@"incrementBadge"])
//		{
//			int b = [[UIApplication sharedApplication] applicationIconBadgeNumber];
//			b += [[data objectForKey:@"incrementBadge"] intValue];
//			localNotif.applicationIconBadgeNumber = b;
//		}
	}
	
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
	
	return localNotif;
}

+ (void)gotLocalPush:(UILocalNotification*)localNotif
{
	if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
	{
		[MGWU showMessage:localNotif.alertBody withImage:nil];
		
//		if (localNotif.applicationIconBadgeNumber 
//		if ([[aps allKeys] containsObject:@"badge"])
//		{
//			int badge = [[aps objectForKey:@"badge"] intValue];
//			[[UIApplication sharedApplication] setApplicationIconBadgeNumber:badge];
//		}
//		else
//		{
//			[[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
//		}
	}
}

+ (void)registerForPush:(NSData *)tokenId {
	deviceToken = [[[[tokenId description]
					 stringByReplacingOccurrencesOfString: @"<" withString: @""]
					stringByReplacingOccurrencesOfString: @">" withString: @""]
				   stringByReplacingOccurrencesOfString: @" " withString: @""];
}

+ (void)gotPush:(NSDictionary *)userInfo {
	if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
	{
		if ([[userInfo allKeys] containsObject:@"link"])
		{
			gameLink = [userInfo objectForKey:@"link"];
			gameLinkId = [userInfo objectForKey:@"appid"];
			
			NSString *message;
			NSDictionary *aps = [userInfo objectForKey:@"aps"];
			id alert = [aps objectForKey:@"alert"];
			if ([alert isKindOfClass:[NSString class]])
				message = alert;
			else
				message = [alert objectForKey:@"body"];
			
			NSString *title = @"Cool New Game!";
			NSString *cancel = @"No Thanks";
			NSString *accept = @"Get It Now!";
			if ([[userInfo allKeys] containsObject:@"title"])
				title = [userInfo objectForKey:@"title"];
			if ([[userInfo allKeys] containsObject:@"cancel"])
				cancel = [userInfo objectForKey:@"cancel"];
			if ([[userInfo allKeys] containsObject:@"accept"])
				accept = [userInfo objectForKey:@"accept"];
			
			if (!pastAlertView)
				pastAlertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:mgwu cancelButtonTitle:cancel otherButtonTitles:accept, nil];
		}
		else
		{
			NSDictionary *aps = [userInfo objectForKey:@"aps"];
			if ([[aps allKeys] containsObject:@"alert"])
			{
				id alert = [aps objectForKey:@"alert"];
				if ([alert isKindOfClass:[NSString class]])
					[MGWU showMessage:alert withImage:nil];
				else
					[MGWU showMessage:[alert objectForKey:@"body"] withImage:nil];
			}
			
			if ([[aps allKeys] containsObject:@"badge"])
			{
				int badge = [[aps objectForKey:@"badge"] intValue];
				[[UIApplication sharedApplication] setApplicationIconBadgeNumber:badge];
			}
			else
			{
				[[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
			}
		}
	}
	else
	{
		if ([[userInfo allKeys] containsObject:@"link"])
		{
			NSString *link = [userInfo objectForKey:@"link"];
			NSString *gameId = [userInfo objectForKey:@"appid"];
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:link]];
			[MGWU logEvent:@"push_appstore_opened" withParams:@{@"linkedapp":gameId, @"appstate":@"inactive"}];
		}
	}
}

+ (void)failedPush:(NSError *)error {
	deviceToken = @"fail";
}

+ (BOOL)handleURL:(NSURL*)url {
    // attempt to extract a token from the url
    return [FBSession.activeSession handleOpenURL:url];
}

- (void)closefbsession
{
	if ([MGWU isFacebookActive])
		[FBSession.activeSession close];
}

//- (void)applicationWillTerminate:(UIApplication *)application {
//    // FBSample logic
//    // if the app is going away, we close the session object
//    [FBSession.activeSession close];
//}

+ (void)display
{
//	NSString *u = [NSString stringWithFormat:@"%@crosspromodata", server_url];
//	//Post Request With ID
//	
//	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
//	
//	[params setObject:build forKey:@"mgwubuild"];
//	[params setObject:u forKey:@"url"];
//	[params setObject:playerId forKey:@"mgid"];
//	[params setObject:appId forKey:@"appid"];
//	[params setObject:devId forKey:@"devid"];
//	
//	CrossPromoViewController *cpvc = [[CrossPromoViewController alloc] initWithNibName:@"CrossPromoViewController" bundle:nil andParams:params andUnicorn:unicorn andDelegate:[[UIApplication sharedApplication] keyWindow].rootViewController];
//	[[[UIApplication sharedApplication] keyWindow].rootViewController presentModalViewController:cpvc animated:YES];
	[MGWU displayCrossPromo];
}

+ (void)displayCrossPromo
{
	NSString *u = [NSString stringWithFormat:@"%@crosspromodata", server_url];
	//Post Request With ID
	
	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
	
	[params setObject:build forKey:@"mgwubuild"];
	[params setObject:u forKey:@"url"];
	[params setObject:playerId forKey:@"mgid"];
	[params setObject:appId forKey:@"appid"];
	[params setObject:devId forKey:@"devid"];
	
	CrossPromoViewController *cpvc = [[CrossPromoViewController alloc] initWithNibName:@"CrossPromoViewController" bundle:nil andParams:params andDark:dark andUnicorn:unicorn andDelegate:[[UIApplication sharedApplication] keyWindow].rootViewController];
	[[[UIApplication sharedApplication] keyWindow].rootViewController presentModalViewController:cpvc animated:YES];
	
//	view = 0;
//	delegate = [[UIApplication sharedApplication] keyWindow].rootViewController;
//	[delegate presentModalViewController:mgwu animated:YES];
	[MGWU logEvent:@"cross_promo_clicked"];
}

+ (void)displayAboutPage
{
	view = 1;
	delegate = [[UIApplication sharedApplication] keyWindow].rootViewController;
	[delegate presentModalViewController:mgwu animated:YES];
	[MGWU logEvent:@"about_clicked"];
}

+ (void)displayAboutMessage:(NSString*)message andTitle:(NSString*)title
{
	UIAlertView *aboutAlertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[aboutAlertView show];
}

//+ (void)submitHighScore:(int)score byPlayer:(NSString*)player
//{
//	NSString *u = [NSString stringWithFormat:@"%@submiths", server_url];
//	NSMutableURLRequest *request = [NSMutableURLRequest
//									requestWithURL:[NSURL URLWithString:u]];
//
//	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
//
//	[params setObject:playerId forKey:@"mgid"];
//	[params setObject:appId forKey:@"appid"];
//	[params setObject:devId forKey:@"devid"];
//	[params setObject:player forKey:@"name"];
//	[params setObject:[NSNumber numberWithInt:score] forKey:@"score"];
//
//	NSData* dparam = [MGWU jsonDataWithObject:params];
//	NSData* dp = [MGWU symmetricEncrypt:dparam withKey:unicorn];
//
//	[request setHTTPMethod:@"POST"];
//	[request setHTTPBody:dp];
//	[NSURLConnection connectionWithRequest:request delegate:nil];
//}

+ (void)submitHighScore:(int)score byPlayer:(NSString*)player forLeaderboard:(NSString *)leaderboard
{
	NSAssert(player && leaderboard, @"[MGWU] Need Score, Player and Leaderboard");
	
	NSString *u = [NSString stringWithFormat:@"%@submiths", server_url];
	NSMutableURLRequest *request = [NSMutableURLRequest
									requestWithURL:[NSURL URLWithString:u]];
	
	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
	
	[params setObject:build forKey:@"mgwubuild"];
	
	[params setObject:playerId forKey:@"mgid"];
	[params setObject:appId forKey:@"appid"];
	[params setObject:devId forKey:@"devid"];
	[params setObject:player forKey:@"name"];
	[params setObject:leaderboard forKey:@"leaderboard"];
	[params setObject:[NSNumber numberWithInt:score] forKey:@"score"];
	
	if (username)
	{
		[params setObject:username forKey:@"username"];
		[params setObject:[me objectForKey:@"name"] forKey:@"fbname"];
		[params setObject:[me objectForKey:@"id"] forKey:@"fbid"];
		[params setObject:fbtoken forKey:@"fbtoken"];
	}
	
	NSData* dparam = [MGWU jsonDataWithObject:params];
	NSData* dp = [MGWU symmetricEncrypt:dparam withKey:unicorn];
	
	[request setHTTPMethod:@"POST"];
	[request setValue:@"application/mgwu" forHTTPHeaderField:@"content-type"];
	[request setHTTPBody:dp];
	[NSURLConnection connectionWithRequest:request delegate:nil];
	
	NSDictionary *highscore = [MGWU objectForKey:[NSString stringWithFormat:@"mgwu_highscore_%@", leaderboard]];
	if ([[highscore objectForKey:@"score"] intValue] < score)
		[MGWU setObject:@{@"score":[NSNumber numberWithInt:score], @"name":player} forKey:[NSString stringWithFormat:@"mgwu_highscore_%@", leaderboard]];
}

+ (void)submitHighScore:(int)score byPlayer:(NSString*)player forLeaderboard:(NSString *)leaderboard withCallback:(SEL)m onTarget:(id)t
{
	NSAssert(player && leaderboard && m && t, @"[MGWU] Need Score, Player, Leaderboard, Callback Method and Target");
	
	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
	
	[params setObject:playerId forKey:@"mgid"];
	[params setObject:appId forKey:@"appid"];
	[params setObject:devId forKey:@"devid"];
	[params setObject:player forKey:@"name"];
	[params setObject:leaderboard forKey:@"leaderboard"];
	[params setObject:[NSNumber numberWithInt:score] forKey:@"score"];
	
	if (username)
	{
		[params setObject:username forKey:@"username"];
		[params setObject:[me objectForKey:@"name"] forKey:@"fbname"];
		[params setObject:[me objectForKey:@"id"] forKey:@"fbid"];
		[params setObject:fbtoken forKey:@"fbtoken"];
		NSArray *friendsPlaying = [[NSUserDefaults standardUserDefaults] objectForKey: @"mgwu_friendsplaying"];
		[params setObject:friendsPlaying forKey:@"friends"];
	}
	
	[params setObject:@"submitgeths" forKey:@"endpoint"];
	
	[MGWUServerRequest requestWithParams:params withCallback:m onTarget:t];
	
	NSDictionary *highscore = [MGWU objectForKey:[NSString stringWithFormat:@"mgwu_highscore_%@", leaderboard]];
	if ([[highscore objectForKey:@"score"] intValue] < score)
		[MGWU setObject:@{@"score":[NSNumber numberWithInt:score], @"name":player} forKey:[NSString stringWithFormat:@"mgwu_highscore_%@", leaderboard]];
}

+ (NSDictionary*)getMyHighScoreForLeaderboard:(NSString*)l
{
	return [MGWU objectForKey:[NSString stringWithFormat:@"mgwu_highscore_%@", l]];
}

+ (void)getHighScoresForLeaderboard:(NSString*)l withCallback:(SEL)m onTarget:(id)t
{
	NSAssert(l && m && t, @"[MGWU] Need Leaderboard, Callback Method and Target");
	
	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
	[params setObject:l forKey:@"leaderboard"];
	
	if (username)
	{
		[params setObject:username forKey:@"username"];
		[params setObject:[me objectForKey:@"name"] forKey:@"fbname"];
		[params setObject:[me objectForKey:@"id"] forKey:@"fbid"];
		NSArray *friendsPlaying = [[NSUserDefaults standardUserDefaults] objectForKey: @"mgwu_friendsplaying"];
		[params setObject:friendsPlaying forKey:@"friends"];
	}
	
	[params setObject:@"getleaderboard" forKey:@"endpoint"];

	[MGWUServerRequest requestWithParams:params withCallback:m onTarget:t];
}

+ (void)getHighScoresForMultipleLeaderboards:(NSArray*)l withCallback:(SEL)m onTarget:(id)t
{
	NSAssert(l && m && t, @"[MGWU] Need Leaderboards, Callback Method and Target");
	
	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
	[params setObject:l forKey:@"leaderboards"];
	
	[params setObject:@"getallhs" forKey:@"endpoint"];

	[MGWUServerRequest requestWithParams:params withCallback:m onTarget:t];
}

+ (void)submitAchievements:(NSArray*)achievements
{
	NSAssert(achievements, @"[MGWU] Need Achievements");
	
	NSString *u = [NSString stringWithFormat:@"%@postach", server_url];
	NSMutableURLRequest *request = [NSMutableURLRequest
									requestWithURL:[NSURL URLWithString:u]];
	
	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
	
	[params setObject:build forKey:@"mgwubuild"];
	
	[params setObject:playerId forKey:@"mgid"];
	[params setObject:appId forKey:@"appid"];
	[params setObject:devId forKey:@"devid"];
	[params setObject:achievements forKey:@"achievements"];
	
	if (username)
	{
		[params setObject:username forKey:@"username"];
		[params setObject:[me objectForKey:@"name"] forKey:@"fbname"];
		[params setObject:[me objectForKey:@"id"] forKey:@"fbid"];
		[params setObject:fbtoken forKey:@"fbtoken"];
	}
	
	NSData* dparam = [MGWU jsonDataWithObject:params];
	NSData* dp = [MGWU symmetricEncrypt:dparam withKey:unicorn];
	
	[request setHTTPMethod:@"POST"];
	[request setValue:@"application/mgwu" forHTTPHeaderField:@"content-type"];
	[request setHTTPBody:dp];
	[NSURLConnection connectionWithRequest:request delegate:nil];
}

+ (void)getAchievementsWithCallback:(SEL)m onTarget:(id)t
{
	NSAssert(m && t, @"[MGWU] Need Callback Method and Target");
	
	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
	
	[params setObject:@"getach" forKey:@"endpoint"];
	
	[MGWUServerRequest requestWithParams:params withCallback:m onTarget:t];
}

+ (void)getAchievementsForPlayer:(NSString*)playername withCallback:(SEL)m onTarget:(id)t
{
	NSAssert(playername && m && t, @"[MGWU] Need User, Callback Method and Target");
	
	if (!username)
		return;
	
	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
	
	[params setObject:playername forKey:@"user"];
	[params setObject:[MGWU fbidFromUsername:playername] forKey:@"userfbid"];
	
	[params setObject:@"getgamerach" forKey:@"endpoint"];
	
	[MGWUServerRequest requestWithParams:params withCallback:m onTarget:t];
}

+ (NSString*)getUsername
{
	return username;
}

+ (NSString*)shortName:(NSString*)friendname
{	
	NSArray *names = [friendname componentsSeparatedByString:@" "];
	NSString * firstLetter = [[names objectAtIndex:([names count]-1)] substringToIndex:1];
	NSString *shortname;
	if ([names count] > 1)
		shortname = [[names objectAtIndex:0] stringByAppendingFormat:@" %@", firstLetter];
	else
		shortname = [names objectAtIndex:0];
	shortname = [shortname stringByAppendingString:@"."];
	return shortname;
}

+ (BOOL)isFacebookActive
{
	return !preFacebook && FBSession.activeSession.isOpen && username;
}

+ (void)toggleOpenGraph
{
	noOpenGraph = !noOpenGraph;
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:noOpenGraph] forKey:@"mgwu_noopengraph"];
	
	if (noOpenGraph)
		[MGWU logEvent:@"facebook_ogoff"];
	else
		[MGWU logEvent:@"facebook_ogon"];
}

+ (BOOL)isOpenGraphActive
{
	return !noOpenGraph;
}

+ (void)publishOpenGraphAction:(NSString*)ogaction withParams:(NSDictionary *)ogparams
{
	if ([MGWU isFacebookActive])
	{
		NSString *u = [NSString stringWithFormat:@"%@publishog", server_url];
		NSMutableURLRequest *request = [NSMutableURLRequest
										requestWithURL:[NSURL URLWithString:u]];
		NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
		
		[params setObject:build forKey:@"mgwubuild"];
		
		[params setObject:playerId forKey:@"mgid"];
		[params setObject:appId forKey:@"appid"];
		[params setObject:devId forKey:@"devid"];
		
		[params setObject:username forKey:@"username"];
		[params setObject:[me objectForKey:@"name"] forKey:@"fbname"];
		[params setObject:[me objectForKey:@"id"] forKey:@"fbid"];
		[params setObject:fbtoken forKey:@"fbtoken"];
		[params setObject:fbexp forKey:@"fbexp"];
		
		[params setObject:ogaction forKey:@"ogaction"];
		[params setObject:ogparams forKey:@"ogparams"];
		
		[params setObject:[NSNumber numberWithBool:noOpenGraph] forKey:@"noopengraph"];
		
		NSData* dparam = [MGWU jsonDataWithObject:params];
		NSData* dp = [MGWU symmetricEncrypt:dparam withKey:unicorn];
		
		[request setHTTPMethod:@"POST"];
		[request setValue:@"application/mgwu" forHTTPHeaderField:@"content-type"];
		[request setHTTPBody:dp];
		[NSURLConnection connectionWithRequest:request delegate:nil];
		
		[MGWU logEvent:@"facebook_ogpost" withParams:@{@"action":ogaction, @"opengraphactive":[NSNumber numberWithBool:!noOpenGraph]}];
	}
}

+ (NSMutableArray *)friendsToInvite
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:@"mgwu_friendstoinvite"];
}

+ (NSMutableArray *)playingFriends
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:@"mgwu_friendsplayinggame"];
}

+ (void)getPlayerWithUsername:(NSString*)playername withCallback:(SEL)m onTarget:(id)t
{
	NSAssert(playername && m && t, @"[MGWU] Need username, Callback Method and Target");
	
	if (!username)
		return;
	
	playername = [playername stringByReplacingOccurrencesOfString:@"." withString:@"_"];
	
	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];

	[params setObject:playername forKey:@"user"];
	[params setObject:username forKey:@"username"];
	
	[params setObject:@"getuser" forKey:@"endpoint"];

	[MGWUServerRequest requestWithParams:params withCallback:m onTarget:t];
}

+ (void)getRandomPlayerWithCallback:(SEL)m onTarget:(id)t
{
	NSAssert(m && t, @"[MGWU] Need Callback Method and Target");
	
	if (!username)
		return;
	
	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
	
	[params setObject:username forKey:@"username"];
	
	[params setObject:@"getrando" forKey:@"endpoint"];
	
	[MGWUServerRequest requestWithParams:params withCallback:m onTarget:t];
}

+ (void)getRandomGameWithCallback:(SEL)m onTarget:(id)t
{
	NSAssert(m && t, @"[MGWU] Need Callback Method and Target");
	
	if (!username)
		return;
	
	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
	
	[params setObject:username forKey:@"username"];
	
	[params setObject:@"getrandomgame" forKey:@"endpoint"];
	
	[MGWUServerRequest requestWithParams:params withCallback:m onTarget:t];
}

+ (void)getGame:(int)gameId withCallback:(SEL)m onTarget:(id)t
{
	NSAssert(m && t, @"[MGWU] Need Callback Method and Target");
	
	if (!username)
		return;
	
	if (!gameId)
	{
		NSLog(@"[MGWU] No GameId");
		return;
	}
	
	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
	
	[params setObject:username forKey:@"username"];
	[params setObject:[NSNumber numberWithInt:gameId] forKey:@"gameid"];
	
	[params setObject:@"getgame" forKey:@"endpoint"];
	
	[MGWUServerRequest requestWithParams:params withCallback:m onTarget:t];
}

+ (void)deleteGame:(int)gameId withCallback:(SEL)m onTarget:(id)t
{
	NSAssert(m && t, @"[MGWU] Need Callback Method and Target");
	
	if (!username)
		return;
	
	if (!gameId)
	{
		NSLog(@"[MGWU] No GameId");
		return;
	}
	
	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
	
	[params setObject:username forKey:@"username"];
	[params setObject:[NSNumber numberWithInt:gameId] forKey:@"gameid"];
	
	[params setObject:@"deletegame" forKey:@"endpoint"];

	[MGWUServerRequest requestWithParams:params withCallback:m onTarget:t];
}

+ (void)inviteFriend:(NSString*)friendname withMessage:(NSString*)message
{
	NSAssert(friendname && message, @"[MGWU] Need Friend and Message");
	
	if (![MGWU isFacebookActive])
		return;
	
	NSString *fbid = [[[NSUserDefaults standardUserDefaults] objectForKey:@"mgwu_usernametoid"] objectForKey:friendname];
	NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   message, @"message", nil];
   // [params setObject: @"1" forKey:@"frictionless"];
	[params setObject:fbid forKey:@"to"];
    [facebook dialog:@"apprequests"
				andParams:params
			  andDelegate:mgwu];
	
	[MGWU logEvent:@"facebook_inviting"];
}

+ (BOOL)canInviteFriends
{
#ifndef APPORTABLE
	if ([MGWU isFacebookActive] || [MFMessageComposeViewController canSendText] || [MFMailComposeViewController canSendMail])
		return TRUE;
	else
		return FALSE;
#else
	if ([MGWU isFacebookActive])//Later add mail functionality
		return TRUE;
	else
		return FALSE;
#endif
}

+ (void)callCallback
{
	if (target && method)
	{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		[target performSelector:method withObject:serverData];
#pragma clang diagnostic pop
		target = nil;
		method = nil;
	}
	
	serverData = nil;
}

+ (void)inviteFriendsWithMessage:(NSString *)message withCallback:(SEL)m onTarget:(id)t
{
	NSAssert(message && m && t, @"[MGWU] Need Message, Callback Method and Target");
	
	method = m;
	target = t;
	
	if (![MGWU canInviteFriends])
	{
		serverData = nil;
		[MGWU callCallback];
	}
	else
	{
		[MGWU inviteFriendsWithMessage:message];
	}
}

+ (void)inviteFriendsWithMessage:(NSString*)message
{
#ifndef APPORTABLE
	NSAssert(message, @"[MGWU] Need Message");
	
	if ([MGWU isFacebookActive])
	{
		NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									   message, @"message", nil];
		[facebook dialog:@"apprequests"
			   andParams:params
			 andDelegate:mgwu];
		
		[MGWU logEvent:@"facebook_inviting"];
	}
	else if([MFMessageComposeViewController canSendText])
	{
		MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
		NSString *appstoreurl = [NSString stringWithFormat:@"%@%@/?s=sms", [link_url stringByReplacingOccurrencesOfString:@"https://www." withString:@""], shortcode];
		controller.body = [message stringByAppendingFormat:@" - %@", appstoreurl];
		controller.messageComposeDelegate = mgwu;
		controller.wantsFullScreenLayout = NO;
		delegate = [[UIApplication sharedApplication] keyWindow].rootViewController;
		[delegate presentModalViewController:controller animated:YES];
		[[UIApplication sharedApplication] setStatusBarHidden:YES];
		
		[MGWU logEvent:@"sms_sending"];
	}
	else if ([MFMailComposeViewController canSendMail])
	{
		MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
		NSString *appstoreurl = [NSString stringWithFormat:@"%@%@/?s=email", link_url, shortcode];
		[controller setMessageBody:[message stringByAppendingFormat:@" - %@", appstoreurl] isHTML:NO];
		controller.mailComposeDelegate = mgwu;
		controller.wantsFullScreenLayout = NO;
		delegate = [[UIApplication sharedApplication] keyWindow].rootViewController;
		[delegate presentModalViewController:controller animated:YES];
		[[UIApplication sharedApplication] setStatusBarHidden:YES];
		
		[MGWU logEvent:@"email_sending"];
	}
#else
	if ([MGWU isFacebookActive])
	{
		NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								   message, @"message", nil];
		[facebook dialog:@"apprequests"
		   andParams:params
		 andDelegate:mgwu];
	
		[MGWU logEvent:@"facebook_inviting"];
	}
#endif
}

#ifndef APPORTABLE
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
	if (result == MessageComposeResultSent)
	{
		[MGWU logEvent:@"sms_sent"];
		serverData = @"Success";
	}
	else
		serverData = nil;
	[MGWU callCallback];
	
	[delegate dismissModalViewControllerAnimated:YES];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
	if (result == MFMailComposeResultSent)
	{
		[MGWU logEvent:@"email_sent"];
		serverData = @"Success";
	}
	else
		serverData = nil;
	[MGWU callCallback];
	
	[delegate dismissModalViewControllerAnimated:YES];
}
#endif

+ (BOOL)isFriend:(NSString*)friendname
{
	if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"mgwu_usernametoid"] objectForKey:friendname])
		return TRUE;
	else
		return FALSE;
}

+ (NSString*)fbidFromUsername:(NSString*)friendname
{
	return [[[NSUserDefaults standardUserDefaults] objectForKey:@"mgwu_usernametoid"] objectForKey:friendname];
}

+ (void)postToFriendsWall:(NSString*)friendname withTitle:(NSString*)title caption:(NSString*)caption andDescription:(NSString*)description
{
	NSAssert(friendname && title && caption && description, @"[MGWU] Need Friend, Title, Caption and Description");
	
	NSString *fbid = [MGWU fbidFromUsername:friendname];
	if (!fbid)
	{
		NSLog(@"[MGWU] User is not your friend");
		return;
	}
	
	NSString *appstoreurl = [NSString stringWithFormat:@"%@%@/?s=fb_wp", [link_url stringByReplacingOccurrencesOfString:@"https://" withString:@""], shortcode];
	NSString *iconurl = [NSString stringWithFormat:@"https://s3.amazonaws.com/mgwu-app-icons/%@@2x.png", appId];
	NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								   appstoreurl, @"link",
								   iconurl, @"picture",
								   fbid, @"to",
								   title, @"name",
								   caption, @"caption",
								   description, @"description",
								   nil];
	
	[facebook dialog:@"feed" andParams:params andDelegate:mgwu];
	[MGWU logEvent:@"facebook_posting"];
}

+ (void)shareWithTitle:(NSString*)title caption:(NSString*)caption andDescription:(NSString*)description
{
	NSAssert(title && caption && description, @"[MGWU] Need Title, Caption and Description");
	
	NSString *appstoreurl = [NSString stringWithFormat:@"%@%@/?s=fb_sh", [link_url stringByReplacingOccurrencesOfString:@"https://" withString:@""], shortcode];
	NSString *iconurl = [NSString stringWithFormat:@"https://s3.amazonaws.com/mgwu-app-icons/%@@2x.png", appId];
	NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								   appstoreurl, @"link",
								   iconurl, @"picture",
								   title, @"name",
								   caption, @"caption",
								   description, @"description",
								   nil];
	
	[facebook dialog:@"feed" andParams:params andDelegate:mgwu];
	[MGWU logEvent:@"facebook_posting"];
}

- (void)dialogCompleteWithUrl:(NSURL *)url
{
	NSString *q = [url query];
	if (!q)
		serverData = nil;
	else
	{
		NSString *type = [[q componentsSeparatedByString:@"="] objectAtIndex:0];
		if ([type isEqualToString:@"post_id"])
		{
			[MGWU logEvent:@"facebook_posted"];
			serverData = @"Success";
		}
		else if ([type isEqualToString:@"request"])
		{
			[MGWU logEvent:@"facebook_invited"];
			serverData = @"Success";
		}
		else
			serverData = nil;
	}
	[MGWU callCallback];
}

+ (void)likeAppWithPageId:(NSString*)pageid
{
	NSAssert(pageid, @"[MGWU] Need PageID");
	
	BOOL fb = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"fb://profile/%@", pageid]]];
	if (!fb)
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.facebook.com/%@", pageid]]];
}

+ (void)likeMGWU
{
	BOOL fb = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"fb://profile/130007087140416"]];
	if (!fb)
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.facebook.com/130007087140416"]];
}

#ifndef APPORTABLE
+ (BOOL)isTwitterActive
{
	if ([SLComposeViewController class] != nil)
		return [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter];
	
	if ([TWTweetComposeViewController class] != nil)
		return [TWTweetComposeViewController canSendTweet];
	
	return false;
	
}

+ (void)postToTwitter:(NSString*)message
{
	if ([SLComposeViewController class] != nil)
	{
		if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
			return;
		
		SLComposeViewController *slc = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
		if (message)
			[slc setInitialText:message];
		UIImage *image = [UIImage imageNamed:@"MGWUIcon.png"];
		if (image)
			[slc addImage:image];
		NSString *appstoreurl = [NSString stringWithFormat:@"%@%@/?s=twt", link_url, shortcode];
		[slc addURL:[NSURL URLWithString:appstoreurl]];
		
		slc.completionHandler = ^(SLComposeViewControllerResult result) {
            if (result == SLComposeViewControllerResultDone)
				[MGWU logEvent:@"twitter_posted"];
			[[UIApplication sharedApplication].keyWindow.rootViewController dismissModalViewControllerAnimated:YES];
		};
		
		[[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:slc animated:YES];

		[MGWU logEvent:@"twitter_posting"];
	}
	else if ([TWTweetComposeViewController class] != nil)
	{
		if (![TWTweetComposeViewController canSendTweet])
			return;
		
		TWTweetComposeViewController *twt = [[TWTweetComposeViewController alloc] init];
		
		if (message)
			[twt setInitialText:message];
		UIImage *image = [UIImage imageNamed:@"MGWUIcon.png"];
		if (image)
			[twt addImage:image];
		NSString *appstoreurl = [NSString stringWithFormat:@"%@%@/?s=twt", link_url, shortcode];
		[twt addURL:[NSURL URLWithString:appstoreurl]];
		
		twt.completionHandler = ^(TWTweetComposeViewControllerResult result) {
			if (result == TWTweetComposeViewControllerResultDone)
				[MGWU logEvent:@"twitter_posted"];
			[[UIApplication sharedApplication].keyWindow.rootViewController dismissModalViewControllerAnimated:YES];
		};
		
		[[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:twt animated:YES];
		
		[MGWU logEvent:@"twitter_posting"];
	}
	else
		return;
}

+ (void)postToTwitter:(NSString*)message withImage:(UIImage*)image
{
	if (!image)
		image = [UIImage imageNamed:@"MGWUIcon.png"];
	
	if ([SLComposeViewController class] != nil)
	{
		if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
			return;
		
		SLComposeViewController *slc = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
		if (message)
			[slc setInitialText:message];
		if (image)
			[slc addImage:image];
		NSString *appstoreurl = [NSString stringWithFormat:@"%@%@/?s=twt", link_url, shortcode];
		[slc addURL:[NSURL URLWithString:appstoreurl]];
		
		slc.completionHandler = ^(SLComposeViewControllerResult result) {
            if (result == SLComposeViewControllerResultDone)
				[MGWU logEvent:@"twitter_posted"];
			[[UIApplication sharedApplication].keyWindow.rootViewController dismissModalViewControllerAnimated:YES];
		};
		
		[[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:slc animated:YES];
		
		[MGWU logEvent:@"twitter_posting"];
	}
	else if ([TWTweetComposeViewController class] != nil)
	{
		if (![TWTweetComposeViewController canSendTweet])
			return;
		
		TWTweetComposeViewController *twt = [[TWTweetComposeViewController alloc] init];
		
		if (message)
			[twt setInitialText:message];
		if (image)
			[twt addImage:image];
		NSString *appstoreurl = [NSString stringWithFormat:@"%@%@/?s=twt", link_url, shortcode];
		[twt addURL:[NSURL URLWithString:appstoreurl]];
		
		twt.completionHandler = ^(TWTweetComposeViewControllerResult result) {
			if (result == TWTweetComposeViewControllerResultDone)
				[MGWU logEvent:@"twitter_posted"];
			[[UIApplication sharedApplication].keyWindow.rootViewController dismissModalViewControllerAnimated:YES];
		};
		
		[[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:twt animated:YES];
		
		[MGWU logEvent:@"twitter_posting"];
	}
	else
		return;
}

+ (BOOL)isFacebookNativeActive
{
	if ([SLComposeViewController class] != nil)
		return [SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook];
	
	return false;
	
}

+ (void)postToFacebook:(NSString*)message withImage:(UIImage*)image
{
	if (!image)
		image = [UIImage imageNamed:@"MGWUIcon.png"];
	
	if ([SLComposeViewController class] != nil)
	{
		if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
			return;
		
		SLComposeViewController *slc = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
		if (message)
			[slc setInitialText:message];
		if (image)
			[slc addImage:image];
		NSString *appstoreurl = [NSString stringWithFormat:@"%@%@/?s=fb", [link_url stringByReplacingOccurrencesOfString:@"https://" withString:@""], shortcode];
		[slc addURL:[NSURL URLWithString:appstoreurl]];
		
		slc.completionHandler = ^(SLComposeViewControllerResult result) {
            if (result == SLComposeViewControllerResultDone)
				[MGWU logEvent:@"facebook_native_posted"];
			[[UIApplication sharedApplication].keyWindow.rootViewController dismissModalViewControllerAnimated:YES];
		};
		
		[[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:slc animated:YES];
		
		[MGWU logEvent:@"facebook_native_posting"];
	}
}
#endif

+ (void)getMyInfoWithCallback:(SEL)m onTarget:(id)t
{
	NSAssert(m && t, @"[MGWU] Need Callback Method and Target");
	
	if (!username)
		return;
	
	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
	
	[params setObject:username forKey:@"username"];
	[params setObject:[me objectForKey:@"id"] forKey:@"fbid"];
	[params setObject:[me objectForKey:@"name"] forKey:@"name"];
	if ([[me allKeys] containsObject:@"email"])
		[params setObject:[me objectForKey:@"email"] forKey:@"email"];
	
	NSArray *friendsPlaying = [[NSUserDefaults standardUserDefaults] objectForKey: @"mgwu_friendsplaying"];
	[params setObject:friendsPlaying forKey:@"friends"];
	
	[params setObject:@"getmyinfo" forKey:@"endpoint"];
	
	[MGWUServerRequest requestWithParams:params withCallback:m onTarget:t];
	
}

//+ (void)addCoins:(int)coins withCallback:(SEL)m onTarget:(id)t
//{
//	NSAssert(m && t, @"[MGWU] Need Callback Method and Target");
//	
//	if (!username)
//		return;
//	
//	method = m;
//	target = t;
//	
//	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
//	
//	NSString *u = [NSString stringWithFormat:@"%@incrementcoins", server_url];
//	[params setObject:u forKey:@"url"];
//	[params setObject:username forKey:@"username"];
//	[params setObject:[NSNumber numberWithInt:coins] forKey:@"coins"];
//	
//	[MGWUServerRequest requestWithParams:params withCallback:m onTarget:t];
//	
//}

+ (void)getMessagesWithFriend:(NSString*)friendId andCallback:(SEL)m onTarget:(id)t
{
	NSAssert(friendId && m && t, @"[MGWU] Need Friend, Callback Method and Target");
	
	if (!username)
		return;
	
	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
	
	[params setObject:username forKey:@"username"];
	[params setObject:friendId forKey:@"friendid"];
	
	[params setObject:@"getmessages" forKey:@"endpoint"];
	
	[MGWUServerRequest requestWithParams:params withCallback:m onTarget:t];
	
}

+ (void)sendMessage:(NSString*)message toFriend:(NSString*)friendId andCallback:(SEL)m onTarget:(id)t
{
	NSAssert(message && friendId && m && t, @"[MGWU] Need Message, Friend, Callback Method and Target");
	
	if (!username)
		return;
	
	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
	
	[params setObject:username forKey:@"username"];
	[params setObject:friendId forKey:@"friendid"];
	[params setObject:message forKey:@"message"];
	if ([MGWU isFriend:friendId])
		[params setObject:[MGWU shortName:[me objectForKey:@"name"]] forKey:@"playername"];
	
	[params setObject:@"sendmessage" forKey:@"endpoint"];

	[MGWUServerRequest requestWithParams:params withCallback:m onTarget:t];
	
}

+ (void)move:(NSDictionary*)move withMoveNumber:(int)moveNumber forGame:(int)gameId withGameState:(NSString*)gameState withGameData:(NSDictionary*)gameData againstPlayer:(NSString*)friendId withPushNotificationMessage:(NSString*)message withCallback:(SEL)m onTarget:(id)t
{
	NSAssert(move && gameState && gameData && friendId && message && m && t, @"[MGWU] Need Move, Move Number, GameID, GameState, GameData, Player, Message, Callback Method and Target.");
	
	if (!username)
		return;
	
	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
	
	if ([move objectForKey:@"mgwu_file_path"])
	{
		NSString *fileKey;
		NSMutableDictionary *mmove = [NSMutableDictionary dictionaryWithDictionary:move];

		if ([gameState isEqualToString:@"started"] || [gameState isEqualToString:@"onemove"])
		{
			long long time = [[NSDate date] timeIntervalSince1970];
			fileKey = [appId stringByAppendingFormat:@"-%@-%qi", username, time];
			[mmove setObject:fileKey forKey:@"mgwu_file_key"];
		}
		else
		{
			fileKey = [appId stringByAppendingFormat:@"-g%d-m%d", gameId, moveNumber];
		}
		
		[params setObject:@{@"filepath":[move objectForKey:@"mgwu_file_path"], @"filekey":fileKey} forKey:@"mgwu_move_file_info"];
		[mmove removeObjectForKey:@"mgwu_file_path"];
		move = mmove;
	}
	
	[params setObject:move forKey:@"move"];
	[params setObject:[NSNumber numberWithInt:moveNumber] forKey:@"movecount"];
	[params setObject:[NSNumber numberWithInt:gameId] forKey:@"gameid"];
	[params setObject:gameState forKey:@"gamestate"];
	[params setObject:gameData forKey:@"gamedata"];
	[params setObject:friendId forKey:@"friendid"];
	[params setObject:username forKey:@"username"];
	[params setObject:message forKey:@"message"];
	
	[params setObject:@"move" forKey:@"endpoint"];

	[MGWUServerRequest requestWithParams:params withCallback:m onTarget:t];
}

+ (void)getFileWithExtension:(NSString*)ext forGame:(int)gameId andMove:(int)moveNumber withCallback:(SEL)m onTarget:(id)t
{
	NSAssert(gameId && moveNumber && m && t, @"[MGWU] Need GameID, Move Number, Callback Method and Target.");
	
	NSString *fileKey = [appId stringByAppendingFormat:@"-g%d-m%d", gameId, moveNumber];
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *filePath = [[[paths objectAtIndex:0] stringByAppendingPathComponent:fileKey] stringByAppendingPathExtension:ext];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
	{
		serverData = filePath;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		[target performSelector:method withObject:serverData];
#pragma clang diagnostic pop
	}
	else
	{
		NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
		[params setObject:@{@"filepath":filePath, @"filekey":fileKey} forKey:@"download_file_info"];
		[MGWUServerRequest requestWithParams:params withCallback:m onTarget:t];
	}
		
}

-(BOOL) uploadFile:(NSString*)filePath toS3ForKey:(NSString*)fileKey
{
	@try {
		S3PutObjectRequest *por = [[S3PutObjectRequest alloc] initWithKey:fileKey inBucket:bucket_name];
		por.data = [NSData dataWithContentsOfFile:filePath];
		[s3 putObject:por];
		
		//Save locally / delete original
		NSString *ext = [filePath pathExtension];
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *fPath = [[[paths objectAtIndex:0] stringByAppendingPathComponent:fileKey] stringByAppendingPathExtension:ext];
		[por.data writeToFile:fPath atomically:YES];
		[[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
		
	}
	@catch (AmazonClientException *exception)
	{
		NSLog(@"Exception = %@", exception);
		return NO;
	}
	return YES;
}

-(BOOL) downloadFileForKey:(NSString*)fileKey toPath:(NSString*)filePath
{
	@try {		
		S3GetObjectRequest *gor = [[S3GetObjectRequest alloc] initWithKey:fileKey withBucket:bucket_name];
		S3GetObjectResponse *response = [s3 getObject:gor];
		[response.body writeToFile:filePath atomically:YES];
	}
	@catch (AmazonClientException *exception)
	{
		NSLog(@"Exception = %@", exception);
		return NO;
	}
	return YES;
}

//-(void)upload:(NSData*)dataToUpload inBucket:(NSString*)bucket forKey:(NSString*)key
//{
//	S3PutObjectRequest *por = [[S3PutObjectRequest alloc] initWithKey:key inBucket:bucket];
//	por.data = dataToUpload;
//	[s3 putObject:por];
//}
//
//-(NSData*)downloadFromBucket:(NSString*)bucket forKey:(NSString*)key
//{
//	NSOutputStream *stream = [[NSOutputStream alloc] initToFileAtPath:key append:NO];
//	[stream open];
//	
//	S3GetObjectRequest *gor = [[S3GetObjectRequest alloc] initWithKey:key withBucket:bucket];
//	gor.outputStream = stream;
//	[stream close];
//}

+ (void)showError
{
	HUD = [[MGWUMBProgressHUD alloc] initWithView:[[UIApplication sharedApplication] keyWindow]];
	[[[UIApplication sharedApplication] keyWindow] addSubview:HUD];
	[HUD setRemoveFromSuperViewOnHide:YES];
	
	// Set view mode
	HUD.mode = MGWUMBProgressHUDModeText;
	
	//HUD.delegate = self;
	HUD.labelText = @"Error With Connection";
	[HUD show:YES];
	[HUD hide:YES afterDelay:2];
}

+ (void)showMessage:(NSString*)message withImage:(NSString *)imageName
{
	if (!imageName)
		imageName = @"MGWUIcon.png";
	
	UIImage *i = [UIImage imageNamed:imageName];
	
	[[MGWUNotificationHandler defaultHandler] notifyAchievementTitle:@"" message:message andImage:i];
	//TODO make this use notifications
//	HUD = [[MGWUMBProgressHUD alloc] initWithView:[[UIApplication sharedApplication] keyWindow]];
//	[[[UIApplication sharedApplication] keyWindow] addSubview:HUD];
//	[HUD setRemoveFromSuperViewOnHide:YES];
//	
//	// Set view mode
//	HUD.mode = MGWUMBProgressHUDModeText;
//	
//	//HUD.delegate = self;
//	HUD.labelText = message;
//	[HUD show:YES];
//	[HUD hide:YES afterDelay:2];
}

- (void)showHUDWithParams:(NSMutableDictionary*)params {
    
	NSString *u = [params objectForKey:@"url"];
	[params removeObjectForKey:@"url"];
	NSString *e = [u lastPathComponent];
	[params setObject:e forKey:@"endpoint"];
	[MGWUServerRequest requestWithParams:params withCallback:method onTarget:target];
	
//    HUD = [[MGWUMBProgressHUD alloc] initWithView:[[UIApplication sharedApplication] keyWindow]];
//    [[[UIApplication sharedApplication] keyWindow] addSubview:HUD];
//	[HUD setRemoveFromSuperViewOnHide:YES];
//	
//    [HUD setDelegate:self];
//    HUD.labelText = @"Loading...";
//	
//	[HUD showWhileExecuting:@selector(myTask:) onTarget:self withObject:params animated:YES];
}

- (void)hudWasHidden:(MGWUMBProgressHUD *)hud
{
	if (serverError)
		[MGWU showMessage:serverError withImage:nil];
	else if (!serverData)
		[MGWU showError];
	
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	[target performSelector:method withObject:serverData];
#pragma clang diagnostic pop
	
	serverData = nil;
	
	HUD = nil;
	target = nil;
	method = nil;
}

#pragma mark -
#pragma mark Execution code

- (void)myTask:(NSMutableDictionary*)params {
	
	if ([params objectForKey:@"download_file_info"])
	{
		NSDictionary *downloadFileInfo = [params objectForKey:@"download_file_info"];
		if([self downloadFileForKey:[downloadFileInfo objectForKey:@"filekey"] toPath:[downloadFileInfo objectForKey:@"filepath"]])
			serverData = [downloadFileInfo objectForKey:@"filepath"];
		else
			serverData = nil;
		return;
	}
	else if ([params objectForKey:@"mgwu_move_file_info"])
	{
		NSDictionary *moveFileInfo = [params objectForKey:@"mgwu_move_file_info"];
		if ([self uploadFile:[moveFileInfo objectForKey:@"filepath"] toS3ForKey:[moveFileInfo objectForKey:@"filekey"]])
			[params removeObjectForKey:@"mgwu_move_file_info"];
		else
		{
			serverData = nil;
			return;
		}
	}
	
	NSString *u = [params objectForKey:@"url"];
	[params removeObjectForKey:@"url"];
	
	NSMutableURLRequest *request = [NSMutableURLRequest
									requestWithURL:[NSURL URLWithString:u]];
		
	[params setObject:build forKey:@"mgwubuild"];
	
	[params setObject:playerId forKey:@"mgid"];
	[params setObject:appId forKey:@"appid"];
	[params setObject:appVersion forKey:@"appver"];
	[params setObject:devId forKey:@"devid"];
	
	NSData* dparam = [MGWU jsonDataWithObject:params];
	NSData* dp = [MGWU symmetricEncrypt:dparam withKey:unicorn];
	
	[request setHTTPMethod:@"POST"];
	[request setValue:@"application/mgwu" forHTTPHeaderField:@"content-type"];
	[request setHTTPBody:dp];
	
	NSURLResponse *urlResponse = nil;
	NSError *urlError = nil;
	serverError = nil;
	
	NSData *urlData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&urlError];
	
	if (urlError) {
        //There is an Error with the connections
        serverData = nil;
		NSString *error = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];
		if (!error)
			error = [urlError description];
		NSLog(@"[MGWU] The server request failed, the response was: %@", error);
    }
    else if (!urlData || !urlResponse || ![[urlResponse MIMEType] isEqualToString:@"application/mgwu"]){
		serverData = nil;
    }
    else {
		NSData* dData = [MGWU symmetricDecrypt:urlData withKey:unicorn];
		if (!dData)
		{
			serverData = nil;
		}
		else
		{
			NSDictionary* o = (NSDictionary*)[MGWU jsonObjectWithData:dData];
			
			if (!o ||
				![[o allKeys] containsObject:@"response"])
			{
				serverData = nil;
			}
			else if ([[o allKeys] containsObject:@"error"])
			{
				serverData = nil;
				serverError = [o objectForKey:@"error"];
			}
			else
			{
				serverData = [o objectForKey:@"response"];
			}
		}
		
	}
}

//- (void)myInfoTask {
//	NSString *u = [NSString stringWithFormat:@"%@getmyinfo", server_url];
//
//	NSMutableURLRequest *request = [NSMutableURLRequest
//									requestWithURL:[NSURL URLWithString:u]];
//
//	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
//
//	[params setObject:playerId forKey:@"mgid"];
//	[params setObject:appId forKey:@"appid"];
//	[params setObject:devId forKey:@"devid"];
//	if (leaderboards)
//		[params setObject:leaderboards forKey:@"leaderboards"];
//	else
//		[params setObject:leaderboard forKey:@"leaderboard"];
//
//	NSData* dparam = [MGWU jsonDataWithObject:params];
//	NSData* dp = [MGWU symmetricEncrypt:dparam withKey:unicorn];
//
//	[request setHTTPMethod:@"POST"];
//	[request setValue:@"application/mgwu" forHTTPHeaderField:@"content-type"];
//	[request setHTTPBody:dp];
//
//	NSURLResponse *urlResponse = nil;
//	NSError *urlError = nil;
//
//	NSData *urlData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&urlError];
//
//	if (urlError) {
//        //There is an Error with the connections
//        serverData = nil;
//		NSString *error = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];
//		NSLog(@"The server request failed, the response was: %@", error);
//    }
//    else if (!urlData || !urlResponse || [[urlResponse MIMEType] isEqualToString:@"text/html"]){
//		serverData = nil;
//    }
//    else {
//		NSData* dData = [MGWU symmetricDecrypt:urlData withKey:unicorn];
//		if (!dData)
//		{
//			serverData = nil;
//		}
//		else
//		{
//			NSDictionary* o = (NSDictionary*)[MGWU jsonObjectWithData:dData];
//
//			if (!o || [[o allKeys] containsObject:@"error"] ||
//				![[o allKeys] containsObject:@"response"])
//			{
//				serverData = nil;
//			}
//			else
//			{
//				serverData = [o objectForKey:@"response"];
//			}
//		}
//
//	}
//}
//
//- (void)myMoveTask {
//	NSString *u = [NSString stringWithFormat:@"%@move", server_url];
//
//	NSMutableURLRequest *request = [NSMutableURLRequest
//									requestWithURL:[NSURL URLWithString:u]];
//
//	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
//
//	[params setObject:playerId forKey:@"mgid"];
//	[params setObject:appId forKey:@"appid"];
//	[params setObject:devId forKey:@"devid"];
//	if (leaderboards)
//		[params setObject:leaderboards forKey:@"leaderboards"];
//	else
//		[params setObject:leaderboard forKey:@"leaderboard"];
//
//	NSData* dparam = [MGWU jsonDataWithObject:params];
//	NSData* dp = [MGWU symmetricEncrypt:dparam withKey:unicorn];
//
//	[request setHTTPMethod:@"POST"];
//  [request setValue:@"application/mgwu" forHTTPHeaderField:@"content-type"];
//	[request setHTTPBody:dp];
//
//	NSURLResponse *urlResponse = nil;
//	NSError *urlError = nil;
//
//	NSData *urlData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&urlError];
//
//	if (urlError) {
//        //There is an Error with the connections
//        serverData = nil;
//		NSString *error = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];
//		NSLog(@"The server request failed, the response was: %@", error);
//    }
//    else if (!urlData || !urlResponse || [[urlResponse MIMEType] isEqualToString:@"text/html"]){
//		serverData = nil;
//    }
//    else {
//		NSData* dData = [MGWU symmetricDecrypt:urlData withKey:unicorn];
//		if (!dData)
//		{
//			serverData = nil;
//		}
//		else
//		{
//			NSDictionary* o = (NSDictionary*)[MGWU jsonObjectWithData:dData];
//
//			if (!o || [[o allKeys] containsObject:@"error"] ||
//				![[o allKeys] containsObject:@"response"])
//			{
//				serverData = nil;
//			}
//			else
//			{
//				serverData = [o objectForKey:@"response"];
//			}
//		}
//
//	}
//}

+(void) setObject:(id)object forKey:(NSString*)keyword
{
	NSAssert(object && keyword, @"[MGWU] Need Object and Keyword");
	
	NSData *d = [NSKeyedArchiver archivedDataWithRootObject:object];
	NSData *k = [@"nsus3rd3f4ults0k" dataUsingEncoding:NSUTF8StringEncoding];
	NSData *crypt = [MGWU symmetricEncrypt:d withKey:k];
	[[NSUserDefaults standardUserDefaults] setObject:crypt forKey:[NSString stringWithFormat:@"mgwuencrypt_%@", keyword]];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

+(id) objectForKey:(NSString*)keyword
{
	NSAssert(keyword, @"[MGWU] Need Keyword");
	
	NSData *crypt = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"mgwuencrypt_%@", keyword]];
	if (!crypt)
		return nil;
	NSData *k = [@"nsus3rd3f4ults0k" dataUsingEncoding:NSUTF8StringEncoding];
	NSData *d = [MGWU symmetricDecrypt:crypt withKey:k];
	return [NSKeyedUnarchiver unarchiveObjectWithData:d];
}

+(void)removeObjectForKey:(NSString*)keyword
{
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"mgwuencrypt_%@", keyword]];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

+(NSData *) symmetricEncrypt: (NSData *) d withKey: (NSData *) k
{
	size_t l;
	void *e = malloc([d length] + kCCBlockSizeAES128);
	if(CCCrypt(kCCEncrypt,
			   kCCAlgorithmAES128,
			   kCCOptionPKCS7Padding,
			   [k bytes],
			   kCCKeySizeAES128,
			   NULL,
			   [d bytes],
			   [d length],
			   e,
			   [d length] + kCCBlockSizeAES128,
			   &l)
	   != kCCSuccess)
	{
		free(e);
		return nil;		// TODO error handling
	}
	
	NSData *o = [NSData dataWithBytes: e length: l];
	free(e);
	
	return o;
}

+ (NSData *) symmetricDecrypt: (NSData *) d withKey: (NSData *) k
{
	size_t l;
	void *e = malloc([d length] + kCCBlockSizeAES128);
	
	if(CCCrypt(kCCDecrypt,
			   kCCAlgorithmAES128,
			   kCCOptionPKCS7Padding,
			   [k bytes],
			   kCCKeySizeAES128,
			   NULL,
			   [d bytes],
			   [d length],
			   e,
			   [d length] + kCCBlockSizeAES128,
			   &l)
	   != kCCSuccess)
	{
		free(e);
		return nil;		// TODO error handling
	}
	
	NSData *o = [NSData dataWithBytes: e length: l];
	free(e);
	
	return o;
}

+ (BOOL) connectedToNetwork
{
	NSURL *url = [NSURL URLWithString:@"http://www.google.com"];
	NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
	if ([NSURLConnection sendSynchronousRequest:urlRequest returningResponse:nil error:nil])
		return TRUE;
	return FALSE;
}

+(NSObject*)jsonObjectWithData:(NSData *)d
{
	MGWUJsonParser *parser = [[MGWUJsonParser alloc] init];
    NSObject *o = [parser objectWithData:d];
    if (!o)
        NSLog(@"-JSONValue failed. Error is: %@", parser.error);
    return o;
}

+(NSData*)jsonDataWithObject:(NSObject*)o
{
	MGWUJsonWriter *writer = [[MGWUJsonWriter alloc] init];
    NSData *d = [writer dataWithObject:o];
	NSAssert(d, @"[MGWU] Do not put objects that are not NSStrings, NSNumbers, NSDictionaries or NSArrays into NSDictionaries that you pass to the MGWU toolkit");
    return d;
}

#ifndef APPORTABLE
+(NSString *) deviceModel{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}
#endif

static const char* jailbreak_apps[] =
{
	"/bin/bash",
	"/Applications/Cydia.app",
	"/Applications/limera1n.app",
	"/Applications/greenpois0n.app",
	"/Applications/blackra1n.app",
	"/Applications/blacksn0w.app",
	"/Applications/redsn0w.app",
	NULL,
};

+ (NSString*)isJailBroken
{
#ifdef APPORTABLE
	return @"no";
#endif
	
#if TARGET_IPHONE_SIMULATOR
	return @"no";
#endif
	
	// Check for known jailbreak apps. If we encounter one, the device is jailbroken.
	for (int i = 0; jailbreak_apps[i] != NULL; ++i)
	{
		if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithUTF8String:jailbreak_apps[i]]])
		{
			return @"yes";
		}
	}
	
	return @"no";
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)loadView
{
	[super loadView];
	
	wview = [[UIWebView alloc] init];
	wview.delegate = self;
	if (dark)
	{
		wview.opaque = NO;
		self.view.backgroundColor = [UIColor blackColor];
	}
	
	aboutview = [[UIView alloc] init];
	
	UIImageView *iView;
	UIImageView *imageView;
	UIButton *footer = [UIButton buttonWithType:UIButtonTypeCustom];;
	
	CGRect frame = [[[[[UIApplication sharedApplication] keyWindow] rootViewController] view] bounds];
	if (UIDeviceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]))
	{
		if (dark)
			iView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MGWUBackgroundDark-Portrait.png"]];
		else
			iView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MGWUBackground-Portrait.png"]];
		
		imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MGWUAbout.png"]];
		[footer setBackgroundImage:[UIImage imageNamed:@"MGWUAboutFooter-Portrait.png"] forState:UIControlStateNormal];
	}
	else
	{
		if (dark)
			iView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MGWUBackgroundDark-Landscape.png"]];
		else
			iView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MGWUBackground-Landscape.png"]];
		
		if (frame.size.width == 568.0)
		{
			imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MGWUAbout-568h.png"]];
			[footer setBackgroundImage:[UIImage imageNamed:@"MGWUAboutFooter-Landscape-568h.png"] forState:UIControlStateNormal];
		}
		else
		{
			imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MGWUAbout.png"]];
			[footer setBackgroundImage:[UIImage imageNamed:@"MGWUAboutFooter-Landscape.png"] forState:UIControlStateNormal];
		}
	}
	
	CGFloat footerHeight = [footer backgroundImageForState:UIControlStateNormal].size.height;
		
	UIScrollView *sView = [[UIScrollView alloc] init];
	imageView.contentMode = UIViewContentModeCenter;
	imageView.frame = CGRectMake(0, 0, frame.size.width, imageView.frame.size.height);
	[sView addSubview:imageView];
	sView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height-footerHeight);
	sView.contentSize = imageView.frame.size;
	
	[aboutview addSubview:iView];
	[aboutview addSubview:sView];
	[aboutview addSubview:footer];
	
	[footer addTarget:self action:@selector(openMGWU) forControlEvents:UIControlEventTouchUpInside];
	footer.frame = CGRectMake(0, frame.size.height-footerHeight, frame.size.width, footerHeight);
	wview.frame = frame;
	sView.frame = frame;
	iView.frame = frame;
	aboutview.frame = frame;
	
	UIImage* closeImage = [UIImage imageNamed:@"MGWUClose.png"];
	
	UIColor* color = [UIColor colorWithRed:167.0/255 green:184.0/255 blue:216.0/255 alpha:1];
	closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[closeButton setImage:closeImage forState:UIControlStateNormal];
	[closeButton setTitleColor:color forState:UIControlStateNormal];
	[closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
	[closeButton addTarget:self action:@selector(close)
		  forControlEvents:UIControlEventTouchUpInside];
	closeButton.titleLabel.font = [UIFont boldSystemFontOfSize:12];
	
	closeButton.showsTouchWhenHighlighted = YES;
	closeButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin
	| UIViewAutoresizingFlexibleBottomMargin;
	
	closeButton.frame = CGRectMake(5, 5, 25, 25);
}

-(void)openMGWU
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.makegameswith.us/"]];
}

-(void)viewWillAppear:(BOOL)animated
{
	
	if (view == CROSSPROMO)
		[self.view addSubview:wview];
	else
		[self.view addSubview:aboutview];
	
	[self.view addSubview:closeButton];
	
	if (view == CROSSPROMO)
	{
		if (initialWebViewLoad && [wview isLoading])
		{
			[wview stopLoading];
		}
		
		NSString *u = [NSString stringWithFormat:@"%@crosspromo", server_url];
		//Post Request With ID
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:u] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30];
		
		NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
		
		[params setObject:build forKey:@"mgwubuild"];
		
		[params setObject:playerId forKey:@"mgid"];
		[params setObject:appId forKey:@"appid"];
		[params setObject:devId forKey:@"devid"];
		
		[params setObject:deviceType forKey:@"devicetype"];
		
		[params setObject:[NSNumber numberWithBool:dark] forKey:@"dark"];
		
		NSData* dparam = [MGWU jsonDataWithObject:params];
		NSData* dp = [MGWU symmetricEncrypt:dparam withKey:unicorn];
		
		[request setHTTPMethod:@"POST"];
		[request setValue:@"application/mgwu" forHTTPHeaderField:@"content-type"];
		[request setHTTPBody:dp];
		[wview loadRequest:request];
	}
}

- (void)webViewDidStartLoad:(UIWebView *)web
{
	if (!initialWebViewLoad)
	{
		if (!HUD)
		{
			HUD = [MGWUMBProgressHUD showHUDAddedTo:self.view animated:YES];
		}
	}
}

- (void)webViewDidFinishLoad:(UIWebView *)web
{
	if (!initialWebViewLoad)
	{
		[HUD removeFromSuperview];
		HUD = nil;
	}
	else{
		initialWebViewLoad = false;
	}
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	if (!initialWebViewLoad)
	{
		[HUD removeFromSuperview];
		HUD = nil;
		[MGWU showError];
	}
	else
	{
		initialWebViewLoad = false;
	}
	//[delegate dismissModalViewControllerAnimated:YES];
}

-(void)close
{
	[delegate dismissModalViewControllerAnimated:YES];
}

-(void)viewDidDisappear:(BOOL)animated
{
	if (view == CROSSPROMO)
		[wview removeFromSuperview];
	else
		[aboutview removeFromSuperview];
	
	[closeButton removeFromSuperview];
}

-(void)closeFB
{
	[delegate dismissModalViewControllerAnimated:YES];
	fvc = nil;
	
	noFacebook = TRUE;
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:noFacebook] forKey:@"mgwu_nofacebook"];
	
	[MGWU logEvent:@"facebook_nothanks"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}


//-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
//{
//	CGRect frame;
//	if (UIDeviceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]))
//	{
//		frame = CGRectMake(0, 0, 320, 480);
//	}
//	else
//	{
//		frame = CGRectMake(0, 0, 480, 320);
//	}
//	
//	if (view == CROSSPROMO)
//		wview.frame = frame;
//	else
//		aboutview.frame = frame;
//}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [[UIApplication sharedApplication].keyWindow.rootViewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}


///////////////iAP code

+ (void)testBuyProduct:(NSString*)productId withCallback:(SEL)m onTarget:(id)t
{
	NSAssert(productId && m && t, @"[MGWU] Need ProductID, Callback Method and Target");
	
	HUD = [MGWUMBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] keyWindow] animated:YES];
	[[[UIApplication sharedApplication] keyWindow] addSubview:HUD];
	HUD.labelText = @"Processing...";
	
	testiAP = productId;
	method = m;
	target = t;
	
	UIAlertView *aview = [[UIAlertView alloc] initWithTitle:@"Buy Product" message:productId delegate:mgwu cancelButtonTitle:@"Cancel" otherButtonTitles:@"Buy", nil];
	[aview show];
	
}

+ (void)testRestoreProducts:(NSArray*)products withCallback:(SEL)m onTarget:(id)t
{
	NSAssert(products && m && t, @"[MGWU] Need Products, Callback Method and Target");
	
	HUD = [MGWUMBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] keyWindow] animated:YES];
	[[[UIApplication sharedApplication] keyWindow] addSubview:HUD];
	HUD.labelText = @"Processing...";

	testiAP = products;
	method = m;
	target = t;
	
	UIAlertView *aview = [[UIAlertView alloc] initWithTitle:@"Restore" message:@"Restore Purchases?" delegate:mgwu cancelButtonTitle:@"Cancel" otherButtonTitles:@"Restore", nil];
	[aview show];
	
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if ([[alertView buttonTitleAtIndex:1] isEqualToString:@"Buy"] || [[alertView buttonTitleAtIndex:1] isEqualToString:@"Restore"])
	{
		if (buttonIndex == 0)
		{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
			[target performSelector:method withObject:nil];
#pragma clang diagnostic pop
		}
		else
		{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
			[target performSelector:method withObject:testiAP];
#pragma clang diagnostic pop
		}
		
		[HUD removeFromSuperview];
		HUD = nil;
		method = nil;
		target = nil;
		testiAP = nil;
	}
	else
	{
		pastAlertView = nil;
		if (buttonIndex == 1)
		{
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:gameLink]];
			[MGWU logEvent:@"push_appstore_opened" withParams:@{@"linkedapp":gameLinkId, @"appstate":@"active"}];
		}
	}
}

+ (void)buyProduct:(NSString*)productId withCallback:(SEL)m onTarget:(id)t {
	
	NSAssert(productId && m && t, @"[MGWU] Need ProductID, Callback Method and Target");
	NSAssert(iAPHelper, @"[MGWU] You need to initialize iAPs");

	HUD = [MGWUMBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] keyWindow] animated:YES];
	[[[UIApplication sharedApplication] keyWindow] addSubview:HUD];
	HUD.labelText = @"Processing...";
	
	method = m;
	target = t;
	
    [iAPHelper buyProductIdentifier:productId];
    
	[MGWU logEvent:@"purchasing" withParams:@{@"productID":productId}];
}

+ (void)restoreProductsWithCallback:(SEL)m onTarget:(id)t {
	
	NSAssert(m && t, @"[MGWU] Need Callback Method and Target");
	NSAssert(iAPHelper, @"[MGWU] You need to initialize iAPs");
	
	HUD = [MGWUMBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] keyWindow] animated:YES];
	[[[UIApplication sharedApplication] keyWindow] addSubview:HUD];
	HUD.labelText = @"Processing...";
	
	method = m;
	target = t;
	
    [iAPHelper restore];
    
	[MGWU logEvent:@"restoring"];
}

- (void)restored:(NSMutableArray *)products
{
	[MGWU logEvent:@"restored" withParams:@{@"producs":products}];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	[target performSelector:method withObject:products];
#pragma clang diagnostic pop
	
	[HUD removeFromSuperview];
	HUD = nil;
	method = nil;
	target = nil;
}

- (void)purchased:(NSString *)productId
{
	[MGWU logEvent:@"purchased" withParams:@{@"productID":productId}];
	
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	[target performSelector:method withObject:productId];
#pragma clang diagnostic pop
	
	[HUD removeFromSuperview];
	HUD = nil;
	method = nil;
	target = nil;
}

- (void)failedToRestore:(NSString *)error
{
	//TODO logevent
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	[target performSelector:method withObject:nil];
#pragma clang diagnostic pop
	
	[HUD removeFromSuperview];
	HUD = nil;
	method = nil;
	target = nil;
}

- (void)failedToPurchase:(NSString *)error
{
	//TODO logevent
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	[target performSelector:method withObject:nil];
#pragma clang diagnostic pop
	
	[HUD removeFromSuperview];
	HUD = nil;
	method = nil;
	target = nil;
}

@end
