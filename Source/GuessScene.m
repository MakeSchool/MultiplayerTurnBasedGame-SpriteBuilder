//
//  GuessScene.m
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 06/06/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "GuessScene.h"

@implementation GuessScene {
  CCTextField *_textField;
}

- (void)onEnterTransitionDidFinish {
  [super onEnterTransitionDidFinish];
  
  UITextField *letter = _textField.textField;
  letter.font = [UIFont fontWithName:@"ghosty" size:40];
  letter.textColor = [UIColor whiteColor];
  [letter becomeFirstResponder];
  
  letter.placeholder = @"";
	[letter setReturnKeyType:UIReturnKeyDefault];
	[letter setAutocorrectionType:UITextAutocorrectionTypeNo];
	[letter setAutocapitalizationType:UITextAutocapitalizationTypeNone];
  [letter setKeyboardAppearance:UIKeyboardAppearanceAlert];
}

@end
