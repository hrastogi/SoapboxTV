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


#define APP_IN_FULL_SCREEN @"appInFullScreenMode"
#define PUBLISHER_BAR_HEIGHT 50.0f
#define SUBSCRIBER_BAR_HEIGHT 66.0f
#define ARCHIVE_BAR_HEIGHT 35.0f
#define PUBLISHER_ARCHIVE_CONTAINER_HEIGHT 85.0f

#define PUBLISHER_PREVIEW_HEIGHT 87.0f
#define PUBLISHER_PREVIEW_WIDTH 113.0f

#define OVERLAY_HIDE_TIME 7.0f
static NSString *soapBoxServerUrl = @"http://52.27.116.102:7273";

// otherwise no upside down rotation
@interface UINavigationController (RotationAll)
- (NSUInteger)supportedInterfaceOrientations;
@end


@implementation UINavigationController (RotationAll)
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

@end

@interface RoomViewController ()<OTSessionDelegate, OTSubscriberKitDelegate,OTPublisherDelegate>{
    NSMutableDictionary *allStreams;
    NSMutableDictionary *allSubscribers;
    NSMutableArray *allConnectionsIds;
    NSMutableArray *backgroundConnectedStreams;
    
    OTSession *_session;
    OTPublisher *_publisher;
    OTSubscriber *_currentSubscriber;
    CGPoint _startPosition;
    
    BOOL initialized;
    int _currentSubscriberIndex;
}

@property (nonatomic) SIOSocket *socket;
@property (nonatomic,assign) BOOL socketIsConnected;
@property (nonatomic) NSString *openTokToken;
@property (nonatomic) NSArray *roomStreamsArray;
@property (nonatomic) NSString *streamId;

@end

@implementation RoomViewController

// *** Fill the following variables using your own Project info  ***
// ***          https://dashboard.tokbox.com/projects            ***
// Replace with your OpenTok API key
static NSString* const kApiKey = @"45194852";
// Replace with your generated session ID
static NSString* const kSessionId = @"2_MX40NTE5NDg1Mn5-MTQzMjI0NDk4MTk3OX45QnVLbVNKTnFPbVp5UVdUK3lqNXlHSW5-fg";

#pragma mark - View lifecycle


@synthesize videoContainerView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.archiveOverlay.hidden = YES;
    
    
    [self.endCallButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    
    self.archiveStatusImgView2.hidden = YES;
    [self adjustArchiveStatusImgView];
    
    // application background/foreground monitoring for publish/subscribe video
    // toggling
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(enteringBackgroundMode:)
     name:UIApplicationWillResignActiveNotification
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(leavingBackgroundMode:)
     name:UIApplicationDidBecomeActiveNotification
     object:nil];
    
    [self setUpUIForOpenTok];
    [self connectToSoapBoxServer];
}


-(void)setUpUIForOpenTok
{
    self.videoContainerView.bounces = NO;
    
    [self.view sendSubviewToBack:self.videoContainerView];
    self.endCallButton.titleLabel.lineBreakMode = NSLineBreakByCharWrapping;
    self.endCallButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    // Default no full screen
    [self.topOverlayView.layer setValue:[NSNumber numberWithBool:NO]
                                 forKey:APP_IN_FULL_SCREEN];
    
    
    self.audioPubUnpubButton.autoresizingMask  =
    UIViewAutoresizingFlexibleLeftMargin
    | UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleTopMargin |
    UIViewAutoresizingFlexibleBottomMargin;
    
    
    // Add right side border to camera toggle button
    CALayer *rightBorder = [CALayer layer];
    rightBorder.borderColor = [UIColor whiteColor].CGColor;
    rightBorder.borderWidth = 1;
    rightBorder.frame =
    CGRectMake(-1,
               -1,
               CGRectGetWidth(self.cameraToggleButton.frame),
               CGRectGetHeight(self.cameraToggleButton.frame) + 2);
    self.cameraToggleButton.clipsToBounds = YES;
    [self.cameraToggleButton.layer addSublayer:rightBorder];
    
    // Left side border to audio publish/unpublish button
    CALayer *leftBorder = [CALayer layer];
    leftBorder.borderColor = [UIColor whiteColor].CGColor;
    leftBorder.borderWidth = 1;
    leftBorder.frame =
    CGRectMake(-1,
               -1,
               CGRectGetWidth(self.audioPubUnpubButton.frame) + 5,
               CGRectGetHeight(self.audioPubUnpubButton.frame) + 2);
    [self.audioPubUnpubButton.layer addSublayer:leftBorder];
    
    // configure video container view
    self.videoContainerView.scrollEnabled = YES;
    videoContainerView.pagingEnabled = YES;
    videoContainerView.delegate = self;
    videoContainerView.showsHorizontalScrollIndicator = NO;
    videoContainerView.showsVerticalScrollIndicator = YES;
    videoContainerView.bounces = NO;
    videoContainerView.alwaysBounceHorizontal = NO;
    
    
    // initialize constants
    allStreams = [[NSMutableDictionary alloc] init];
    allSubscribers = [[NSMutableDictionary alloc] init];
    allConnectionsIds = [[NSMutableArray alloc] init];
    backgroundConnectedStreams = [[NSMutableArray alloc] init];
    
    // set up look of the page
    [self.navigationController setNavigationBarHidden:YES];
    [self setNeedsStatusBarAppearanceUpdate];
    
    
    // listen to taps around the screen, and hide/show overlay views
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(viewTapped:)];
    tgr.delegate = self;
    [self.view addGestureRecognizer:tgr];
    
    
}


