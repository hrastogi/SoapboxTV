//
//  ViewController.m
//  SoapBoxTV
//
//  Created by HEENA RASTOGI on 8/2/15.
//  Copyright (c) 2015 HEENA RASTOGI. All rights reserved.
//

#import "LoginViewController.h"
#import "LobbyTableViewController.h"
#import <TwitterKit/TwitterKit.h>
@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    TWTRLogInButton *logInButton = [TWTRLogInButton buttonWithLogInCompletion:^(TWTRSession *session, NSError *error) {
        // play with Twitter session
        if (session)
        {
            // This session is then used to make Twitter API requests.
            NSLog(@"%@", [session userID]);
            NSLog(@"%@", [session userName]);
            NSLog(@"%@", [session authToken]);
            NSLog(@"%@", [session authTokenSecret]);
            
            // Push the Lobby View controller.
            [self loadLobbyViewController];
            
        }
        else
        {
            NSLog(@"Error: %@", [error localizedDescription]);
        }
    }];
    logInButton.center = self.view.center;
    [self.view addSubview:logInButton];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loadLobbyViewController{
    
    LobbyTableViewController *lobbyVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"LobbyTableViewController"];
    [self.navigationController pushViewController:lobbyVC animated:YES];
    
}
@end
