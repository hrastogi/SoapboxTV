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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationController.navigationBarHidden = NO;
    
    TWTRLogInButton *logInButton = [TWTRLogInButton buttonWithLogInCompletion:^(TWTRSession *session, NSError *error) {
        // play with Twitter session
        if (session)
        {
            // This session is then used to make Twitter API requests.
            NSLog(@"%@", [session userID]);
            NSLog(@"%@", [session userName]);
            NSLog(@"%@", [session authToken]);
            NSLog(@"%@", [session authTokenSecret]);
            
            
            NSDictionary *userInfo = @{@"room":@1,@"roomName":@"slug1",@"username": [session userName], @"userID": [session userID],@"authToken":[session authToken],@"authTokenSecret":[session authTokenSecret], @"platform":@"iOS"};
            
            // Push the Lobby View controller.
            //[self loadLobbyViewControllerWithInfo:userInfo];
            
            
            [SIOSocket socketWithHost: @"http://52.27.116.102:7273" response: ^(SIOSocket *socket) {
                NSLog(@"connected");
                self.socket = socket;
                
                __weak typeof(self) weakSelf = self;
                
                
                
                self.socket.onConnect = ^()
                {
                    weakSelf.socketIsConnected = YES;
                    // Broadcast new location
                    if (self.socketIsConnected)
                    {
                        [self.socket emit: @"register" args: @[userInfo]];
                    }
                    
                };
                
                [self.socket on: @"initiOSUserEmit" callback: ^(SIOParameterArray *args)
                 {
                     NSLog(@"%@ ARGS",args);
                     NSDictionary *dto = [args objectAtIndex:0];
                     
                     
                     //self.openTokToken = [dto valueForKey:@"opentok_user_token"];
                     //[self setupSession];
                     
                 }];
                
                [self.socket on: @"initSBRoomClientEmit" callback: ^(SIOParameterArray *args)
                 {
                     NSLog(@"%@ ARGS",args);
                     NSDictionary *dto = [args objectAtIndex:0];
                     
                     
                     //self.openTokToken = [dto valueForKey:@"opentok_user_token"];
                     //[self setupSession];
                     
                 }];
                
                
                
            }];
            
        }
        else
        {
            NSLog(@"Error: %@", [error localizedDescription]);
        }
    }];
    logInButton.center = self.view.center;
    [self.view addSubview:logInButton];
    
    [self.socket on: @"initiOSUserEmit" callback: ^(SIOParameterArray *args)
     {
         NSLog(@"%@ ARGS",args);
     }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loadLobbyViewControllerWithUserInfo:(UserModel*)userModel {
    
    
    LobbyTableViewController *lobbyVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"LobbyTableViewController"];
    self.navigationItem.title = @"";
    [self.navigationController pushViewController:lobbyVC animated:NO];
    
}
@end
