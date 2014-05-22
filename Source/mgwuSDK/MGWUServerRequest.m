//
//  MGWUServerRequest.m
//  mgwuSDK
//
//  Created by Ashutosh Desai on 8/11/13.
//  Copyright (c) 2013 makegameswithus inc. All rights reserved.
//

#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>
#import <AWSS3/AWSS3.h>

#import "MGWUServerRequest.h"
#import "MGWUJsonParser.h"
#import "MGWUJsonWriter.h"
#import "MGWUMBProgressHUD.h"
#import "MGWUNotificationHandler.h"

@interface MGWUServerRequest () <MGWUMBProgressHUDDelegate>
{
	MGWUMBProgressHUD *HUD;
	id serverData;
	NSString *serverError;
}

@end

static NSString *server_url = @"https://dev.makegameswith.us/";
static NSData *unicorn;
static NSDictionary *genericParams;
static AmazonS3Client *s3;
static NSString *bucket_name;

@implementation MGWUServerRequest

+ (void)setServerURL:(NSString *)s andUnicorn:(NSData *)u
{
	server_url = s;
	unicorn = u;
}

+ (void)setS3:(AmazonS3Client*)s andBucketName:(NSString*)b
{
	s3 = s;
	bucket_name = b;
}

+ (void)setGenericParams:(NSDictionary*)p
{
	genericParams = p;
}

+ (void)requestWithParams:(NSMutableDictionary *)p withCallback:(SEL)c onTarget:(id)t
{
	MGWUServerRequest *sr = [[MGWUServerRequest alloc] init];
	sr.method = c;
	sr.target = t;
	[sr showHUDWithParams:p];
}

- (void)showHUDWithParams:(NSMutableDictionary*)params {
	HUD = [[MGWUMBProgressHUD alloc] initWithView:[[UIApplication sharedApplication] keyWindow]];
    [[[UIApplication sharedApplication] keyWindow] addSubview:HUD];
	[HUD setRemoveFromSuperViewOnHide:YES];
	
    [HUD setDelegate:self];
    HUD.labelText = @"Loading...";
	
	[HUD showWhileExecuting:@selector(myTask:) onTarget:self withObject:params animated:YES];
}

- (void)hudWasHidden:(MGWUMBProgressHUD *)hud
{
	if (serverError)
		[self showMessage:serverError withImage:nil];
	else if (!serverData)
		[self showError];
	
	
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	[self.target performSelector:self.method withObject:serverData];
#pragma clang diagnostic pop
	
	serverData = nil;

	HUD = nil;
	self.target = nil;
	self.method = nil;
}

- (void)showError
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

- (void)showMessage:(NSString*)message withImage:(NSString *)imageName
{
	if (!imageName)
		imageName = @"MGWUIcon.png";
	
	UIImage *i = [UIImage imageNamed:imageName];
	
	[[MGWUNotificationHandler defaultHandler] notifyAchievementTitle:@"" message:message andImage:i];
}

#pragma mark -
#pragma mark Execution code

- (void)myTask:(NSMutableDictionary*)params {
	
	id postProcessInfo = nil;
	
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
		if ([[params objectForKey:@"gamestate"] isEqualToString:@"started"] || [[params objectForKey:@"gamestate"] isEqualToString:@"onemove"])
			postProcessInfo = moveFileInfo;
	}
	
	NSString *endpoint = [params objectForKey:@"endpoint"];
	[params removeObjectForKey:@"endpoint"];
	
	NSString *u = [NSString stringWithFormat:@"%@%@", server_url, endpoint];
	
	NSMutableURLRequest *request = [NSMutableURLRequest
									requestWithURL:[NSURL URLWithString:u]];
	
	[params addEntriesFromDictionary:genericParams];
//	[params setObject:build forKey:@"mgwubuild"];
//	
//	[params setObject:playerId forKey:@"mgid"];
//	[params setObject:appId forKey:@"appid"];
//	[params setObject:appVersion forKey:@"appver"];
//	[params setObject:devId forKey:@"devid"];
	
	NSData* dparam = [self jsonDataWithObject:params];
	NSData* dp = [self symmetricEncrypt:dparam withKey:unicorn];
	
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
		NSData* dData = [self symmetricDecrypt:urlData withKey:unicorn];
		if (!dData)
		{
			serverData = nil;
		}
		else
		{
			NSDictionary* o = (NSDictionary*)[self jsonObjectWithData:dData];
			
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
				[self postProcessDataForEndpoint:endpoint withInfo:postProcessInfo];
			}
		}
		
	}
}

-(void)postProcessDataForEndpoint:(NSString*)endpoint withInfo:(id)info
{
	if ([endpoint isEqualToString:@"move"] && info)
	{
		//Rename to g-m- / delete original
		NSString *originalFilePath = [info objectForKey:@"filepath"];
		NSString *oldFileKey = [info objectForKey:@"filekey"];
		NSString *newFileKey = [[[oldFileKey componentsSeparatedByString:@"-"] objectAtIndex:0] stringByAppendingFormat:@"-g%@-m%d", [serverData objectForKey:@"gameid"], 1];
		NSString *ext = [originalFilePath pathExtension];
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		
		NSString *oldFilePath = [[[paths objectAtIndex:0] stringByAppendingPathComponent:oldFileKey] stringByAppendingPathExtension:ext];
		NSString *newFilePath = [[[paths objectAtIndex:0] stringByAppendingPathComponent:newFileKey] stringByAppendingPathExtension:ext];
		
		[[NSData dataWithContentsOfFile:oldFilePath] writeToFile:newFilePath atomically:YES];
		[[NSFileManager defaultManager] removeItemAtPath:oldFilePath error:nil];
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

-(NSData *) symmetricEncrypt: (NSData *) d withKey: (NSData *) k
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

- (NSData *) symmetricDecrypt: (NSData *) d withKey: (NSData *) k
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

-(NSObject*)jsonObjectWithData:(NSData *)d
{
	MGWUJsonParser *parser = [[MGWUJsonParser alloc] init];
    NSObject *o = [parser objectWithData:d];
    if (!o)
        NSLog(@"-JSONValue failed. Error is: %@", parser.error);
    return o;
}

-(NSData*)jsonDataWithObject:(NSObject*)o
{
	MGWUJsonWriter *writer = [[MGWUJsonWriter alloc] init];
    NSData *d = [writer dataWithObject:o];
	NSAssert(d, @"[MGWU] Do not put objects that are not NSStrings, NSNumbers, NSDictionaries or NSArrays into NSDictionaries that you pass to the MGWU toolkit");
    return d;
}

@end
