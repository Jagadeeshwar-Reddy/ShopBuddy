//
//  StoreLocatorViewController.h
//  ShopBuddy
//
//  Created by Jagadeeshwar on 25/09/15.
//  Copyright © 2015 Jagadeeshwar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StoreLocatorViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (weak, nonatomic) IBOutlet UITextField *searchField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (weak, nonatomic) IBOutlet UIButton *findstoresbutton;

@property (strong, nonatomic) NSString *listId;

- (IBAction)findStoresAction:(id)sender;

@end
