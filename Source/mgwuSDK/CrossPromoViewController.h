//
//  CrossPromoViewController.h
//  mgwuSDK
//
//  Created by Ashutosh Desai on 9/6/12.
//  Copyright (c) 2012 makegameswithus inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGWUMBProgressHUD.h"
#import "MGWUGameCell.h"

@interface CrossPromoViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, MGWUMBProgressHUDDelegate>
{
	IBOutlet UITableView *tView;
	IBOutlet UIImageView *logo;
	MGWUMBProgressHUD *HUD;
	id serverData;
	NSError *serverError;
	id target;
	SEL method;
	NSMutableDictionary *params;
	NSData *unicorn;
	BOOL dark;
	UIViewController *delegate;
	
	NSMutableArray *apps;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil andParams:(NSMutableDictionary *)p andDark:(BOOL)dk andUnicorn:(NSData*)u andDelegate:(UIViewController*)d;

@end
