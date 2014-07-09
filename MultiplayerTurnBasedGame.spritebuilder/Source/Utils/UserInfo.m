//
//  UserInfo.m
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 17/06/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "UserInfo.h"

@interface UserInfo ()

@property (nonatomic, assign) SEL refreshCallback;
@property (nonatomic, weak) id refreshTarget;

@end

@implementation UserInfo

#pragma mark - Initializer

+ (instancetype)sharedUserInfo {
	static dispatch_once_t once;
	static id _sharedInstance = nil;
	
	dispatch_once(&once, ^{
		_sharedInstance = [[self alloc] init];
	});
	
	return _sharedInstance;
}

+ (NSString *)shortNameFromName:(NSString*)name
{
	if ([name isEqualToString:@"Random Player"])
		return @"Random Player";
		
	NSArray *names = [name componentsSeparatedByString:@" "];
	int count = [names count];
	if (count == 1)
		return name;
	else
		return [NSString stringWithFormat:@"%@ %@", names[0], [names[count-1] substringToIndex:1]];
}

#pragma mark - Refreshing

- (void)refreshWithCallback:(SEL)callback onTarget:(id)target {
	self.refreshCallback = callback;
	self.refreshTarget = target;
	
	[MGWU getMyInfoWithCallback:@selector(refreshCompleted:) onTarget:self];
}

- (void)refreshCompleted:(NSDictionary *)userInfo {
	[self extractUserInformation:userInfo];
	
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	[self.refreshTarget performSelector:self.refreshCallback withObject:userInfo];
#pragma clang diagnostic pop
	
}

#pragma mark - Extract User Information

- (void)extractUserInformation:(NSDictionary *)userInfo {
	// name and username
	_name = userInfo[@"info"][@"name"];
	_username = userInfo[@"info"][@"username"];
	[self splitGames:userInfo];
	
	_friends = [NSMutableArray arrayWithArray:userInfo[@"friends"]];
}

- (void)splitGames:(NSDictionary *)userInfo {
	// divide games into: gamesWaitingOn, gamesYourTurn, gamesCompleted
	self.gamesCompleted = [[NSMutableArray alloc] init];
	self.gamesYourTurn = [[NSMutableArray alloc] init];
	self.gamesTheirTurn = [[NSMutableArray alloc] init];
	
	self.allGames = userInfo[@"games"];
	
	for (NSMutableDictionary *game in self.allGames)
	{
		NSString* gameState = game[@"gamestate"];
		NSString* turn = game[@"turn"];
		
		NSString* opponent;
		NSArray* gamers = game[@"players"];
		if ([gamers[0] isEqualToString:self.username])
			opponent = gamers[1];
		else
			opponent = gamers[0];
		NSString* oppName = game[opponent];
		game[@"opponent"] = opponent;
		game[@"opponentName"] = oppName;
		
		if ([gameState isEqualToString:@"ended"])
			[self.gamesCompleted addObject:game];
		else if ([turn isEqualToString:self.username])
			[self.gamesYourTurn addObject:game];
		else
			[self.gamesTheirTurn addObject:game];
	}
}

@end
