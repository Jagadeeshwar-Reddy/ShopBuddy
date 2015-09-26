//
//  MasterViewController.h
//  ShopBuddy
//
//  Created by Jagadeeshwar on 24/09/15.
//  Copyright © 2015 Jagadeeshwar. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ItemListViewController;

@interface MasterViewController : UITableViewController

@property (strong, nonatomic) ItemListViewController *detailViewController;


@end