-(void)adjustArchiveStatusImgView
{
    CGPoint pointInViewCoords = [self.archiveOverlay
                                 convertPoint:self.archiveStatusImgView.frame.origin
                                 toView:self.view];
    
    CGRect frame = self.archiveStatusImgView2.frame;
    frame.origin = pointInViewCoords;
    self.archiveStatusImgView2.frame = frame;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)viewTapped:(UITapGestureRecognizer *)tgr
{
    BOOL isInFullScreen = [[[self topOverlayView].layer
                            valueForKey:APP_IN_FULL_SCREEN] boolValue];
    
    UIInterfaceOrientation orientation =
    [[UIApplication sharedApplication] statusBarOrientation];
    
    if (isInFullScreen) {
        
        if (!self.archiveStatusImgView2.isAnimating)
            self.archiveOverlay.hidden = YES;
        
        [self.topOverlayView.layer setValue:[NSNumber numberWithBool:NO]
                                     forKey:APP_IN_FULL_SCREEN];
        
        // Show/Adjust top, bottom, archive, publisher and video container
        // views according to the orientation
        if (orientation == UIInterfaceOrientationPortrait ||
            orientation == UIInterfaceOrientationPortraitUpsideDown) {
            
            
            [UIView animateWithDuration:0.5 animations:^{
                
                CGRect frame = _currentSubscriber.view.frame;
                frame.size.height =
                self.videoContainerView.frame.size.height;
                _currentSubscriber.view.frame = frame;
                
                frame = self.topOverlayView.frame;
                frame.origin.y += frame.size.height;
                self.topOverlayView.frame = frame;
                
                frame = self.archiveOverlay.superview.frame;
                frame.origin.y -= frame.size.height;
                self.archiveOverlay.superview.frame = frame;
                
                [_publisher.view setFrame:
                 CGRectMake(8,
                            self.view.frame.size.height -
                            (PUBLISHER_BAR_HEIGHT +
                             (self.archiveOverlay.hidden ? 0 :
                              ARCHIVE_BAR_HEIGHT)
                             + 8 + PUBLISHER_PREVIEW_HEIGHT),
                            PUBLISHER_PREVIEW_WIDTH,
                            PUBLISHER_PREVIEW_HEIGHT)];
            } completion:^(BOOL finished) {
                
            }];
        }
        else
        {
            
            [UIView animateWithDuration:0.5 animations:^{
                
                CGRect frame = _currentSubscriber.view.frame;
                frame.size.width =
                self.videoContainerView.frame.size.width;
                _currentSubscriber.view.frame = frame;
                
                frame = self.topOverlayView.frame;
                frame.origin.y += frame.size.height;
                self.topOverlayView.frame = frame;
                
                frame = self.bottomOverlayView.frame;
                if (orientation == UIInterfaceOrientationLandscapeRight) {
			                 frame.origin.x -= frame.size.width;
                } else {
			                 frame.origin.x += frame.size.width;
                }
                
                self.bottomOverlayView.frame = frame;
                
                frame = self.archiveOverlay.frame;
                frame.origin.y -= frame.size.height;
                self.archiveOverlay.frame = frame;
                
                if (orientation == UIInterfaceOrientationLandscapeRight) {
			                 [_publisher.view setFrame:
                              CGRectMake(8,
                                         self.view.frame.size.height -
                                         ((self.archiveOverlay.hidden ? 0 :
                                           ARCHIVE_BAR_HEIGHT) + 8 +
                                          PUBLISHER_PREVIEW_HEIGHT),
                                         PUBLISHER_PREVIEW_WIDTH,
                                         PUBLISHER_PREVIEW_HEIGHT)];
                    
                    
                    
                } else {
			                 [_publisher.view setFrame:
                              CGRectMake(PUBLISHER_BAR_HEIGHT + 8,
                                         self.view.frame.size.height -
                                         ((self.archiveOverlay.hidden ? 0 :
                                           ARCHIVE_BAR_HEIGHT) + 8 +
                                          PUBLISHER_PREVIEW_HEIGHT),
                                         PUBLISHER_PREVIEW_WIDTH,
                                         PUBLISHER_PREVIEW_HEIGHT)];
                    
                    
                }
            } completion:^(BOOL finished) {
                
                
            }];
        }
        
        // start overlay hide timer
        self.overlayTimer = [NSTimer scheduledTimerWithTimeInterval:OVERLAY_HIDE_TIME
                                                             target:self
                                                           selector:@selector(overlayTimerAction)
                                                           userInfo:nil
                                                            repeats:NO];
    }
    
}

