//
//  MGWUServerRequest.h
//  mgwuSDK
//
//  Created by Ashutosh Desai on 8/11/13.
//  Copyright (c) 2013 makegameswithus inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MGWUServerRequest : NSObject

@property (nonatomic, strong) id target;
@property (nonatomic) SEL method;

+ (void)setServerURL:(NSString *)s andUnicorn:(NSData *)u;
+ (void)setS3:(AmazonS3Client*)s andBucketName:(NSString*)b;
+ (void)setGenericParams:(NSDictionary*)p;
+ (void)requestWithParams:(NSMutableDictionary *)p withCallback:(SEL)c onTarget:(id)t;

@end
