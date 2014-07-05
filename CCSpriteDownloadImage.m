//
//  CCSpriteDownloadImage.m
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 05/07/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCSpriteDownloadImage.h"

@implementation CCSpriteDownloadImage {
  NSString *_username;
}

static NSOperationQueue *imageDownloadQueue;

- (void)setUsername:(NSString *)username {
  _username = username;
  NSString *downloadPath = [NSString stringWithFormat: @"https://graph.facebook.com/%@/picture?width=120&height=120", username];
  [self setDownloadImage:downloadPath];
}

- (void)setDownloadImage:(NSString *)urlString {
  if (!imageDownloadQueue) {
    imageDownloadQueue = [[NSOperationQueue alloc] init];
  }
  
  NSURL *url = [NSURL URLWithString:urlString];
	NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
  
  [NSURLConnection sendAsynchronousRequest:urlRequest queue:imageDownloadQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *path = [[paths objectAtIndex: 0] stringByAppendingPathComponent:_username];
    [data writeToFile: path atomically: TRUE];
    
    UIImage *profilePicture = [[UIImage alloc] initWithContentsOfFile:path];
    
    dispatch_async(dispatch_get_main_queue(), ^{
      CCTexture *texture = [[CCTexture alloc] initWithCGImage:profilePicture.CGImage contentScale:1.f];
      [self setTexture:texture];
    });
    
  }];
}

@end
