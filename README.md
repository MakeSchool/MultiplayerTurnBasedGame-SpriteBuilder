#Rock, Paper, Scissors - A simple turn based multiplayer game



#1. Setup

When you start developing your own game you need to make some changes to make sure our servers + facebook treat it as a new app.

**Enabling SDK Features**

First create your app on our server at this url: [https://dev.makegameswith.us/createapp](https://dev.makegameswith.us/createapp)

In the left bar of Xcode, click on your project, then navigate to "info" (see screenshot below). Change the Bundle identifier to "com.xxx.xxx" to match the app you created on the server. **Delete the project from any simulator / device you've been testing on, you'll also need to delete any other apps which use the new bundle identifier (to ensure this, in the simulator top bar you can go to iOS Simulator -> Reset Content and Settings...)**. On the top bar of Xcode go to Product -> Clean. This should ensure you are using the new bundle identifier.

![image](https://s3.amazonaws.com/mgwu-misc/mgwuSDK+Tutorial/bundle.png)

Now open the file AppDelegate.m. In the method `application: didFinishLaunchingWithOptions:` find the line:

<!--hfmd>.. sourcecode:: objective-c<hfmd-->

    [MGWU loadMGWU:@"secretkey"];

Replace 'secretkey' with the secret key you used when you created your app on the server. 

**Enabling Facebook Features**

Facebook integration is set up for you in this template, but you'll have to create a new Facebook app. Follow these steps (here's a link to the [Facebook App Dashboard](https://developers.facebook.com/apps/), you'll need to register as a developer):

![image](https://s3.amazonaws.com/mgwu-misc/mgwuSDK+Tutorial/fb1.png)
![image](https://s3.amazonaws.com/mgwu-misc/mgwuSDK+Tutorial/fb2.png)
![image](https://s3.amazonaws.com/mgwu-misc/mgwuSDK+Tutorial/fb3.png)


#2. How to Plug in Your Game


Generally it's best to build the basic components of the game in a different project, this way you don't have to go through all the menus when you want to test things. Then once you've tested things to mostly work the way you want with dummy data, work on plugging this back into the template.


##Structure of the Game
![image](RockPaperScissors_Scenes.png)

###MainScene
Displays a list of all current games, divided into three categories:
- Games where it is the players turn
- Games where it is the opponents turn
- Games that are completed

Allows to "Play now" which will either continue an existing game, start a new game against a friend which whom the player hasn't started a game yet or will start a game against a random other player of the game.

###FriendListScene
This scene lists all Facebook players who are also playing the game. From where a player can start games against his friends. An "invite Friends" button allows players to invite Facebook friends who aren't playing the game yet.

###PreMatchScene
Displays the current state of the game including all previous rounds. Is also used to display games that are completed.

###GameplayScene
This scene allows the player to perform a move and choose between Rock, Paper and Scissors.

###RoundResultScene
Displayed after each round is complete (each player has chosen either Rock, Paper or Scissors). This scene will fade both choices in slowly and then display wether the player has lost or won against the opponent, or wether this round was a draw.


##What you need to customize

**PreMatchScene**:
Change the PreMatchScene to give an overview of the game currently going on between two players.

**GameplayScene**:
Update the GameplayScene to implement the main mechanic of your game. In this template the GameplayScene implements a selection of Rock, Paper or Scissors. Make sure that the `performMoveForPlayerInGame()` function is called once the player has completed the Gameplay. That function sends the *move* of the current player to the MGWU server. You will have to update the `performMoveForPlayerInGame()` function in `GameDataUtils.m` - you should do that once you know how you want to store individual moves and the current game state for your game.

**RoundResultScene**:
If your game wants to display the results of each rounds between two players you should use and update the `RoundResultScene` class. The `RoundResultScene` is presented when a game is selected from the list of games in the `MainScene` and from the `GameplayScene` after a player has performed a move that completes a round.

**Constants.h**:
The most important constants used in the game are stored in *Constants.h*:

	static NSInteger MOVES_PER_ROUND = 2;
	static NSInteger ROUNDS_PER_GAME = 3;
	
They define how many rounds a game has and how many moves belong to one round. If your game has a different amount of rounds or moves than the tempalte game, you should update these constants.

This should be enough to carry you forward, poking around the code / re-reading the SDK instructions should help explain the rest!

##Other Important Classes/Files

###UserInfo
The `UserInfo` class stores all of the information received from the MGWU server. You should read the [documenation of the MGWU SDK](https://s3.amazonaws.com/mgwu/mgwuSDK-instructions.html) to get an overview of the available methods and information provided by the SDK. The `UserInfo` class calls the following method of the MGWU SDK:

	  [MGWU getMyInfoWithCallback:@selector(refreshCompleted:) onTarget:self];

and stores the results in a structurded manner. The `UserInfo` class consists of different properties that provide easy access to the information received from the MGWU SDK server.

`UserInfo` is implemented as a singleton. If you want to access information do it as follows:
 
 	// access username
 	NSString *playerUsername = [[UserInfo sharedUserInfo] username];

 If you want the `UserInfo` class to download the latest information from the MGWU server you should call:
 
	 [[UserInfo sharedUserInfo] refreshWithCallback:@selector(yourCallback) onTarget:self];

The callback you provide within this method call will be called as soon as the data is retrieved from the server. In the template the `MainScene` methods calls the `refreshWithCallback` method of `UserInfo` in the `onEnterTransitionDidFinish` method; whenever the `MainScene` appears, the latest data from the MGWU server is loaded.


###GameDataUtils
`GameDataUtils` is a collection of convenience functions that make it easier to extract relevant information from the data provided by the MGWU SDK.

Here are two examples:

    /** 
     Performs the specified move for the provided player and game. This function sends the move to the MGWU server. After
     sending is complete the callback is called on the target.
     */
    extern void performMoveForPlayerInGame(NSString *move, NSString *playerName, NSDictionary* game, id target, SEL callback);

    /**
     Calculates the winner of the two provided choices.
     0 = draw between both choices
     -1 = choice 1 wins
     +1 = choice 2 wins
     */
    extern NSInteger calculateWinnerOfRound(NSString *movePlayer1, NSString *movePlayer2);
    
If you find yourself adding complex code to some of your scenes in order to extract information from the MGWU SDK you should consider adding them as convenience functions to the `GameDataUtils` collection.
	