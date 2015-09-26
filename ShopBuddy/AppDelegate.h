//
//  AppDelegate.h
//  ShopBuddy
//
//  Created by Jagadeeshwar on 24/09/15.
//  Copyright © 2015 Jagadeeshwar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPCHandler.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong) MPCHandler *mpcHandler;

@end

