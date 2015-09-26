//
//  ItemListViewController.m
//  ShopBuddy
//
//  Created by Jagadeeshwar on 25/09/15.
//  Copyright © 2015 Jagadeeshwar. All rights reserved.
//

#import "ItemListViewController.h"
#import "DBOperationManager.h"
#import "AddItemTableViewController.h"
#import "SWTableViewCell.h"
#import "StoreLocatorViewController.h"
#import "AppDelegate.h"

@interface ItemListViewController () <SWTableViewCellDelegate, UIActionSheetDelegate, MCBrowserViewControllerDelegate>
@property (strong, nonatomic) NSMutableArray *dataArray;
@property (weak, nonatomic) IBOutlet UIButton *sortByItemButton;
@property (weak, nonatomic) IBOutlet UIButton *sortByAisleButton;
@property (strong, nonatomic) AppDelegate *appDelegate;

- (IBAction)sortByItemButtonAction:(id)sender;
- (IBAction)sortByAisleButtonAction:(id)sender;

@end

@implementation ItemListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.title=self.detailItem[@"listTitle"];
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(takeActionOnList:)];

    self.navigationItem.rightBarButtonItems = @[addButton, actionButton];
    
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peerDidReceiveShopListData:)
                                                 name:@"MPC_DidReceiveDataNotification"
                                               object:nil];

}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.dataArray = [[DBOperationManager instance] itemsForList:self.detailItem[@"listId"]];
    [self.tableView reloadData];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender {
    [self performSegueWithIdentifier:@"AddItemSegue" sender:self];
}
-(void)takeActionOnList:(id)sender{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"What do you want to do with the list?"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Share basket", @"Locate the store", nil];
    
    [actionSheet showInView:self.view];
}
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
        NSLog(@"share");
        
        if (self.appDelegate.mpcHandler.session != nil) {
            [[self.appDelegate mpcHandler] setupBrowser];
            [[[self.appDelegate mpcHandler] browser] setDelegate:self];
            
            [self presentViewController:self.appDelegate.mpcHandler.browser
                               animated:YES
                             completion:nil];
        }
        
        
    }
    else if (buttonIndex == 1){
        [self performSegueWithIdentifier:@"StoreLocator" sender:nil];
    }
}


-(NSMutableArray*)pickedItems{
    __block NSMutableArray *pickedItems = [NSMutableArray array];

    [self.dataArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj[@"collectionStatus"] integerValue]) {
            [pickedItems addObject:obj];
        }
    }];
    return pickedItems;
}
-(NSMutableArray*)unPickedItems{
    __block NSMutableArray *unPickedItems = [NSMutableArray array];
    
    [self.dataArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj[@"collectionStatus"] integerValue] == 0) {
            [unPickedItems addObject:obj];
        }
    }];
    return unPickedItems;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    __block NSInteger pickedItemsCount = [self pickedItems].count;
    __block NSInteger unpickedItemsCount = [self unPickedItems].count;
    
    return (section==0?unpickedItemsCount:pickedItemsCount);
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *cellIdentifier = @"ItemCell";

    SWTableViewCell *cell = (SWTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell.delegate == nil) {
        cell.leftUtilityButtons = [self leftButtons];
        cell.rightUtilityButtons = [self rightButtons];
        cell.delegate = self;
    }
    cell.selectionStyle=UITableViewCellSelectionStyleNone;
    cell.tag=indexPath.section;
    
    UILabel *titleLabel = (UILabel *)[cell.contentView viewWithTag:1];
    UILabel *detailTitleLabel = (UILabel *)[cell.contentView viewWithTag:2];
    
    
    
    // Configure the cell...
    if (indexPath.section == 1) {
        NSDictionary *dict = [self pickedItems][indexPath.row];

        NSDictionary* attributes = @{
                                     NSStrikethroughStyleAttributeName: [NSNumber numberWithInt:NSUnderlineStyleSingle]
                                     };
        
        NSAttributedString* attrText = [[NSAttributedString alloc] initWithString:dict[@"name"] attributes:attributes];
        titleLabel.attributedText = attrText;
        detailTitleLabel.text = dict[@"aisle"];

    }else{
        NSDictionary *dict = [self unPickedItems][indexPath.row];

        titleLabel.text = dict[@"name"];
        detailTitleLabel.text = dict[@"aisle"];
    }

    

    return cell;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return (section==0?@"":@"Picked Items");
}
- (NSArray *)leftButtons
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.55f green:0.27f blue:0.07f alpha:1.0]
                                                icon:[UIImage imageNamed:@"list.png"]];
    return rightUtilityButtons;
}
- (NSArray *)rightButtons
{
    NSMutableArray *leftUtilityButtons = [NSMutableArray new];
    
    [leftUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.07 green:0.75f blue:0.16f alpha:1.0]
                                                icon:[UIImage imageNamed:@"check.png"]];
    return leftUtilityButtons;
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index
{
    switch (index) {
        case 0:
        {
            // Delete button was pressed
            NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
            NSMutableDictionary *dict = [[self pickedItems] objectAtIndex:cellIndexPath.row];
            dict[@"collectionStatus"]=@0;
            [[DBOperationManager instance] updateCollectionStatus:0 forProduct:[dict[@"productId"] integerValue] inList:dict[@"listId"]];
            
            [self.tableView reloadData];
            
            
            NSDictionary *messageInformation = @{@"ListItemUpdate":  @{@"listId":self.detailItem[@"listId"], @"item":dict} };
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:messageInformation options:NSJSONWritingPrettyPrinted error:nil];
            NSError *error = nil;
            [self.appDelegate.mpcHandler.session sendData:jsonData toPeers:self.appDelegate.mpcHandler.session.connectedPeers withMode:MCSessionSendDataReliable error:&error];

            
            break;
        }
        case 1:
            NSLog(@"left button 1 was pressed");
            break;
        case 2:
            NSLog(@"left button 2 was pressed");
            break;
        case 3:
            NSLog(@"left btton 3 was pressed");
        default:
            break;
    }
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index
{
    switch (index) {
        case 0:
        {
            // Delete button was pressed
            NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
            
            NSMutableDictionary *dict = [[self unPickedItems] objectAtIndex:cellIndexPath.row];
            dict[@"collectionStatus"]=@1;
            [[DBOperationManager instance] updateCollectionStatus:1 forProduct:[dict[@"productId"] integerValue] inList:self.detailItem[@"listId"]];

            [self.tableView reloadData];
            
            NSDictionary *messageInformation = @{@"ListItemUpdate":  @{@"listId":self.detailItem[@"listId"], @"item":dict} };
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:messageInformation options:NSJSONWritingPrettyPrinted error:nil];
            NSError *error = nil;
            [self.appDelegate.mpcHandler.session sendData:jsonData toPeers:self.appDelegate.mpcHandler.session.connectedPeers withMode:MCSessionSendDataReliable error:&error];

            break;
        }
        default:
            break;
    }
}

