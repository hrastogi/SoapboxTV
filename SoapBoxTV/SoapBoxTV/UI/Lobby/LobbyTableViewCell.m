//
//  LobbyTableViewCell.m
//  SoapBoxTV
//
//  Created by HEENA RASTOGI on 8/24/15.
//  Copyright (c) 2015 HEENA RASTOGI. All rights reserved.
//

#import "LobbyTableViewCell.h"
#import "Room.h"
@interface LobbyTableViewCell()
@property (nonatomic,weak) IBOutlet UILabel *roomTitle;
@end
@implementation LobbyTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) updateCellWuthRoomData:(Room*)room{
    self.roomTitle.text = room.title;
}

@end
