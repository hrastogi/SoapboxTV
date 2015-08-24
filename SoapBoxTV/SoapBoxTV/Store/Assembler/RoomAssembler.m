//
//  RoomAssembler.m
//  SoapBoxTV
//
//  Created by HEENA RASTOGI on 8/23/15.
//  Copyright (c) 2015 HEENA RASTOGI. All rights reserved.
//

#import "RoomAssembler.h"
#import "Room.h"

@implementation RoomAssembler
+(RoomAssembler*)sharedInstance
{
    static dispatch_once_t token;
    static  RoomAssembler *sharedInstance = nil;
    dispatch_once(&token, ^{
        sharedInstance = [[RoomAssembler alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Assembler
-(NSArray*)createRoomsFromJsonResponse:(NSDictionary*)results{
    return [NSArray array];
}

-(Room*)createRoomFromDictionary:(NSDictionary*)dto{
}
@end
