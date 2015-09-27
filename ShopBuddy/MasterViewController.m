//
//  MasterViewController.m
//  ShopBuddy
//
//  Created by Jagadeeshwar on 24/09/15.
//  Copyright © 2015 Jagadeeshwar. All rights reserved.
//

#import "MasterViewController.h"
#import "ItemListViewController.h"
#import "DBOperationManager.h"

#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

@interface MasterViewController () <UITextFieldDelegate>

@property NSMutableArray *objects;
@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.clearsSelectionOnViewWillAppear = YES;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peerDidReceiveSharedShopListData:)
                                                 name:@"MPC_DidReceiveDataNotification"
                                               object:nil];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.objects = [[DBOperationManager instance] shoppingLists];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Shopping Buddy"
                                                    message:@"Please give the name for new shopping list"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Done", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [[alert textFieldAtIndex:0] setAutocapitalizationType:UITextAutocapitalizationTypeWords];
    [alert show];
}
#pragma mark - UIAlertViewDelegate
- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    return ([alertView textFieldAtIndex:0].text.length>3 ? YES : NO);
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (buttonIndex == 1) {
        NSLog(@"%@", [alertView textFieldAtIndex:0].text);
        
        if (!self.objects) {
            self.objects = [[NSMutableArray alloc] init];
        }
        NSString *listTitle = [alertView textFieldAtIndex:0].text;
        //listTitle=[listTitle uppercaseString];
        
        NSString *listId = [[DBOperationManager instance] insertNewShoppingList:listTitle];
        
        [self.objects insertObject:@{@"listTitle":listTitle, @"listId":listId} atIndex:0];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

    }
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"ItemListSegue"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSDictionary *object = self.objects[indexPath.row];
        ItemListViewController *controller = (ItemListViewController *)[segue destinationViewController];
        [controller setDetailItem:object];
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CustomCell" forIndexPath:indexPath];

    UILabel *titleLabel = (UILabel *)[cell.contentView viewWithTag:1];
    UILabel *detailTitleLabel = (UILabel *)[cell.contentView viewWithTag:2];
    
    UIImageView *imgview = (UIImageView *)[cell.contentView viewWithTag:3];
    
    if (SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(@"9.0")) {
        titleLabel.font=[UIFont systemFontOfSize:20];
    }
    
    NSString *object = [self.objects[indexPath.row] objectForKey:@"listTitle"];
    titleLabel.text = object;
    
    NSArray *listItems = [[DBOperationManager instance] itemsForList:[self.objects[indexPath.row] objectForKey:@"listId"]];

    if ([listItems valueForKeyPath:@"name"]) {
        detailTitleLabel.text = [[listItems valueForKeyPath:@"name"] componentsJoinedByString:@","];
    }
    if (listItems.count==0) {
        detailTitleLabel.text = @"<No Items defined>";
    }
    
    if ([[DBOperationManager instance] isListShared:[self.objects[indexPath.row] objectForKey:@"listId"]]) {
        imgview.image = [UIImage imageNamed:@"shared-list-1.png"];
    }else{
        imgview.image = [UIImage imageNamed:@"sh.png"];
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [[DBOperationManager instance] deleteShoplist:[self.objects[indexPath.row] objectForKey:@"listId"]];
        
        [self.objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];

    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}


- (void)peerDidReceiveSharedShopListData:(NSNotification *)notification {
    NSDictionary *dict = [[notification userInfo] objectForKey:@"data"];
    
    NSDictionary *sharedList = dict[@"ShopListShare"];
    if (sharedList) {
        NSLog(@"peerDidReceiveShopListData = %@", dict);
        //    NSDictionary *messageInformation = @{@"ShopListShare":  @{@"user":[DBOperationManager instance].user, @"listTitle":self.detailItem[@"listTitle"], @"listId":self.detailItem[@"listId"], @"items":self.dataArray} };
        
        [[DBOperationManager instance] insertSharedShoppingList:sharedList];
        self.objects = [[DBOperationManager instance] shoppingLists];
        [self.tableView reloadData];

    }
}
@end
