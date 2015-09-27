//
//  DBOperationManager.h
//  ShopBuddy
//
//  Created by Jagadeeshwar on 25/09/15.
//  Copyright © 2015 Jagadeeshwar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DBOperationManager : NSObject
+(DBOperationManager *)instance;

-(NSString *)documentdirectiorypath;

////////////////////////
//  Insert Operations
////////////////////////
-(void)saveItems:(NSMutableArray*)items forList:(NSString*)listId;
-(NSString *)insertNewShoppingList:(NSString *)listName;
-(void)updateCollectionStatus:(NSInteger)status forProduct:(NSInteger)productId inList:(NSString*)listId;
-(void)updateStoreInformation:(NSString*)storeName toShoppingList:(NSString*)listId;
-(void)createNewUser;
-(void)insertSharedShoppingList:(NSDictionary*)list;
-(void)updateBasketSharringStaus:(BOOL)status toShoppingList:(NSString*)listId;
-(void)deleteShoplist:(NSString *)listId;

////////////////////////
//  Read Operations
////////////////////////
-(NSMutableArray*)shoppingLists;
-(NSMutableArray*)defaultItems;
-(NSMutableArray *)itemsForList:(NSString*)listId;
-(NSString *)user;
-(NSString*)storeNameForList:(NSString*)listId;
-(BOOL)isListShared:(NSString*)listId;
@end
