//
//  RoomViewController.m
//  Hello-World
//
//  Copyright (c) 2013 TokBox, Inc. All rights reserved.
//

#import "RoomViewController.h"
#import "UserModel.h"
#import <SIOSocket/SIOSocket.h>
#import <OpenTok/OpenTok.h>
#import "Room.h"

#define PUBLISHER_BAR_HEIGHT 50.0f
#define SUBSCRIBER_BAR_HEIGHT 66.0f
#define ARCHIVE_BAR_HEIGHT 35.0f
#define PUBLISHER_ARCHIVE_CONTAINER_HEIGHT 85.0f

#define PUBLISHER_PREVIEW_HEIGHT 87.0f
#define PUBLISHER_PREVIEW_WIDTH 113.0f

#define OVERLAY_HIDE_TIME 7.0f
static NSString *soapBoxServerUrl = @"http://52.27.116.102:7273";


@interface RoomViewController ()<OTSessionDelegate, OTSubscriberKitDelegate,OTPublisherDelegate>{


	NSMutableArray *allConnectionsIds;
	NSMutableArray *backgroundConnectedStreams;

	OTSession *_session;
	OTPublisher *_publisher;
	OTSubscriber *_currentSubscriber;
	CGPoint _startPosition;

	BOOL initialized;
	int _currentSubscriberIndex;
}

@property (nonatomic,weak) IBOutlet UIView *publisherPlaceholderView;
@property (nonatomic,weak) IBOutlet UIView *subscriberPlaceholderView;
@property (nonatomic) SIOSocket *socket;
@property (nonatomic,assign) BOOL socketIsConnected;
@property (nonatomic) NSString *openTokToken;
@property (nonatomic) NSArray *roomStreamsArray;
@property (nonatomic) NSString *streamId;
@property (nonatomic) NSMutableDictionary *allStreams;
@property (nonatomic) NSMutableDictionary *allSubscribers;

-(IBAction)cameraButtonTapped:(id)sender;

@end

@implementation RoomViewController
static NSString* const kApiKey = @"45194852";
// Replace with your generated session ID
static NSString* const kSessionId = @"2_MX40NTE5NDg1Mn5-MTQzMjI0NDk4MTk3OX45QnVLbVNKTnFPbVp5UVdUK3lqNXlHSW5-fg";

#pragma mark - View lifecycle
- (void)viewDidLoad
{
	[super viewDidLoad];

	self.allStreams = [NSMutableDictionary dictionary];
	self.allSubscribers = [NSMutableDictionary dictionary];
	[self connectToSoapBoxServer];
}


- (void)setupSession
{
	if(self.openTokToken) {
		//setup one time session
		if (_session) {
			_session = nil;
		}

		_session = [[OTSession alloc] initWithApiKey:kApiKey
		            sessionId:kSessionId
		            delegate:self];
		[_session connectWithToken:self.openTokToken error:nil];

	}
}

- (void)setupPublisher
{
	// create one time publisher and style publisher
	_publisher = [[OTPublisher alloc]
	              initWithDelegate:self
	              name:[[UIDevice currentDevice] name]];

	[self.view addSubview:_publisher.view];
	_publisher.view.userInteractionEnabled = YES;

}


#pragma mark - OpenTok Session
- (void)session:(OTSession *)session
        connectionDestroyed:(OTConnection *)connection
{
	NSLog(@"connectionDestroyed: %@", connection);
}

- (void)session:(OTSession *)session
        connectionCreated:(OTConnection *)connection
{
	NSLog(@"addConnection: %@", connection);
}

- (void)sessionDidConnect:(OTSession *)session
{


}



- (void)sessionDidDisconnect:(OTSession *)session
{



}

- (void)    session:(OTSession *)session
        streamDestroyed:(OTStream *)stream
{
	NSLog(@"streamDestroyed %@", stream.connection.connectionId);



}



- (void)subscriberDidConnectToStream:(OTSubscriberKit *)subscriber
{
	NSLog(@"subscriberDidConnectToStream %@", subscriber.stream.name);
	[self requestToHopOnStage:subscriber.stream.name];
}

- (void)publisher:(OTPublisherKit *)publisher
        streamCreated:(OTStream *)stream
{
	NSLog(@"Publisher stream created");
	[self requestToHopOnStage:stream.streamId];
}



- (void)session:(OTSession*)session streamCreated:(OTStream*)stream
{
	NSLog(@"session streamCreated (%@)", stream.streamId);

	// See the declaration of subscribeToSelf above.
	if ([stream.connection.connectionId isEqualToString: session.connection.connectionId]) {
		// This is my own stream
	} else {
		// This is a stream from another client.
		// Get the stream and subscribe to the stream
		[self.allStreams setObject:stream forKey:stream.streamId];
		[self createSubscriber: stream];
	}
}

