/*
 * SpriteBuilder: http://www.spritebuilder.org
 *
 * Copyright (c) 2012 Zynga Inc.
 * Copyright (c) 2013 Apportable Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "cocos2d.h"

#import "AppDelegate.h"
#import "CCBuilderReader.h"
#import "MGWU.h"
#import "UserInfo.h"
#import "MainScene.h"

@implementation AppController {
  CCScene *_startScene;
  MainScene *_mainScene;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Configure Cocos2d with the options set in SpriteBuilder
    NSString* configPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Published-iOS"]; // TODO: add support for Published-Android support
    configPath = [configPath stringByAppendingPathComponent:@"configCocos2d.plist"];
    
    NSMutableDictionary* cocos2dSetup = [NSMutableDictionary dictionaryWithContentsOfFile:configPath];
    
    // Note: this needs to happen before configureCCFileUtils is called, because we need apportable to correctly setup the screen scale factor.
#ifdef APPORTABLE
    if([cocos2dSetup[CCSetupScreenMode] isEqual:CCScreenModeFixed])
        [UIScreen mainScreen].currentMode = [UIScreenMode emulatedMode:UIScreenAspectFitEmulationMode];
    else
        [UIScreen mainScreen].currentMode = [UIScreenMode emulatedMode:UIScreenScaledAspectFitEmulationMode];
#endif
    
    // Configure CCFileUtils to work with SpriteBuilder
    [CCBReader configureCCFileUtils];
    
    // Do any extra configuration of Cocos2d here (the example line changes the pixel format for faster rendering, but with less colors)
    //[cocos2dSetup setObject:kEAGLColorFormatRGB565 forKey:CCConfigPixelFormat];
  
    [self setupCocos2dWithOptions:cocos2dSetup];
  
    [MGWU loadMGWU:@"MultiplayerTurnBasedGame"];
    [MGWU noFacebookPrompt];

    NSDictionary *me = [[NSUserDefaults standardUserDefaults] objectForKey:@"mgwu_fbobject_self"];
  
    _mainScene = _startScene.children[0];
  
    if ([MGWU isFacebookActive]) {
      [[UserInfo sharedUserInfo] refreshWithCallback:@selector(loadedUserInfo:) onTarget:_mainScene];
    } else {
      CCScene *fbLoginScene = [CCBReader loadAsScene:@"FacebookLoginScene" owner:self];
      CCTransition *presentModalTransition = [CCTransition transitionMoveInWithDirection:CCTransitionDirectionUp duration:0.3f];
      [[CCDirector sharedDirector] pushScene:fbLoginScene withTransition:presentModalTransition];
    }
  
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // attempt to extract a token from the url
    return [MGWU handleURL:url];
}

-(void) applicationDidBecomeActive:(UIApplication *)application {
  if ([MGWU isFacebookActive]) {
    [[UserInfo sharedUserInfo] refreshWithCallback:@selector(loadedUserInfo:) onTarget:_mainScene];
  }
}

- (void)facebookLoginButtonSelected {
  [MGWU loginToFacebookWithCallback:@selector(facebookLoginCompleted:) onTarget:self];
}

- (void)facebookLoginCompleted:(id)serverData {
  if ([serverData isEqualToString:@"Success"]) {
    [[UserInfo sharedUserInfo] refreshWithCallback:@selector(loadedUserInfo:) onTarget:_mainScene];
    [[CCDirector sharedDirector] popScene];
  }
}

- (CCScene*) startScene
{
  _startScene = [CCBReader loadAsScene:@"MainScene"];
  
  return _startScene;
}

@end
