//
//  ViewController.m
//  SoapBoxTV
//
//  Created by HEENA RASTOGI on 8/2/15.
//  Copyright (c) 2015 HEENA RASTOGI. All rights reserved.
//

#import "LoginViewController.h"
#import "LobbyTableViewController.h"
#import "UserModel.h"

#import <SIOSocket/SIOSocket.h>
#import <TwitterKit/TwitterKit.h>
@interface LoginViewController ()
@property (nonatomic) SIOSocket *socket;
@property (nonatomic,assign) BOOL socketIsConnected;
@end

@implementation LoginViewController
#pragma mark - View Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationController.navigationBarHidden = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI Setup
-(void) setUpTwitterButton {
    TWTRLogInButton *logInButton = [TWTRLogInButton buttonWithLogInCompletion:^(TWTRSession *session, NSError *error) {
        // play with Twitter session
        if (session)
        {
            
            // Create User Model
            UserModel *userInfo = [[UserModel alloc] init];
            userInfo.twitterUserID = [session userID];
            userInfo.twitterUserName = [session userName];
            userInfo.twitterAuthToken = [session authToken];
            userInfo.twitterAuthTokenSecret = [session authTokenSecret];
            
            // Push the Lobby View controller.
            [self loadLobbyViewControllerWithUserInfo:userInfo];
            
        }
        else
        {
            NSLog(@"Unable to connect to Twiiter");
        }
    }];
    logInButton.center = self.view.center;
    [self.view addSubview:logInButton];
}

#pragma mark - User Actions
-(void)loadLobbyViewControllerWithUserInfo:(UserModel*)userInfo {
    
    
    LobbyTableViewController *lobbyVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"LobbyTableViewController"];
    self.navigationItem.title = @"";
    lobbyVC.userInfo = userInfo;
    [self.navigationController pushViewController:lobbyVC animated:NO];
    
}
@end
