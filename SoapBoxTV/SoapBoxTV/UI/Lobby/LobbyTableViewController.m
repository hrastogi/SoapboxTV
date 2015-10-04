//
//  LobbyTableViewController.m
//  SoapBoxTV
//
//  Created by HEENA RASTOGI on 8/23/15.
//  Copyright (c) 2015 HEENA RASTOGI. All rights reserved.
//
#import "RoomStore.h"
#import "LobbyTableViewController.h"
#import "LobbyTableViewCell.h"
#import "RoomViewController.h"
#import "UserModel.h"

static NSString *lobbyCellNibName = @"LobbyTableViewCell";

@interface LobbyTableViewController ()
@property (nonatomic) NSArray *rooms;

@end

@implementation LobbyTableViewController

#pragma mark - View Hierarchy
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set up UI
    self.navigationItem.hidesBackButton = YES;
    
    // Register nib name for table vie wcell
    [self.tableView registerNib:[UINib nibWithNibName:lobbyCellNibName bundle:nil] forCellReuseIdentifier:lobbyCellNibName];
    RoomStore *roomStore = [RoomStore sharedInstance];
    [roomStore fetchLobbyDataWithCallback:^(NSError* error){
        self.rooms = roomStore.rooms;
        [self.tableView reloadData];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.rooms.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 200.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LobbyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:lobbyCellNibName forIndexPath:indexPath];
    [cell updateCellWithRoomData:self.rooms[indexPath.row]];
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    RoomViewController *roomVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"RoomViewController"];
    roomVC.userInfo = self.userInfo;
    roomVC.roomInfo = [self.rooms objectAtIndex:indexPath.row];
    self.navigationItem.title = @"";
    [self.navigationController pushViewController:roomVC animated:YES];
    
    
}

@end