- (void)overlayTimerAction
{
    BOOL isInFullScreen =   [[[self topOverlayView].layer
                              valueForKey:APP_IN_FULL_SCREEN] boolValue];
    
    // if any button is in highlighted state, we ignore hide action
    if (!self.cameraToggleButton.highlighted &&
        !self.audioPubUnpubButton.highlighted &&
        !self.audioPubUnpubButton.highlighted) {
        // Hide views
        if (!isInFullScreen) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self viewTapped:[[self.view gestureRecognizers]
                                  objectAtIndex:0]];
            });
            
            //[[[self.view gestureRecognizers] objectAtIndex:0] sendActionsForControlEvents:UIControlEventTouchUpInside];
            
        }
    } else {
        // start the timer again for next time
        self.overlayTimer =
        [NSTimer scheduledTimerWithTimeInterval:OVERLAY_HIDE_TIME
                                         target:self
                                       selector:@selector(overlayTimerAction)
                                       userInfo:nil
                                        repeats:NO];
    }
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    
    // current subscriber
    int currentPage = (int)(videoContainerView.contentOffset.x /
                            videoContainerView.frame.size.width);
    
    if (currentPage < [allConnectionsIds count]) {
        // show current scrolled subscriber
        NSString *connectionId = [allConnectionsIds objectAtIndex:currentPage];
        NSLog(@"show as current subscriber %@",connectionId);
        [self showAsCurrentSubscriber:[allSubscribers
                                       objectForKey:connectionId]];
    }
    
}

- (void)showAsCurrentSubscriber:(OTSubscriber *)subscriber
{
    // scroll view tapping bug
    if(subscriber == _currentSubscriber)
        return;
    
    // unsubscribe currently running video
    _currentSubscriber.subscribeToVideo = NO;
    
    // update as current subscriber
    _currentSubscriber = subscriber;
    self.userNameLabel.text = _currentSubscriber.stream.name;
    
    // subscribe to new subscriber
    _currentSubscriber.subscribeToVideo = YES;
    
    self.audioSubUnsubButton.selected = !_currentSubscriber.subscribeToAudio;
}

