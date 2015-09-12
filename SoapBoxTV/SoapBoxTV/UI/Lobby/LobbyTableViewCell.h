//
//  LobbyTableViewCell.h
//  SoapBoxTV
//
//  Created by HEENA RASTOGI on 9/12/15.
//  Copyright (c) 2015 HEENA RASTOGI. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Room;
@interface LobbyTableViewCell : UITableViewCell
- (void) updateCellWithRoomData:(Room*)room;
@end
