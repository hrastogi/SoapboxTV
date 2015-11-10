//
//  RoomViewController.h
//  SoapBoxTV
//
//  Created by HEENA RASTOGI on 8/2/15.
//  Copyright (c) 2015 HEENA RASTOGI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Opentok/Opentok.h>
#import <QuartzCore/QuartzCore.h>

@class UserModel,Room;
@interface RoomViewController : UIViewController <OTSessionDelegate, OTPublisherDelegate>
@property (nonatomic) UserModel *userInfo;
@property (nonatomic) Room *roomInfo;


@end
