//
//  PictureCache.m
//  Ghost
//
//  Created by Ashutosh Desai on 11/9/12.
//  Copyright (c) 2012 makegameswithus inc. Free to use for all purposes.
//

#import "AppIconCache.h"

@implementation AppIconCache

-(id)initWithAppId:(NSString*)app andImageView:(UIImageView*)iv inTableView:(UITableView*)tv forIndexPath:(NSIndexPath*)ip
{
	self = [super init];
	//Save instance variables, tView and indexPath will be nil if imageView is not in tableViewCell
	appID = app;
	imageView = iv;
	tView = tv;
	indexPath = ip;
	
	return self;
}

//Download Image from facebook
- (void) downloadImage
{
	//Get url of facebook pic
	NSString *u;
	
	if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] == YES && [[UIScreen mainScreen] scale] == 2.00)
		u = [NSString stringWithFormat: @"https://s3.amazonaws.com/mgwu-app-icons/com_mgwu_%@@2x.png", appID];
	else
		u = [NSString stringWithFormat: @"https://s3.amazonaws.com/mgwu-app-icons/com_mgwu_%@.png", appID];
	
	////////This block of code downloads the image
	NSURL *url = [NSURL URLWithString:u];
	NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
	
	NSURLResponse *response = nil;
	NSError *error = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
	
	if (error || !data){
		return;
	}
	////////This block of code downloads the image
	
	//Name to save the picture (username.png)
	NSString *picname = [appID stringByAppendingString:@"_MGWU.png"];
	
	////////This block of code saves the image to the "Caches Directory", note the end of the path is "picname" which means it will be stored as username.png
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *path = [[paths objectAtIndex: 0] stringByAppendingPathComponent:picname];
	[data writeToFile: path atomically: TRUE];
	////////This block of code saves the image to the "Caches Directory"

	//Call method to update the cell to use the newly downloaded image (needs to be done on the main thread)
	[self performSelectorOnMainThread:@selector(setImageIfVisible) withObject:nil waitUntilDone:NO];
}

//This method sets the image to imageView
- (void)setImageIfVisible
{
	//If imageView no longer exists, do nothing
	if (!imageView)
		return;
	
	//If the imageView was in a tableViewCell, and the cell is no longer visible or doesn't exist, do nothing
	if (tView)
	{
		UITableViewCell *cell = [tView cellForRowAtIndexPath:indexPath];
		if (!cell)
			return;
	}
	
	//Get the image name and the cell from the dictionary
	NSString* imageName = [appID stringByAppendingString:@"_MGWU.png"];
	
	//Makes sure the cell is still visible (if not no point in updating the image)

	/////////////This block of code searches for an image named imageName (in this case it will be username.png)
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *path = [[paths objectAtIndex: 0] stringByAppendingPathComponent:imageName];
	UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
	////////////This block of code searches for an image named imageName

	//If the image exists, set the imageView to display this image
	if (image)
		imageView.image = image;
}

-(void)getImage:(NSNumber*)exists
{
	//Get the image name and the cell from the dictionary
	NSString* imageName = [appID stringByAppendingString:@"_MGWU.png"];
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *path = [[paths objectAtIndex: 0] stringByAppendingPathComponent:imageName];
	
	//Make sure this fits in the desired image container
	//imageView.contentMode = UIViewContentModeScaleAspectFill;
	//imageView.clipsToBounds = TRUE;
	
	//If image doesn't exist, download
	if (![exists boolValue])
		[self downloadImage];
	//Else set image and download image if it is over a day old
	else
	{
		NSFileManager* fm = [NSFileManager defaultManager];
		NSDictionary* attrs = [fm attributesOfItemAtPath:path error:nil];
		if (attrs != nil) {
			NSDate *downloadDate = (NSDate*)[attrs objectForKey: NSFileCreationDate];
			NSDate *today = [NSDate date];
			
			NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
			NSDateComponents *dateDifference = [gregorian components:NSWeekCalendarUnit fromDate:downloadDate toDate:today options:0];
			NSUInteger daysDiff = [dateDifference day];
			
			if (daysDiff)
				[self downloadImage];
		}
	}
}

//This method sets the image to imageView
- (BOOL)setImage
{
	//If imageView no longer exists, do nothing
	if (!imageView)
		return FALSE;
	
	//Get the image name and the cell from the dictionary
	NSString* imageName = [appID stringByAppendingString:@"_MGWU.png"];
	
	//Makes sure the cell is still visible (if not no point in updating the image)
	
	/////////////This block of code searches for an image named imageName (in this case it will be username.png)
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *path = [[paths objectAtIndex: 0] stringByAppendingPathComponent:imageName];
	UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
	////////////This block of code searches for an image named imageName
	
	//If the image exists, set the imageView to display this image
	if (image)
	{
		imageView.image = image;
		return TRUE;
	}
	
	return FALSE;
}

//Method to set profile picture to generic image view
+(void)setAppIcon:(NSString*)a forImageView:(UIImageView*)iv
{
	AppIconCache *aic = [[AppIconCache alloc] initWithAppId:a andImageView:iv inTableView:nil forIndexPath:nil];
	
	NSNumber *exists = [NSNumber numberWithBool:[aic setImage]];
	
	//Get Image asynchronously
	[aic performSelectorInBackground:@selector(getImage:) withObject:exists];
}

//Method to set profile picture to image view residing in a table view cell (needs to be treated differently since table views reuse cells)
+(void)setAppIcon:(NSString *)a forImageView:(UIImageView *)iv inTableView:(UITableView*)tv forIndexPath:(NSIndexPath*)ip
{
	AppIconCache *aic = [[AppIconCache alloc] initWithAppId:a andImageView:iv inTableView:tv forIndexPath:ip];
	
	NSNumber *exists = [NSNumber numberWithBool:[aic setImage]];
	
	//Get Image asynchronously
	[aic performSelectorInBackground:@selector(getImage:) withObject:exists];
}

@end