- (void)session:(OTSession *)session didFailWithError:(OTError *)error
{
	NSLog(@"sessionDidFail");

}

- (void)publisher:(OTPublisher *)publisher didFailWithError:(OTError *)error
{
	NSLog(@"publisher didFailWithError %@", error);

}

- (void)subscriber:(OTSubscriber *)subscriber didFailWithError:(OTError *)error
{
	NSLog(@"subscriber could not connect to stream");
}

#pragma mark - Helper Methods


- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark - User Actions
-(IBAction)cameraButtonTapped:(id)sender {
	[self createPublisher];


}

-(void)createPublisher {
	_publisher = [[OTPublisher alloc]
	              initWithDelegate:self
	              name:[[UIDevice currentDevice] name]];

	self.view.backgroundColor = [UIColor blackColor];
	_publisher.view.frame = CGRectMake(0, 0, self.publisherPlaceholderView.frame.size.width, self.publisherPlaceholderView.frame.size.height);
	[self.publisherPlaceholderView addSubview:_publisher.view];
	_publisher.view.userInteractionEnabled = YES;

	OTError *error = nil;
	[_session publish:_publisher error:&error];
//	if (error)
//	{
//		[self showAlert:[error localizedDescription]];
//	}

}

- (void)createSubscriber:(OTStream *)stream
{
	// If subscriber exists then do not create new subscriber.
	OTSubscriber *existingSubscriber = [self.allSubscribers objectForKey:stream.streamId];

	// If subscriber does not exists then create new subscriber
	if(!existingSubscriber) {
		// create subscriber
		OTSubscriber *subscriber = [[OTSubscriber alloc]
		                            initWithStream:stream delegate:self];


		[self.allSubscribers setObject:subscriber forKey:stream.streamId];

	}

}


#pragma mark - Connect to soapbox server
-(void)connectToSoapBoxServer {
	NSDictionary *userInfoDto = @{@"roomName":@"slug1",@"room":@"slug1",@"username": self.userInfo.twitterUserName, @"userID": self.userInfo.twitterUserID,@"authToken":self.userInfo.twitterAuthToken,@"authTokenSecret":self.userInfo.twitterAuthTokenSecret, @"platform":@"iOS"};

	[SIOSocket socketWithHost: soapBoxServerUrl response: ^(SIOSocket *socket)
	 {
	         self.socket = socket;
	         __weak typeof(self) weakSelf = self;
	         self.socket.onConnect = ^()
	         {
	                 weakSelf.socketIsConnected = YES;
	                 // Broadcast new location
	                 [weakSelf.socket emit: @"register" args: @[userInfoDto]];
		 };

	         [self.socket on: @"initiOSUserEmit" callback: ^(SIOParameterArray *args)
	          {
	                  NSLog(@"initiOSUserEmit : %@",args);
	                  NSDictionary *dto =args[0];
	                  self.openTokToken = [dto valueForKey:@"opentok_user_token"];

	                  [self.socket on: @"initSBRoomClientEmit" callback: ^(SIOParameterArray *args)
	                   {
	                           NSLog(@"initSBRoomClientEmit : %@ ",args);
	                           NSDictionary *roomInfoDto = args[0];
	                           NSDictionary *roomStreams = roomInfoDto[@"roomStreams"];
	                           NSString *streamId = roomStreams[@"videoStreamSlotA"];

	                           [self setupSession];
	                           // Get all the stream ids array
	                           self.roomStreamsArray = [args valueForKey:@"roomStreams"];

			   }];

	                  [self.socket on: @"makeCamSlotLiveClientEmit" callback: ^(SIOParameterArray *args)
	                   {
	                           NSLog(@"makeCamSlotLiveClientEmit : %@ ",args);
	                           NSDictionary *camSlotInfoDto = args[0];
	                           NSString *streamId = [camSlotInfoDto objectForKey:@"streamID"];
	                           [self makeSubscriberLive:streamId];



			   }];




		  }];

	 }];

}

-(void)requestToHopOnStage:(NSString*)streamId {



	if(self.socketIsConnected) {
		[self.socket emit: @"requestToHopStageEmit" args: @[streamId]];
	}
}

-(void) makeSubscriberLive:(NSString*)streamId {
	OTError *error = nil;
	OTSubscriber *subscriber = [self.allSubscribers objectForKey:streamId];
	[_session subscribe:subscriber error:&error];
	dispatch_async(dispatch_get_main_queue(), ^{
		// code here
		subscriber.view.frame = CGRectMake(0, 0, self.subscriberPlaceholderView.frame.size.width, self.subscriberPlaceholderView.frame.size.height);
		[self.subscriberPlaceholderView addSubview:subscriber.view];
	});



	if (error)
	{
		NSLog(@"error %@",error.localizedDescription);
	}
}
@end