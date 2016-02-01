//
//  RoomStore.m
//  SoapBoxTV
//
//  Created by HEENA RASTOGI on 8/23/15.
//  Copyright (c) 2015 HEENA RASTOGI. All rights reserved.
//

#import "AFNetworking.h"
#import "RoomStore.h"
#import "RoomAssembler.h"
static NSString * const BaseURLString = @"https://soapbox.tv/api/rooms";
@implementation RoomStore
+(RoomStore*)sharedInstance
{
    static dispatch_once_t token;
    static  RoomStore *sharedInstance = nil;
    dispatch_once(&token, ^{
        sharedInstance = [[RoomStore alloc] init];
    });
    return sharedInstance;
}

-(void)fetchLobbyDataWithCallback:(SBCompletionBlock)callback{
    NSURL *url = [NSURL URLWithString:BaseURLString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSLog(@"Data Retrieved");
        [self didLoadData:responseObject withCallback:callback];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        }];
    [operation start];
}

-(void)didLoadData:(id)responseObject withCallback:(SBCompletionBlock)callback{
    self.rooms = [[RoomAssembler sharedInstance] createRoomsFromJsonResponse:responseObject];
    callback(nil);
}
@end