- (BOOL)swipeableTableViewCell:(SWTableViewCell *)cell canSwipeToState:(SWCellState)state
{
    
    switch (state) {
        case 1:{
            // set to NO to disable all left utility buttons appearing
            if(cell.tag == 0){
                return NO;
            }
        }
            return YES;
            break;
        case 2:{
            // set to NO to disable all right utility buttons appearing
            if(cell.tag == 1){
                return NO;
            }
        }
            return YES;
            break;
        default:
            break;
    }
    
    return YES;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"AddItemSegue"]) {
        UINavigationController *navig = [segue destinationViewController];
        AddItemTableViewController *controller = (AddItemTableViewController *)[navig.viewControllers objectAtIndex:0];
        controller.listName=self.detailItem[@"listTitle"];
        controller.listId=self.detailItem[@"listId"];
    }else if ([segue.identifier isEqualToString:@"StoreLocator"]) {
        UINavigationController *navig = [segue destinationViewController];
        StoreLocatorViewController *controller = (StoreLocatorViewController *)[navig.viewControllers objectAtIndex:0];
        controller.listId=self.detailItem[@"listId"];
    }
}


- (IBAction)sortByItemButtonAction:(id)sender {
    BOOL isAscendingOrder = YES;
    
    if ([[self.sortByItemButton titleForState:UIControlStateNormal] isEqualToString:@"Item ↑"]) {
        isAscendingOrder = NO;
        [self.sortByItemButton setTitle:@"Item ↓" forState:UIControlStateNormal];
    }
    else{//↓
        [self.sortByItemButton setTitle:@"Item ↑" forState:UIControlStateNormal];
    }
    NSSortDescriptor *brandDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:isAscendingOrder];
    self.dataArray = [[self.dataArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:brandDescriptor]] mutableCopy];
    [self.tableView reloadData];
}

- (IBAction)sortByAisleButtonAction:(id)sender {
    BOOL isAscendingOrder = YES;
    
    if ([[self.sortByAisleButton titleForState:UIControlStateNormal] isEqualToString:@"Aisle Number ↑"]) {
        isAscendingOrder = NO;
        [self.sortByAisleButton setTitle:@"Aisle Number ↓" forState:UIControlStateNormal];
    }
    else{//↓
        [self.sortByAisleButton setTitle:@"Aisle Number ↑" forState:UIControlStateNormal];
    }

    NSSortDescriptor *brandDescriptor = [[NSSortDescriptor alloc] initWithKey:@"aisle" ascending:isAscendingOrder];
    self.dataArray = [[self.dataArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:brandDescriptor]] mutableCopy];
    [self.tableView reloadData];
}


#pragma mark - MCBrowserViewControllerDelegate


- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController {
    [self.appDelegate.mpcHandler.browser dismissViewControllerAnimated:YES completion:nil];
    
    
    NSDictionary *messageInformation = @{@"ShopListShare":  @{@"user":[DBOperationManager instance].user, @"listTitle":self.detailItem[@"listTitle"], @"listId":self.detailItem[@"listId"], @"items":self.dataArray} };
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:messageInformation options:NSJSONWritingPrettyPrinted error:nil];
    NSError *error = nil;
    [self.appDelegate.mpcHandler.session sendData:jsonData toPeers:self.appDelegate.mpcHandler.session.connectedPeers withMode:MCSessionSendDataReliable error:&error];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController {
    [self.appDelegate.mpcHandler.browser dismissViewControllerAnimated:YES completion:nil];
}

- (void)peerDidReceiveShopListData:(NSNotification *)notification {
    NSDictionary *dict = [[notification userInfo] objectForKey:@"data"];
    
    NSDictionary *updatedItem = dict[@"ListItemUpdate"];

    if (updatedItem && [self.detailItem[@"listId"] isEqualToString:updatedItem[@"listId"]]) {
        NSLog(@"peerDidReceiveShopListData = %@", dict);
        NSDictionary *item = updatedItem[@"item"];
        [self.dataArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if ([obj[@"productId"] integerValue] == [[item objectForKey:@"productId"] integerValue]) {
                
                [[DBOperationManager instance] updateCollectionStatus:[item[@"collectionStatus"] integerValue] forProduct:[item[@"productId"] integerValue] inList:updatedItem[@"listId"]];
                
                obj[@"collectionStatus"] = @([item[@"collectionStatus"] integerValue]);
                
                *stop=YES;
            }
            
        }];
        [self.tableView reloadData];
    }
}
@end
