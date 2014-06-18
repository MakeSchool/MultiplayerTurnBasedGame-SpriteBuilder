//
//  MGWUFBLoginViewController.m
//  MGWU
//
//  Created by Ashutosh Desai on 7/30/12.
//
//

#import "MGWUFBLoginViewController.h"

@interface MGWUFBLoginViewController ()

@end

@implementation MGWUFBLoginViewController

@synthesize mgwu, fbOptional;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		fbOptional = TRUE;
    }
    return self;
}

-(IBAction)login:(id)sender
{
	[mgwu login];
}

-(IBAction)close:(id)sender
{
	[mgwu closeFB];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
	if (!fbOptional)
	{
		[close setEnabled:NO];
		[close setHidden:YES];
	}
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == [[UIApplication sharedApplication] statusBarOrientation]);
}

@end
