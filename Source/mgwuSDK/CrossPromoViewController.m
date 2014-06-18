//
//  CrossPromoViewController.m
//  mgwuSDK
//
//  Created by Ashutosh Desai on 9/6/12.
//  Copyright (c) 2012 makegameswithus inc. All rights reserved.
//

#import "CrossPromoViewController.h"
#import "MGWU.h"
#import "MGWUJsonWriter.h"
#import "MGWUJsonParser.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>
#import "MGWUGameCell.h"

@interface CrossPromoViewController ()

@end

@implementation CrossPromoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil andParams:(NSMutableDictionary *)p andDark:(BOOL)dk andUnicorn:(NSData*)u andDelegate:(UIViewController*)d
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		params = p;
		unicorn = u;
		delegate = d;
		dark = dk;
		apps = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	if (dark)
	{
		self.view.backgroundColor = [UIColor colorWithRed:51.0/255.0 green:51.0/255.0 blue:51.0/255.0 alpha:1];
		logo.image = [UIImage imageNamed:@"mgwuLogoDark.png"];
	}
}

-(IBAction)close:(id)sender
{
	[delegate dismissModalViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
	HUD = [[MGWUMBProgressHUD alloc] initWithView:[[UIApplication sharedApplication] keyWindow]];
    [[[UIApplication sharedApplication] keyWindow] addSubview:HUD];
	[HUD setRemoveFromSuperViewOnHide:YES];
	
    [HUD setDelegate:self];
    HUD.labelText = @"Loading...";
	[HUD showWhileExecuting:@selector(myTask) onTarget:self withObject:nil animated:YES];
}

- (void)myTask {
	NSString *u = [params objectForKey:@"url"];
	[params removeObjectForKey:@"url"];
	//	if (leaderboards)
	//		u = [NSString stringWithFormat:@"%@getallhs", server_url];
	//	else
	//		u = [NSString stringWithFormat:@"%@geths", server_url];
	
	NSMutableURLRequest *request = [NSMutableURLRequest
									requestWithURL:[NSURL URLWithString:u]];
	
	//	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
	
	NSData* dparam = [CrossPromoViewController jsonDataWithObject:params];
	NSData* dp = [CrossPromoViewController symmetricEncrypt:dparam withKey:unicorn];
	
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
		NSData* dData = [CrossPromoViewController symmetricDecrypt:urlData withKey:unicorn];
		if (!dData)
		{
			serverData = nil;
		}
		else
		{
			NSDictionary* o = (NSDictionary*)[CrossPromoViewController jsonObjectWithData:dData];
			
			if (!o || ![[o allKeys] containsObject:@"response"])
			{
				serverData = nil;
			}
			else if ([[o allKeys] containsObject:@"error"])
			{
				serverData = nil;
				serverError = [o objectForKey:@"error"];
				NSLog(@"%@", serverError);
			}
			else
			{
				serverData = [o objectForKey:@"response"];
			}
		}
		
	}
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

- (void)hudWasHidden:(MGWUMBProgressHUD *)hud
{
	if (!serverData)
	{
		[MGWU showError];
		return;
	}
	
	apps = serverData;
	[tView reloadData];
	
	HUD = nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [apps count];
}

- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [MGWUGameCell height];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"GameCell";
    
    MGWUGameCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        cell = [[MGWUGameCell alloc] initWithDark:dark style:UITableViewCellStyleDefault reuseIdentifier:@"GameCell"
				];
    }
	
	cell.tableView = tableView;
	cell.indexPath = indexPath;
	
	[cell setGame:[apps objectAtIndex:indexPath.row]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[MGWU logEvent:@"appstore_opened" withParams:@{@"linkedapp":[NSString stringWithFormat:@"com_mgwu_%@", [[apps objectAtIndex:indexPath.row] objectForKey:@"id"]]}];
	NSString *url = [NSString stringWithFormat:@"%@&ct=%@", [[apps objectAtIndex:indexPath.row] objectForKey:@"url"], [params objectForKey:@"appid"]];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return [[UIApplication sharedApplication].keyWindow.rootViewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

@end
