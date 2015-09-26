//
//  StoreLocatorViewController.m
//  ShopBuddy
//
//  Created by Jagadeeshwar on 25/09/15.
//  Copyright © 2015 Jagadeeshwar. All rights reserved.
//

#import "StoreLocatorViewController.h"
#import "DBOperationManager.h"

@interface StoreLocatorViewController ()
@property (nonatomic, strong) NSMutableArray *stores;
@property (nonatomic, strong) NSIndexPath *checkedIndexPath;
- (IBAction)doneTapped:(id)sender;

@end

@implementation StoreLocatorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.tableview registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    
    UIView *vw = [self.view viewWithTag:1];
    vw.layer.cornerRadius=2.0f;
    vw.layer.borderColor=[UIColor lightGrayColor].CGColor;
    vw.layer.borderWidth=1.0f;
    
    [self.loadingIndicator setHidden:YES];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)doneTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{}];
}
- (IBAction)findStoresAction:(id)sender {
    [sender setHidden:YES];
    [self.loadingIndicator setHidden:NO];
    
    [self.searchField resignFirstResponder];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/geocode/json?address=santa+cruz&components=postal_code:%@&sensor=false", self.searchField.text]];
        
        NSData *dta = [NSData dataWithContentsOfURL:url];
        if (dta) {
            
            NSError *error = nil;
            NSDictionary *locationInfodictionary = [NSJSONSerialization JSONObjectWithData:dta options:NSJSONReadingMutableLeaves error:&error];
            if (!error) {
                NSArray*arr=[locationInfodictionary valueForKey:@"results"];
                if (arr.count) {
                    NSDictionary*dict=[[arr[0] objectForKey:@"geometry"] objectForKey:@"location"];
                    NSURL *storelocatorurl = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.tesco.com/store-locator/uk/asp/getNearestStores.asp?lat=%@&lon=%@&searchField=allStores&rad=0.03&rL=0&resultsRequired=0", dict[@"lat"], dict[@"lng"]]];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                        NSData *dttta = [NSData dataWithContentsOfURL:storelocatorurl];
                        NSError *error2 = nil;
                        if (dttta) {
                            NSString *str = [[NSString alloc] initWithBytes:dttta.bytes length:dttta.length encoding:NSUTF8StringEncoding];
                            
                            str = [str stringByReplacingOccurrencesOfString:@"storeLocatorLite.getNearestStoresResponse(" withString:@""];
                            NSString *newjsonString = [str substringToIndex:[str length]-2];
                            
                            NSDictionary *infodictionary = [NSJSONSerialization JSONObjectWithData:[newjsonString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:&error2];
                            if (error2) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [sender setHidden:NO];
                                    [self.loadingIndicator setHidden:YES];
                                });
                                NSLog(@"error2 = %@",error2);
                                
                                [[[UIAlertView alloc] initWithTitle:@"Couldn't get nearest stores for given post code" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                                
                            }else{
                                NSLog(@"%@",infodictionary);
                                
                                if (!self.stores) {
                                    self.stores = [NSMutableArray array];
                                }
                                NSArray*infoarr=[infodictionary valueForKey:@"resources"];
                                if (infoarr.count) {
                                    
                                    [infoarr enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                        NSString *storeName = [obj objectForKey:@"name"];
                                        if (storeName) {
                                            [self.stores addObject:storeName];
                                        }
                                    }];
                                    
                                    
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [self.tableview reloadData];
                                        
                                        [sender setHidden:NO];
                                        [self.loadingIndicator setHidden:YES];
                                    });
                                }
                                
                            }
                        }
                        else{
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [sender setHidden:NO];
                                [self.loadingIndicator setHidden:YES];
                                
                                [[[UIAlertView alloc] initWithTitle:@"Couldn't get nearest stores for given post code" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];

                            });
                        }
                    });
                }
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.searchField.text=@"";

                    [sender setHidden:NO];
                    [self.loadingIndicator setHidden:YES];
                    
                    [[[UIAlertView alloc] initWithTitle:@"Couldn't get nearest stores for given post code" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                    
                });
            }

        }
        else{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.searchField.text=@"";
                
                [sender setHidden:NO];
                [self.loadingIndicator setHidden:YES];
                
                [[[UIAlertView alloc] initWithTitle:@"Couldn't get nearest stores for given post code" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                
            });
        }
    });
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.stores.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.textLabel.text=[self.stores objectAtIndex:indexPath.row];

    cell.textLabel.textColor=[UIColor colorWithRed:0.0f green:83.0f/255.0 blue:159.0f/255.0f alpha:1.0];
    cell.accessoryType=UITableViewCellAccessoryNone;
    return cell;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return @"Nearest stores";
}
-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath{
    
    [[tableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [[tableView cellForRowAtIndexPath:self.checkedIndexPath] setAccessoryType:UITableViewCellAccessoryNone];

    self.checkedIndexPath = indexPath;
    
    [[DBOperationManager instance] updateStoreInformation:[self.stores objectAtIndex:indexPath.row] toShoppingList:self.listId];
}


@end
