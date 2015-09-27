//
//  AddItemTableViewController.m
//  ShopBuddy
//
//  Created by Jagadeeshwar on 25/09/15.
//  Copyright © 2015 Jagadeeshwar. All rights reserved.
//

#import "AddItemTableViewController.h"
#import "Checkbox.h"
#import "DBOperationManager.h"

@interface AddItemTableViewController (){
    BOOL isInSearchMode;
}
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIButton *addButton;
@property (strong, nonatomic) NSMutableArray *dataArray;

@property (strong, nonatomic) NSMutableArray *searchResultsArray;

@end

@implementation AddItemTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    
    self.dataArray=[[DBOperationManager instance] defaultItems];
    
    
    NSMutableArray *arr = [[DBOperationManager instance] itemsForList:self.listId];
    [arr enumerateObjectsUsingBlock:^(NSMutableDictionary *selectedItem, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [self.dataArray enumerateObjectsUsingBlock:^(NSMutableDictionary *defaultItem, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if ([selectedItem[@"productId"] integerValue] == [defaultItem[@"productId"] integerValue]) {
                defaultItem[@"checked"]=@(YES);
                defaultItem[@"collectionStatus"]=selectedItem[@"collectionStatus"];
            }
        }];
    }];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)doneTapped:(id)sender {
    
    NSMutableArray *arr = [NSMutableArray array];
    [self.dataArray enumerateObjectsUsingBlock:^(NSMutableDictionary *defaultItem, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([defaultItem[@"checked"] boolValue]) {
            [arr addObject:defaultItem];
        }
    }];

    if (arr.count) {
        [[DBOperationManager instance] saveItems:arr forList:self.listId];
    }
    
    [self dismissViewControllerAnimated:YES completion:^{}];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (isInSearchMode) {
        return self.searchResultsArray.count;
    }
    return self.dataArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ItemCell" forIndexPath:indexPath];
    
    // Configure the cell...
    
    if (cell.accessoryView == nil) {
        // Only configure the Checkbox control once.
        cell.accessoryView = [[Checkbox alloc] initWithFrame:CGRectMake(0, 0, 25, 43)];
        cell.accessoryView.opaque = NO;
        cell.backgroundColor = [UIColor clearColor];
        
        [(Checkbox*)cell.accessoryView addTarget:self action:@selector(checkBoxTapped:forEvent:) forControlEvents:UIControlEventValueChanged];
    }
    
    NSDictionary *item = self.dataArray[(NSUInteger)indexPath.row];

    if (isInSearchMode) {
        item = self.searchResultsArray[(NSUInteger)indexPath.row];
    }
    
    cell.textLabel.text = [item objectForKey:@"name"];
    [(Checkbox*)cell.accessoryView setChecked: [item[@"checked"] boolValue] ];
    
    // Accessibility
    [self updateAccessibilityForCell:cell];

    return cell;
}

- (void)checkBoxTapped:(id)sender forEvent:(UIEvent*)event
{
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint currentTouchPosition = [touch locationInView:self.tableView];
    
    // Lookup the index path of the cell whose checkbox was modified.
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:currentTouchPosition];
    
    if (indexPath != nil) {
        // Update our data source array with the new checked state.
        NSMutableDictionary *selectedItem = self.dataArray[(NSUInteger)indexPath.row];
        
        if (isInSearchMode) {
            selectedItem = self.searchResultsArray[(NSUInteger)indexPath.row];
        }

        selectedItem[@"checked"] = @([(Checkbox*)sender isChecked]);
    }
    
    // Accessibility
    [self updateAccessibilityForCell:[self.tableView cellForRowAtIndexPath:indexPath]];
}
#pragma mark -
#pragma mark UITableViewDelegate

//| ----------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Find the cell being touched and update its checked/unchecked image.
    UITableViewCell *targetCell = [tableView cellForRowAtIndexPath:indexPath];
    Checkbox *targetCheckbox = (Checkbox*)[targetCell accessoryView];
    targetCheckbox.checked = !targetCheckbox.checked;
    
    // Don't keep the table selection.
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSMutableDictionary *selectedItem = self.dataArray[(NSUInteger)indexPath.row];
    
    if (isInSearchMode) {
        selectedItem = self.searchResultsArray[(NSUInteger)indexPath.row];
    }

    selectedItem[@"checked"] = @(targetCheckbox.checked);
    
    // Accessibility
    [self updateAccessibilityForCell:targetCell];
}

#pragma mark -
#pragma mark Accessibility

//| ----------------------------------------------------------------------------
//! Utility method for configuring a cell's accessibilityValue based upon the
//! current checkbox state.
//
- (void)updateAccessibilityForCell:(UITableViewCell*)cell
{
    // The cell's accessibilityValue is the Checkbox's accessibilityValue.
    cell.accessibilityValue = cell.accessoryView.accessibilityValue;
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
- (IBAction)addButtonAction:(id)sender {
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark -
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar{
    isInSearchMode=YES;

    return YES;
}
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
    [searchBar setShowsCancelButton:YES animated:YES];
}
/*- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar{
    [searchBar setShowsCancelButton:NO animated:YES];
    isInSearchMode=NO;
    [self.tableView reloadData];
}*/
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    [searchBar setShowsCancelButton:NO animated:YES];
    isInSearchMode=NO;
    [self.tableView reloadData];
    [searchBar resignFirstResponder];
    searchBar.text=@"";

}
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    [searchBar resignFirstResponder];
}
- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString *str = [searchBar.text stringByReplacingCharactersInRange:range withString:[text stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]];
    //NSLog(@"String:%@",str);
    
    NSArray *filteredarray = [self.dataArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(name CONTAINS[cd] %@)", [@" " stringByAppendingString:str]]];
    
    self.searchResultsArray = [filteredarray copy];
    if (str.length==0) {
        self.searchResultsArray = [self.dataArray copy];
    }
    [self.tableView reloadData];

    return YES;
}
@end
