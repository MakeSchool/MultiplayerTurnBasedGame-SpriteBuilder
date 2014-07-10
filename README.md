MGWU Mutliplayer Template
=========================

This template should be used for turn based multiplayer games based off the mgwuSDK built using SpriteBuilder and Cocos2D. The game in the template is [Nim](http://education.jlab.org/nim/index.html).

The template takes care of all the menus, while the SDK takes care of all the server functionality. All you'll need to do is basic setup of the SDK, swap out the GameScene with your game, and customize the art, and you'll have built your own turn based multiplayer game!

Table of Contents
-----------------

    1. Understanding the mgwuSDK
    2. SDK Setup
    3. How to Plug in Your Game
    

1. Understanding the mgwuSDK
---------------------------
There are a few parts of the mgwuSDK you should become familiar with before you begin:

    a. Callbacks and Targets and Data
    b. The Game Object
    c. Getting the User's Data
    d. Making Moves

If you're interested in additional multiplayer features like chat, or general game features like analytics and crash reporting, take a look at the [full SDK documentation](https://s3.amazonaws.com/mgwu/mgwuSDK-instructions.html).

###a. Callbacks and Targets and Data

Normal methods return values immediately. For example:

<!--hfmd>.. sourcecode:: objective-c<hfmd-->

    int i = [self myMethod];
  
However, sometimes methods can't do this. So instead we use a callback. Callbacks work like this:

<!--hfmd>.. sourcecode:: objective-c<hfmd-->

    [self myMethodWithCallback:@selector(myOtherMethod:) onTarget:self];
  
So instead of returning a value immediately, the method will send the value to a method you choose. The target is the object on which the method is called (this will typically be self), while the callback is the name of the method to be called.

myOtherMethod will be declared as:

<!--hfmd>.. sourcecode:: objective-c<hfmd-->

    - (void) myOtherMethod:(id)returnedValue
    {
        //Do stuff with the returned value
    }
  
The returned value can be any object (typically NSDictionary or NSArray) depending on the method (we will specify the type in our methods).

When using a method in our SDK that uses callbacks, the call will typically look like:

<!--hfmd>.. sourcecode:: objective-c<hfmd-->

    [MGWU someSDKMethodWithParameter:param withSelector:@selector(yourMethod:) onTarget:self];
  
    - (void) yourMethod:(NSDictionary*)dict
    {
        //Do stuff!
    }

If for some reason the server request failed, the callback method will be passed a nil value, and typically the error will be printed in your console so you can correct the mistake.

When a dictionary is passed to a callback method, you also need to know what format the data is in inside the dictionary so you can work with it properly. In the tutorials we will explain it in this format:

<!--hfmd>::<hfmd-->

    NSString - @"String"
    NSNumber - @4
    NSArray - @[@"String1", @"String2", @"String3"]
    NSDictionary - @{@"Key1":@"Value1", @"Key2":@2, @"Key3":@"Value3"}

These can also be nested like so:

<!--hfmd>::<hfmd-->

    @{@"myArray":@[@1, @2, @3], @"myString":@"string"}

This corresponds to the new [literal syntax in Objective-C](http://cocoaheads.tumblr.com/post/17757846453/objective-c-literals-for-nsdictionary-nsarray-and)

###b. The Game Object

The Game object represents a single game between two players. It is a dictionary with this format:

<!--hfmd>::<hfmd-->

    @{
        @"gameid" : @8,
        @"players" : @[
            @"desaiashu",
            @"shea_sidau"
        ],
        @"turn" : @"shea_sidau"
        @"gamestate" : @"inprogress",
        @"gamedata" : @{
            @"dictionary containing the current gamedata" : @"for example, in chess this would have the locations of all the pieces on the board"
        },
        @"movecount" : @5,
        @"moves" = @[
             @{
                @"dictionary containing 3 moves ago" = @"for example, in chess this could have info describing White Queen to E5",
                @"time" : @1349907651
            },
            @{
                @"dictionary containing 2 moves ago" = @"for example, in chess this could have info describing Black Queen to E5",
                @"time" : @1349916403
            },
            @{
                @"dictionary containing the last move" = @"for example, in chess this could have info describing Black Rook to E5",
                @"time" : @1349916412
            }
        ],
        @"newmessages" : @0,
        @"datebegan" : @1349907651,
        @"dateplayed" : @1349916492,
    }

**(All timestamps are in [epoch time](https://gist.github.com/4507119))**

The gamedata and moves are defined by you.

@"newmessages" is the number of unread messages in the chat for each game. 

@"turn" tells you whose turn it is, currently games are required to be strictly turn based (contact me at ashu@makegameswith.us if you have a game that needs a different format).

There are three states a game can be in:

- @"started" when you a new game has just been begun
- @"inprogress" when a game is in progress
- @"ended" a game that is completed

###c. Getting the User's Data

The SDK method **getMyInfo** retrieves the user, along with their list of friends and their list of current and past games.

Call **getMyInfo** like this:

<!--hfmd>.. sourcecode:: objective-c<hfmd-->

    [MGWU getMyInfoWithCallback:@selector(gotUserInfo:) onTarget:self];
    
The callback will be passed an NSDictionary with this format:

    @{
        @"user" : @{
            @"username" : @"shea_sidau";
            @"name" : @"Shea Sidau";
            @"wins" : @3;
            @"losses" : @4;
            @"rankpoints" : @0;
            @"lastplayed" : @1350159215;
        },
        @"friends" : @[
            @{
                @"username" : @"desaiashu";
                @"name" : @"Ashu Desai";
                @"wins" : @4;
                @"losses" : @3;
                @"rankpoints" : @0;
                @"lastplayed" : @1350159615;
            },
        ... ],
        @"games" : @[game1, game2, game3]
    }

**game1, game2 and game3 will be dictionaries of the format described in the Game Object section.** The list of friends includes all facebook friends who also play the game. 

If you want to delete all games on the server during testing, you can use the url: [https://dev.makegameswith.us/cleargames](https://dev.makegameswith.us/cleargames)

###d. Making Moves

The SDK method **move** is used to create a new game or make a move in an existing game.

Call **move** like this:

<!--hfmd>.. sourcecode:: objective-c<hfmd-->

    [MGWU move:move withMoveNumber:moveNumber forGame:gameID withGameState:gameState withGameData:gameData againstPlayer:opponent withPushNotificationMessage:pushMessage withCallback:@selector(moveCompleted:) onTarget:self];
    
The callback will be passed the new updated game object.

Depending on the state of the game, the parameters you pass to the move method will be as follows:

- **Beginning a game:**
    - move (NSDictionary) should be a dictionary with info about the move that was just performed (in chess this would be along the lines of Queen to E5)
    - moveNumber (int) should be 1
    - gameID (int) should be 0
    - gameState (NSString) should be @"started"
    - gameData (NSDictionary) should be a dictionary with info about the game (in chess this would be where the pieces on the board are)
    - friend (NSString) should be the username of the player you are starting the game against
    - pushMessage (NSString) should be whatever you would like to display to the other user in a push notification about the move (like, @"username invited you to a game")
  
- **Making a move in the game:**
    - move (NSDictionary) should be a dictionary with info about the move that was just performed (in chess this would be along the lines of Queen to E5)
    - moveNumber (int) should be 1 + the move number of the game retrieved from the list of games
    - gameID (int) should be the gameId retrieved from the list of games
    - gameState (NSString) should be @"inprogress"
    - gameData (NSDictionary) should be a dictionary with info about the game (in chess this would be where the pieces on the board are)
    - opponent (NSString) should be the username of the player you are playing against, retrieved from the list of games
    - pushMessage (NSString) should be whatever you would like to display to the other user in a push notification about the move (like, @"it is your turn against username")

- **Making a move to end a game (checkmate condition):**
    * move (NSDictionary) should be a dictionary with any info about the move that was just performed (in chess this would be along the lines of Queen to E5)
    * moveNumber (int) should be 1 + the move number of the game retrieved from the list of games
    * gameID (int) should be the gameId retrieved from the list of games
    * gameState (NSString) should be @"ended"
    * gameData (NSDictionary) should be a dictionary with info about the game (in chess this would be where the pieces on the board are)
    * opponent (NSString) should be the username of the player you are playing against, retrieved from the list of games
    * pushMessage (NSString) should be whatever you would like to display to the other user in a push notification about the move (like, @"you lost to username")

**IMPORTANT NOTE: Do not use a period or dollar sign in the keys of any dictionaries you create for move or gamedata, the data will not be successfully stored on the server.** Here are examples of what not to do:

<!--hfmd>::<hfmd-->

    @{@"my.key":@"myValue"}
    @{@"$myKey":@"myValue"}
    @{@"myKey":@{@"my.key":@"myValue"}}
    
Also, make sure you don't add any uninitialized values to dictionaries, otherwise you will get lots of unpredictable errors.

If your game has a winner and loser, you can have the server keep track of total wins and losses. You can also define ranking points (typically a rating / ELO system). To define the winner for a game you want to include the key @"winner" in gamedata dictionary when the game is ending, for ranking points include @"rankpoints" like so:

<!--hfmd>::<hfmd-->

    @"winner":@"usernameOfWinner",
    @"rankpoints":@{
        @"player1":@50,
        @"player2":@-50
    }
    
Passing in negative numbers in rankpoints will reduce a players rankpoints.

2. SDK Setup
------------

When you start developing your own game you need to make some changes to make sure our servers + facebook treat it as a new app.

###Enabling SDK Features

First create your app on our server at this url: [https://dev.makegameswith.us/createapp](https://dev.makegameswith.us/createapp)

In the left bar of Xcode, click on your project, then navigate to "info" (see screenshot below). Change the Bundle identifier to "com.xxx.xxx" to match the app you created on the server. **Delete the project from any simulator / device you've been testing on, you'll also need to delete any other apps which use the new bundle identifier (to ensure this, in the simulator top bar you can go to iOS Simulator -> Reset Content and Settings...)**. On the top bar of Xcode go to Product -> Clean. This should ensure you are using the new bundle identifier.

![image](https://s3.amazonaws.com/mgwu-misc/mgwuSDK+Tutorial/bundle.png)

Now open the file AppDelegate.m. In the method **application: didFinishLaunchingWithOptions:** find the line:

<!--hfmd>.. sourcecode:: objective-c<hfmd-->

    [MGWU loadMGWU:@"secretkey"];

Replace 'secretkey' with the secret key you used when you created your app on the server. 

###Enabling Facebook Features

Facebook integration is set up for you in this template, but you'll have to create a new Facebook app. Follow these steps (here's a link to the [Facebook App Dashboard](https://developers.facebook.com/apps/), you'll need to register as a developer):

![image](https://s3.amazonaws.com/mgwu-misc/mgwuSDK+Tutorial/fb1.png)
![image](https://s3.amazonaws.com/mgwu-misc/mgwuSDK+Tutorial/fb2.png)
![image](https://s3.amazonaws.com/mgwu-misc/mgwuSDK+Tutorial/fb3.png)


3. How to Plug in Your Game
---------------------------

Generally it's best to build the basic components of the game in a different project, this way you don't have to go through all the menus when you want to test things. Then once you've tested things to mostly work the way you want with dummy data, work on plugging this back into the template.

Once your game is mostly working in a different project, you'll want to use it to replace the GameScene. When the GameScene is initialized, it's handed a game object (as described above). In the **reload** method, the GameScene updates the user interface based on the current state of the game. When a user takes an action, the **submitMove** method is called, which calls the **move** method of the SDK is called.

When you plug in your game and replace the GameScene, you need to ensure that your game properly updates it's interface based on the current game state, allows the user to play the game, and sends the move info back up to the server. If you're unsure how to do this, review the SDK info above and review the code in GameScene.

##Structure of the Template

###MainScene
Displays a list of all current games, divided into three categories:

- Games where it's the player's turn
- Games where it's the opponent's turn
- Completed games

Allows to "Play now" which will either continue an existing game or will start a game against a random player.

###FriendListScene
This scene lists all Facebook players who are also playing the game. From where a player can start games against his friends. An "invite Friends" button allows players to invite Facebook friends who aren't playing the game yet.

###GameScene
This scene is the actual game, you need to replace it!

###UserInfo
UserInfo is a singleton that calles the **getMyInfo** method of the SDK and stores the user info it receives.
