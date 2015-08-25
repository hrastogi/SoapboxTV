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

static NSString *lobbyCellNibName = @"LobbyTableViewCell";

@interface LobbyTableViewController ()
@property (nonatomic) NSArray *rooms;
@end

@implementation LobbyTableViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
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
    
    return cell;
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
