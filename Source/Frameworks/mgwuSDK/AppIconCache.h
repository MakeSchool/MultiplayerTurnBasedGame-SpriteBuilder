//
//  PictureCache.h
//  Ghost
//
//  Created by Ashutosh Desai on 11/9/12.
//  Copyright (c) 2012 makegameswithus inc. Free to use for all purposes.
//
//  Class to asynchronously load Facebook Profile Pictures

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface AppIconCache : NSObject
{
	//Username of profile picture to pull
	NSString *appID;
	//Image view to fill with profile picture
	UIImageView *imageView;
	//If part of table view, table view of cell containing image view
	UITableView *tView;
	//If part of table view, index path of cell containing image view
	NSIndexPath *indexPath;
}

//Set appIcon to generic image view
+(void)setAppIcon:(NSString*)a forImageView:(UIImageView*)iv;

//Set app icon to image view residing in a table view cell (needs to be treated differently since table views reuse cells)
+(void)setAppIcon:(NSString *)a forImageView:(UIImageView *)iv inTableView:(UITableView*)tv forIndexPath:(NSIndexPath*)ip;

-(id)initWithAppId:(NSString*)app andImageView:(UIImageView*)iv inTableView:(UITableView*)tv forIndexPath:(NSIndexPath*)ip;

@end
