//
//  UserModel.h
//  SoapBoxTV
//
//  Created by HEENA RASTOGI on 10/1/15.
//  Copyright (c) 2015 HEENA RASTOGI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserModel : NSObject
@property (nonatomic) NSString *twitterUserID;
@property (nonatomic) NSString *twitterUserName;
@property (nonatomic) NSString *twitterAuthToken;
@property (nonatomic) NSString *twitterAuthTokeenSecret;
@end
