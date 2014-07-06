//
//  CCSpriteDownloadImage.m
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 05/07/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCSpriteDownloadImage.h"

@implementation CCSpriteDownloadImage

static NSOperationQueue *imageDownloadQueue;
static NSCache *profilePictureCache;

- (id)initWithTexture:(CCTexture *)texture rect:(CGRect)rect rotated:(BOOL)rotated {
  self = [super initWithTexture:texture rect:rect rotated:rotated];
  
  if (self) {
    if (!imageDownloadQueue) {
      imageDownloadQueue = [[NSOperationQueue alloc] init];
    }
    
    if (!profilePictureCache) {
      profilePictureCache = [[NSCache alloc] init];
    }
    
  }
  
  return self;
}

- (void)setUsername:(NSString *)username {
  _username = [username copy];
  
  CCTexture *textureForUserName = [profilePictureCache objectForKey:username];
  
  if (textureForUserName) {
    [self setTexture:textureForUserName];
  } else {
    NSString *downloadPath = [NSString stringWithFormat: @"https://graph.facebook.com/%@/picture?width=240&height=240", username];
    [self setDownloadImage:downloadPath];
  }
}

- (void)setDownloadImage:(NSString *)urlString {
  NSString *path = [self downloadPathForUsername:self.username];
  UIImage *profilePicture = [[UIImage alloc] initWithContentsOfFile:path];

  if (profilePicture) {
    CCTexture *texture = [[CCTexture alloc] initWithCGImage:profilePicture.CGImage contentScale:1.f];
    [self setTexture:texture];
    [profilePictureCache setObject:texture forKey:self.username];

    return;
  }
  
  NSURL *url = [NSURL URLWithString:urlString];
	NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
  
  [NSURLConnection sendAsynchronousRequest:urlRequest queue:imageDownloadQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
    
    NSInteger statusCode = [((NSHTTPURLResponse *) response) statusCode];
    if (statusCode == 404) {
      return;
    }
    
    [data writeToFile: path atomically: TRUE];
    
    UIImage *profilePicture = [[UIImage alloc] initWithContentsOfFile:path];
    
    dispatch_async(dispatch_get_main_queue(), ^{
      CCTexture *texture = [[CCTexture alloc] initWithCGImage:profilePicture.CGImage contentScale:1.f];
      [self setTexture:texture];
      [profilePictureCache setObject:texture forKey:self.username];
    });
    
  }];
}

- (NSString *)downloadPathForUsername:(NSString *)username {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
  NSString *path = [[paths objectAtIndex: 0] stringByAppendingPathComponent:username];
  
  return path;
}

@end
