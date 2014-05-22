//
//  MGWUFBLoginViewController.h
//  MGWU
//
//  Created by Ashutosh Desai on 7/30/12.
//
//

#import <UIKit/UIKit.h>
#import "MGWU.h"

@protocol FBLoginDelegate <NSObject>

-(void)closeFB;
-(void)login;

@end

@interface MGWUFBLoginViewController : UIViewController
{
	MGWU<FBLoginDelegate> *mgwu;
	BOOL fbOptional;
	IBOutlet UIButton *close;
	IBOutlet UIButton *login;
}

@property MGWU *mgwu;
@property BOOL fbOptional;

@end
