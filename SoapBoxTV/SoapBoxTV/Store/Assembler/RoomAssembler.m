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
    NSArray *roomsArray = [results objectForKey:@"soapbox_rooms"];
    NSMutableArray *tempArray =[NSMutableArray array];
    for(NSDictionary *dto in roomsArray){
        [tempArray addObject:[self createRoomFromDictionary:dto]];
    }
    
    
    return [NSArray arrayWithArray:tempArray];
}

-(Room*)createRoomFromDictionary:(NSDictionary*)dto{
    Room *room = [[Room alloc] init];
    room.roomId = [(NSString*)[dto valueForKey:@"room_id"] integerValue];
    room.title = [dto valueForKey:@"room_title"];
    room.subTitle = [dto valueForKey:@"room_sub_title"];
    room.startTime = [dto valueForKey:@"room_start_time"];
    
    
    return room;
}
@end
