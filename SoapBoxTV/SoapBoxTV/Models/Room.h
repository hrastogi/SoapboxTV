//
//  RoomModel.h
//  SoapBoxTV
//
//  Created by HEENA RASTOGI on 8/22/15.
//  Copyright (c) 2015 HEENA RASTOGI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Room : NSObject
@property (nonatomic) NSInteger roomId;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *subTitle;
@property (nonatomic) NSString *hashTag;
@property (nonatomic) NSString *slug;
@property (nonatomic) NSString *presenter;
@property (nonatomic) NSString *startTime;
@property (nonatomic) NSString *openTokSessionId;

@end
