//
//  LobbyTableViewCell.m
//  SoapBoxTV
//
//  Created by HEENA RASTOGI on 9/12/15.
//  Copyright (c) 2015 HEENA RASTOGI. All rights reserved.
//

#import "LobbyTableViewCell.h"
#import "Room.h"

@interface LobbyTableViewCell()
@property (nonatomic, weak) IBOutlet UILabel *roomTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *roomSubTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *roomStartTime;
@property (nonatomic, weak) IBOutlet UIButton *roomStatusView;

@end

@implementation LobbyTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) updateCellWithRoomData:(Room*)room{
    self.roomTitleLabel.text = room.title;
    self.roomSubTitleLabel.text = room.subTitle;
    self.roomStatusView.layer.cornerRadius = 10.0;
    self.roomStatusView.layer.masksToBounds = YES;
}

@end
