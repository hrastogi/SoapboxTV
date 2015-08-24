//
//  RoomStore.h
//  SoapBoxTV
//
//  Created by HEENA RASTOGI on 8/23/15.
//  Copyright (c) 2015 HEENA RASTOGI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
typedef void (^SBCompletionBlock)(NSError *error);

@interface RoomStore : NSObject
@property (nonatomic) NSArray *rooms;
+(RoomStore*) sharedInstance;
-(void)fetchLobbyDataWithCallback:(SBCompletionBlock)callback;


@end