- (void)setupSession
{
    if(!self.openTokToken)
        return;
    //setup one time session
    if (_session) {
        _session = nil;
    }
    
    _session = [[OTSession alloc] initWithApiKey:kApiKey
                                       sessionId:kSessionId
                                        delegate:self];
    [_session connectWithToken:self.openTokToken error:nil];
    [self setupPublisher];
    
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



- (void)cycleSubscriberViewForward:(BOOL)forward {
    
    // Check this method for rotating subscriber views.
    int mod = 1;
    
    if (!forward) {
        mod = -1;
    }
    
    _currentSubscriberIndex =
    (_currentSubscriberIndex + mod) % allConnectionsIds.count;
    
    OTSubscriber *nextSubscriber =
    [allSubscribers objectForKey:
     [allConnectionsIds objectAtIndex:_currentSubscriberIndex]];
    
    [self showAsCurrentSubscriber:nextSubscriber];
    
    [videoContainerView setContentOffset:
     CGPointMake(_currentSubscriber.view.frame.origin.x, 0) animated:YES];
    
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
    // now publish
//    OTError *error = nil;
//    [_session publish:_publisher error:&error];
//    if (error)
//    {
//        [self showAlert:[error localizedDescription]];
//    }
    
    // create self subscriber
    [self createSubscriber:self.roomStreamsArray[0]];
}



- (void)sessionDidDisconnect:(OTSession *)session
{
    
    // remove all subscriber views from video container
    for (int i = 0; i < [allConnectionsIds count]; i++)
    {
        OTSubscriber *subscriber = [allSubscribers valueForKey:
                                    [allConnectionsIds objectAtIndex:i]];
        [subscriber.view removeFromSuperview];
    }
    
    [_publisher.view removeFromSuperview];
    
    [allSubscribers removeAllObjects];
    [allConnectionsIds removeAllObjects];
    [allStreams removeAllObjects];
    
    _currentSubscriber = NULL;
    _publisher = nil;
    
    if (self.archiveStatusImgView2.isAnimating)
    {
        [self stopArchiveAnimation];
    }
    
}

- (void)    session:(OTSession *)session
    streamDestroyed:(OTStream *)stream
{
    NSLog(@"streamDestroyed %@", stream.connection.connectionId);
    
    // get subscriber for this stream
    OTSubscriber *subscriber = [allSubscribers objectForKey:
                                stream.connection.connectionId];
    
    // remove from superview
    [subscriber.view removeFromSuperview];
    
    [allSubscribers removeObjectForKey:stream.connection.connectionId];
    [allConnectionsIds removeObject:stream.connection.connectionId];
    
    _currentSubscriber = nil;
    
    // show first subscriber
    if ([allConnectionsIds count] > 0) {
        NSString *firstConnection = [allConnectionsIds objectAtIndex:0];
        [self showAsCurrentSubscriber:[allSubscribers
                                       objectForKey:firstConnection]];
    }
    
    
}

- (void)createSubscriber:(OTStream *)stream
{
    // create subscriber
    OTSubscriber *subscriber = [[OTSubscriber alloc]
                                initWithStream:stream delegate:self];
    
    // subscribe now
    OTError *error = nil;
    [_session subscribe:subscriber error:&error];
    if (error)
    {
        [self showAlert:[error localizedDescription]];
    }
}

- (void)subscriberDidConnectToStream:(OTSubscriberKit *)subscriber
{
    NSLog(@"subscriberDidConnectToStream %@", subscriber.stream.name);
    [self requestToHopOnStage:subscriber.stream.name];
    
    
    // create subscriber
    OTSubscriber *sub = (OTSubscriber *)subscriber;
    [allSubscribers setObject:subscriber forKey:sub.stream.connection.connectionId];
    [allConnectionsIds addObject:sub.stream.connection.connectionId];
    
    // set subscriber position and size
    CGFloat containerWidth = CGRectGetWidth(videoContainerView.bounds);
    CGFloat containerHeight = CGRectGetHeight(videoContainerView.bounds);
    int count = [allConnectionsIds count] - 1;
    [sub.view setFrame:
     CGRectMake(count *
                CGRectGetWidth(videoContainerView.bounds),
                0,
                containerWidth,
                containerHeight)];
    
    sub.view.tag = count;
    
    // add to video container view
    [videoContainerView insertSubview:sub.view
                         belowSubview:_publisher.view];
    
    
    // default subscribe video to the first subscriber only
    if (!_currentSubscriber) {
        [self showAsCurrentSubscriber:(OTSubscriber *)subscriber];
    } else {
        subscriber.subscribeToVideo = NO;
    }
    
    // set scrollview content width based on number of subscribers connected.
    [videoContainerView setContentSize:
     CGSizeMake(videoContainerView.frame.size.width * (count + 1),
                videoContainerView.frame.size.height - 18)];
    
    [allStreams setObject:sub.stream forKey:sub.stream.connection.connectionId];
    
    
    
}

- (void)publisher:(OTPublisherKit *)publisher
    streamCreated:(OTStream *)stream
{
    // create self subscriber
    [self createSubscriber:stream];
}

- (void)  session:(OTSession *)mySession
    streamCreated:(OTStream *)stream
{
    // create remote subscriber
    [self createSubscriber:stream];
}

- (void)session:(OTSession *)session didFailWithError:(OTError *)error
{
    NSLog(@"sessionDidFail");
    [self showAlert:
     [NSString stringWithFormat:@"There was an error connecting to session %@",
      session.sessionId]];
    [self endCallAction:nil];
}

- (void)publisher:(OTPublisher *)publisher didFailWithError:(OTError *)error
{
    NSLog(@"publisher didFailWithError %@", error);
    [self showAlert:[NSString stringWithFormat:
                     @"There was an error publishing."]];
    [self endCallAction:nil];
}

- (void)subscriber:(OTSubscriber *)subscriber didFailWithError:(OTError *)error
{
    NSLog(@"subscriber could not connect to stream");
}

#pragma mark - Helper Methods
- (IBAction)endCallAction:(UIButton *)button
{
    if (_session && _session.sessionConnectionStatus ==
        OTSessionConnectionStatusConnected) {
        // disconnect session
        NSLog(@"disconnecting....");
        [_session disconnect:nil];
        return;
    }
}

- (void)showAlert:(NSString *)string
{
    // show alertview on main UI
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Other Interactions
- (IBAction)toggleAudioSubscribe:(id)sender
{
    if (_currentSubscriber.subscribeToAudio == YES) {
        _currentSubscriber.subscribeToAudio = NO;
        self.audioSubUnsubButton.selected = YES;
    } else {
        _currentSubscriber.subscribeToAudio = YES;
        self.audioSubUnsubButton.selected = NO;
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:UIApplicationWillResignActiveNotification
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:UIApplicationDidBecomeActiveNotification
     object:nil];
    
}

- (IBAction)toggleCameraPosition:(id)sender
{
    if (_publisher.cameraPosition == AVCaptureDevicePositionBack) {
        _publisher.cameraPosition = AVCaptureDevicePositionFront;
        self.cameraToggleButton.selected = NO;
        self.cameraToggleButton.highlighted = NO;
    } else if (_publisher.cameraPosition == AVCaptureDevicePositionFront) {
        _publisher.cameraPosition = AVCaptureDevicePositionBack;
        self.cameraToggleButton.selected = YES;
        self.cameraToggleButton.highlighted = YES;
    }
}

- (IBAction)toggleAudioPublish:(id)sender
{
    if (_publisher.publishAudio == YES) {
        _publisher.publishAudio = NO;
        self.audioPubUnpubButton.selected = YES;
    } else {
        _publisher.publishAudio = YES;
        self.audioPubUnpubButton.selected = NO;
    }
}

- (void)startArchiveAnimation
{
    
    if (self.archiveOverlay.hidden)
    {
        self.archiveOverlay.hidden = NO;
        CGRect frame = _publisher.view.frame;
        frame.origin.y -= ARCHIVE_BAR_HEIGHT;
        _publisher.view.frame = frame;
    }
    BOOL isInFullScreen = [[[self topOverlayView].layer
                            valueForKey:APP_IN_FULL_SCREEN] boolValue];
    
    //show UI if it is in full screen
    if (isInFullScreen)
    {
        [self viewTapped:[self.view.gestureRecognizers objectAtIndex:0]];
    }
    
    self.archiveStatusImgView.hidden = YES;
    self.archiveStatusImgView2.hidden = NO;
    
    // set animation images
    self.archiveStatusLbl.text = @"Archiving call";
    UIImage *imageOne = [UIImage imageNamed:@"archiving_on-5.png"];
    UIImage *imageTwo = [UIImage imageNamed:@"archiving_pulse-15.png"];
    NSArray *imagesArray =
    [NSArray arrayWithObjects:imageOne, imageTwo, nil];
    self.archiveStatusImgView2.animationImages = imagesArray;
    self.archiveStatusImgView2.animationDuration = 1.0f;
    self.archiveStatusImgView2.animationRepeatCount = 0;
    [self.archiveStatusImgView2 startAnimating];
    
}

- (void)stopArchiveAnimation
{
    [self.archiveStatusImgView2 stopAnimating];
    self.archiveStatusLbl.text = @"Archiving off";
    self.archiveStatusImgView2.image =
    [UIImage imageNamed:@"archiving_off-Small.png"];
    
    self.archiveStatusImgView.hidden = NO;
    self.archiveStatusImgView2.hidden = YES;
    
    BOOL isInFullScreen = [[[self topOverlayView].layer
                            valueForKey:APP_IN_FULL_SCREEN] boolValue];
    if (!isInFullScreen)
    {
        [_publisher.view setFrame:
         CGRectMake(8,
                    self.view.frame.size.height -
                    (PUBLISHER_BAR_HEIGHT +
                     (self.archiveOverlay.hidden ? 0 :
                      ARCHIVE_BAR_HEIGHT)
                     + 8 + PUBLISHER_PREVIEW_HEIGHT),
                    PUBLISHER_PREVIEW_WIDTH,
                    PUBLISHER_PREVIEW_HEIGHT)];
    }
}

- (void)enteringBackgroundMode:(NSNotification*)notification
{
    _publisher.publishVideo = NO;
    _currentSubscriber.subscribeToVideo = NO;
}

- (void)leavingBackgroundMode:(NSNotification*)notification
{
    _publisher.publishVideo = YES;
    _currentSubscriber.subscribeToVideo = YES;
    
    //now subscribe to any background connected streams
    for (OTStream *stream in backgroundConnectedStreams)
    {
        // create subscriber
        OTSubscriber *subscriber = [[OTSubscriber alloc]
                                    initWithStream:stream delegate:self];
        // subscribe now
        OTError *error = nil;
        [_session subscribe:subscriber error:&error];
        if (error)
        {
            [self showAlert:[error localizedDescription]];
        }
        
    }
    [backgroundConnectedStreams removeAllObjects];
}

- (void)session:(OTSession *)session
archiveStartedWithId:(NSString *)archiveId
           name:(NSString *)name
{
    NSLog(@"session archiving started");
    [self startArchiveAnimation];
}

- (void)session:(OTSession*)session
archiveStoppedWithId:(NSString *)archiveId
{
    NSLog(@"session archiving stopped");
    [self stopArchiveAnimation];
}


#pragma mark - Connect to soapbox server
-(void)connectToSoapBoxServer {
    NSDictionary *userInfoDto = @{@"roomName":@"slug1",@"room":@"slug1",@"username": self.userInfo.twitterUserName, @"userID": self.userInfo.twitterUserID,@"authToken":self.userInfo.twitterAuthToken,@"authTokenSecret":self.userInfo.twitterAuthTokenSecret, @"platform":@"iOS"};
    
    [SIOSocket socketWithHost: soapBoxServerUrl response: ^(SIOSocket *socket) {
        NSLog(@"connected");
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
             NSLog(@"%@ ARGS",args);
             NSDictionary *dto =args[0];
             self.openTokToken = [dto valueForKey:@"opentok_user_token"];
             [self.socket on: @"initSBRoomClientEmit" callback: ^(SIOParameterArray *args)
              {
                  NSLog(@"%@ ARGS",args);
                  NSDictionary *dto =args[0];
                  self.openTokToken = [dto valueForKey:@"opentok_user_token"];
                  
                  [self setupSession];
                  
                  // Get all the stream ids array
                  self.roomStreamsArray = [args valueForKey:@"roomStreams"];
                  
                  [self setupSession];
                  
              }];
             
         }];
        
    }];
    
}

-(void)requestToHopOnStage:(NSString*)streamId {
    if(self.socketIsConnected) {
        [self.socket emit: @"requestToHopStageEmit" args: @[@"ahdblakhbalkhf"]];
    }
}

@end