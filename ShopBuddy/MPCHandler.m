//
//  MPCHandler.m
//  MultiPeerConnectivity
//
//  Created by Jagadeeshwar on 21/09/15.
//  Copyright (c) 2015 Jagadeeshwar. All rights reserved.
//

#import "MPCHandler.h"


@implementation MPCHandler

- (void)setupPeerWithDisplayName:(NSString *)displayName {
    self.peerID = [[MCPeerID alloc] initWithDisplayName:displayName];
}

- (void)setupSession {
    self.session = [[MCSession alloc] initWithPeer:self.peerID];
    self.session.delegate = self;
}

- (void)setupBrowser {
    self.browser = [[MCBrowserViewController alloc] initWithServiceType:@"my-basket" session:_session];
}

- (void)advertiseSelf:(BOOL)advertise {
    if (advertise) {
        self.advertiser = [[MCAdvertiserAssistant alloc] initWithServiceType:@"my-basket" discoveryInfo:nil session:self.session];
        [self.advertiser start];
        
    } else {
        [self.advertiser stop];
        self.advertiser = nil;
    }
}

#pragma mark - MCSessionDelegate

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    //not connected, connecting, and connected
    NSLog(@"%s",__FUNCTION__);
    switch (state) {
        case MCSessionStateNotConnected:
        {
            NSLog(@"%@ NotConnected", peerID.displayName);
        }
            break;
        case MCSessionStateConnecting:
        {
            NSLog(@"%@ Connecting", peerID.displayName);
        }
            break;
        case MCSessionStateConnected:
        {
            NSLog(@"%@ Connected", peerID.displayName);
        }
            break;
        default:
            break;
    }
    NSDictionary *userInfo = @{ @"peerID": peerID,
                                @"state" : @(state) };
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MPC_DidChangeStateNotification"
                                                            object:nil
                                                          userInfo:userInfo];
    });
    
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    NSLog(@"%s",__FUNCTION__);
    
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];

    NSDictionary *userInfo = @{ @"data": dict,
                                @"peerID": peerID };
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MPC_DidReceiveDataNotification"
                                                            object:nil
                                                          userInfo:userInfo];
    });
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
    NSLog(@"%s",__FUNCTION__);
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
    NSLog(@"%s",__FUNCTION__);
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
    NSLog(@"%s",__FUNCTION__);
}
@end
