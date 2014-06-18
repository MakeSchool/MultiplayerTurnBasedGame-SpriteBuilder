//
//  GameCell.m
//  mgwuSDK
//
//  Created by Ashutosh Desai on 9/6/12.
//  Copyright (c) 2012 makegameswithus inc. All rights reserved.
//

#import "MGWUGameCell.h"
#import "AppIconCache.h"
#import <QuartzCore/QuartzCore.h>

@implementation MGWUGameCell

@synthesize tableView, indexPath;

- (id)initWithDark:(BOOL)d style:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
		
		dark = d;
		
		self.backgroundColor = [UIColor clearColor];
		
		CGRect frame = [[UIScreen mainScreen] bounds];
		if (UIDeviceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]))
			self.frame = CGRectMake(0, 0, frame.size.width, [MGWUGameCell height]);
		else
			self.frame = CGRectMake(0, 0, frame.size.height, [MGWUGameCell height]);
		
		self.selectionStyle = UITableViewCellSelectionStyleGray;
        // Initialization code
		UIView *dropshadow = [[UIView alloc] initWithFrame:CGRectMake(15, 7, 57, 57)];
		dropshadow.layer.shadowColor = [UIColor colorWithRed:170.0/255.0 green:170.0/255.0 blue:170.0/255.0 alpha:1].CGColor;
		dropshadow.layer.shadowOffset = CGSizeMake(1, -1);
		dropshadow.layer.shadowOpacity = 1;
		dropshadow.layer.shadowRadius = 4.0;
		dropshadow.clipsToBounds = NO;
		
		if (dark)
			iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mgwuPlaceholderIconDark.png"]];
		else
			iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mgwuPlaceholderIcon.png"]];
		iv.layer.masksToBounds = YES;
		iv.layer.cornerRadius = 9.0;
		
		[dropshadow addSubview:iv];
		
		UIView *borderbottom = [[UIView alloc] initWithFrame:CGRectMake(0, 71, self.frame.size.width, 1)];
		borderbottom.backgroundColor = [UIColor colorWithRed:234.0/255.0 green:234.0/255.0 blue:234.0/255.0 alpha:1];
		
		name = [[UILabel alloc] initWithFrame:CGRectMake(87, 4, self.frame.size.width - 97, 20)];
		name.font = [UIFont boldSystemFontOfSize:16.0];
		if (dark)
			name.textColor = [UIColor colorWithRed:221.0/255.0 green:221.0/255.0 blue:221.0/255.0 alpha:1];
		name.backgroundColor = [UIColor clearColor];
		
		description = [[UILabel alloc] initWithFrame:CGRectMake(87, 24, self.frame.size.width - 97, 40)];
		if (dark)
			description.textColor = [UIColor colorWithRed:170.0/255.0 green:170.0/255.0 blue:170.0/255.0 alpha:1];
		else
			description.textColor = [UIColor colorWithRed:130.0/255.0 green:130.0/255.0 blue:130.0/255.0 alpha:1];
		description.backgroundColor = [UIColor clearColor];
		description.numberOfLines = 0;
		
		[self.contentView addSubview:dropshadow];
		[self.contentView addSubview:name];
		[self.contentView addSubview:description];
		[self.contentView addSubview:borderbottom];

    }
    return self;
}

- (void)setGame:(NSDictionary*)g
{
	game = g;
	name.text = [game objectForKey:@"text"];
	
	description.frame = CGRectMake(87, 24, self.frame.size.width - 97, 40);
	description.text = [game objectForKey:@"desc"];
	[description sizeToFit];
	
//	if (self.indexPath.row % 2 == 0)
//		self.contentView.backgroundColor = [UIColor colorWithRed:252.0/255.0 green:252.0/255.0 blue:252.0/255.0 alpha:1];
	
	if (dark)
		iv.image = [UIImage imageNamed:@"mgwuPlaceholderIconDark.png"];
	else
		iv.image = [UIImage imageNamed:@"mgwuPlaceholderIcon.png"];
	
	[AppIconCache setAppIcon:[game objectForKey:@"id"] forImageView:iv inTableView:self.tableView forIndexPath:self.indexPath];
}

+ (float)height
{
	return 72.0;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
