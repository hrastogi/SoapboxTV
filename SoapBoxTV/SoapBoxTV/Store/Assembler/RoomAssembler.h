//
//  RoomAssembler.h
//  SoapBoxTV
//
//  Created by HEENA RASTOGI on 8/23/15.
//  Copyright (c) 2015 HEENA RASTOGI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RoomAssembler : NSObject
+(RoomAssembler*) sharedInstance;
-(NSArray*)createRoomsFromJsonResponse:(NSArray*)results;
@end
