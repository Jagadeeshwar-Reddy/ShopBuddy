//
//  DBOperationManager.m
//  ShopBuddy
//
//  Created by Jagadeeshwar on 25/09/15.
//  Copyright © 2015 Jagadeeshwar. All rights reserved.
//

#import "DBOperationManager.h"
#import "FMDB.h"

@implementation DBOperationManager

#define kLocalDatabaseName @"ShoppingBuddy.sqlite"
#define FMDBQuickCheck(SomeBool) { if (!(SomeBool)) { NSLog(@"Failure on line %d", __LINE__); abort(); } }
#define GlobalDatabaseQueue [self globalQueueForDatabase]


+ (DBOperationManager *)instance {
    static DBOperationManager *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[DBOperationManager alloc] init];
    });
    
    return _sharedClient;
}

- (id)init
{
    if(self=[super init]){
        
        //Using NSFileManager we can perform many file system operations.
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error=nil;
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);
        NSString *documentsDir = [paths objectAtIndex:0];
        NSString *dbPath=[documentsDir stringByAppendingPathComponent:kLocalDatabaseName];
        
        BOOL success = [fileManager fileExistsAtPath:dbPath];
        
        if(!success) {
            NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:kLocalDatabaseName];
            success = [fileManager copyItemAtPath:defaultDBPath toPath:dbPath error:&error];
            dbPath=nil;
            if (!success)
                NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error description]);
        }
        dbPath=nil;
    }
    return self;
}
-(FMDatabaseQueue *)globalQueueForDatabase{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);
    NSString *documentsDir = [paths objectAtIndex:0];
    NSString *dbPath=[documentsDir stringByAppendingPathComponent:kLocalDatabaseName];
    
    
    static FMDatabaseQueue *_sharedQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
        NSLog(@"Database path = %@",dbPath);
    });
    
    return _sharedQueue;
}

#pragma mark - open database connection

-(NSString *)documentdirectiorypath{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);
    NSString *documentsDir = [paths objectAtIndex:0];
    return documentsDir;
}


////////////////////////
//  Insert Operations
////////////////////////
-(void)saveItems:(NSMutableArray*)items forList:(NSString*)listId{
    [GlobalDatabaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"DELETE FROM Items WHERE listId = ?",listId];
        
        [db beginTransaction];
        [items enumerateObjectsUsingBlock:^(NSDictionary *Obj, NSUInteger idx, BOOL *stop) {
            [db executeUpdate:@"INSERT INTO Items (productId, collectionStatus, listId) VALUES (?, ?, ?)",Obj[@"productId"], Obj[@"collectionStatus"], listId];
        }];
        [db commit];
    }];
}
-(void)insertSharedShoppingList:(NSDictionary*)list{
    [GlobalDatabaseQueue inDatabase:^(FMDatabase *db) {
        
        BOOL isListAlreadyExist = NO;

        FMResultSet *rs = [db executeQuery:@"SELECT listId FROM shoppingList WHERE listId = ?", list[@"listId"]];
        while ([rs next]) {
            NSString *listid = [rs stringForColumnIndex:0];
            isListAlreadyExist = listid.length?YES:NO;
        }
        
        if (isListAlreadyExist == NO) {
            [db executeUpdate:@"INSERT INTO shoppingList (listId, listTitle, listOwner) VALUES (?, ?, ?)", list[@"listId"], list[@"listTitle"], list[@"user"]];
        }else{
            [db executeUpdate:@"DELETE FROM Items WHERE listId = ?",list[@"listId"]];
        }
        
        [list[@"items"] enumerateObjectsUsingBlock:^(NSDictionary *Obj, NSUInteger idx, BOOL *stop) {
            [db executeUpdate:@"INSERT INTO Items (productId, collectionStatus, listId) VALUES (?, ?, ?)",Obj[@"productId"], (Obj[@"collectionStatus"]?:@0), list[@"listId"]];
        }];
    }];
}
-(NSString *)insertNewShoppingList:(NSString *)listName{
    __block NSString *newListId;
    NSString *user=[[DBOperationManager instance] user];

    [GlobalDatabaseQueue inDatabase:^(FMDatabase *db) {
        
        NSString *alphabet  = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXZY0123456789";
        NSMutableString *randomString = [NSMutableString stringWithCapacity: 10];
        
        for (int i=0; i<10; i++) {
            u_int32_t r = arc4random() % [alphabet length];
            unichar c = [alphabet characterAtIndex:r];
            [randomString appendFormat:@"%C", c];
        }
        [db executeUpdate:@"INSERT INTO shoppingList (listId, listTitle, listOwner) VALUES (?, ?, ?)", randomString, listName, user];
        
        newListId = randomString;
    }];
    return newListId;
}

-(void)updateCollectionStatus:(NSInteger)status forProduct:(NSInteger)productId inList:(NSString*)listId{
    [GlobalDatabaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"UPDATE Items SET collectionStatus = ? WHERE productId = ? AND listId = ?", @(status), @(productId), listId];
    }];
}
-(void)updateStoreInformation:(NSString*)storeName toShoppingList:(NSString*)listId{
    [GlobalDatabaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"UPDATE shoppingList SET storeToShop = ? WHERE listId = ?", storeName, listId];
    }];
}
-(void)createNewUser{
    //
    [GlobalDatabaseQueue inDatabase:^(FMDatabase *db) {

        NSString *alphabet  = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXZY0123456789";
        NSMutableString *randomString = [NSMutableString stringWithCapacity:10];
        
        for (int i=0; i<10; i++) {
            u_int32_t r = arc4random() % [alphabet length];
            unichar c = [alphabet characterAtIndex:r];
            [randomString appendFormat:@"%C", c];
        }
        
        [db executeUpdate:@"INSERT INTO userMaster (username) VALUES (?)", randomString];
    }];
}
////////////////////////
//  Read Operations
////////////////////////
-(NSMutableArray*)shoppingLists{
    __block NSMutableArray* lists = [NSMutableArray array];
    
    [GlobalDatabaseQueue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM shoppingList"];
        while ([rs next]) {
            
            NSString *name = [rs stringForColumn:@"listTitle"];
            NSString *listId = [rs stringForColumn:@"listId"];
            NSString *listOwner = [rs stringForColumn:@"listOwner"];
            NSString *storeToShop = [rs stringForColumn:@"storeToShop"];
            NSInteger isShared = [rs intForColumn:@"isShared"];
           
            NSMutableDictionary *item = [@{@"listTitle":name, @"listId":listId, @"listOwner":(listOwner?:@""), @"storeToShop":(storeToShop?:@""), @"isShared":@(isShared)} mutableCopy];
            [lists addObject:item];
        }
    }];
    
    return lists;
}

-(NSMutableArray*)defaultItems{
    __block NSMutableArray* items = [NSMutableArray array];
    
    [GlobalDatabaseQueue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM DefaultItems"];
        while ([rs next]) {
            
            NSString *name = [rs stringForColumn:@"name"];
            NSString *category = [rs stringForColumn:@"category"];
            NSInteger productId = [rs intForColumn:@"productId"];
            NSMutableDictionary *item = [@{@"name":name, @"category":category, @"productId":@(productId), @"checked":@(false)} mutableCopy];
            [items addObject:item];
        }
    }];
    
    return items;
}

-(NSMutableArray *)itemsForList:(NSString*)listId{
    __block NSMutableArray* items = [NSMutableArray array];
    
    [GlobalDatabaseQueue inDatabase:^(FMDatabase *db) {
        
        NSString *storeInfo = nil;
        FMResultSet *rs0 = [db executeQuery:@"SELECT storeToShop FROM shoppingList WHERE listid = ?", listId];
        while ([rs0 next]) {
            storeInfo = [rs0 stringForColumnIndex:0];
        }
        
        
        FMResultSet *rs1 = [db executeQuery:@"SELECT * FROM Items WHERE listid = ?", listId];
        while ([rs1 next]) {
            
            NSInteger collectionStatus = [rs1 intForColumn:@"collectionStatus"];
            NSInteger productId = [rs1 intForColumn:@"productId"];
            NSMutableDictionary *item = [@{@"collectionStatus":@(collectionStatus), @"productId":@(productId)} mutableCopy];

            
            if (storeInfo.length) {
                FMResultSet *rs2 = [db executeQuery:@"SELECT aisle FROM DefaultItems WHERE productId=?",@(productId)];
                while ([rs2 next]) {
                    [item setObject:[rs2 stringForColumnIndex:0] forKey:@"aisle"];
                }
            }
            
            FMResultSet *rs3 = [db executeQuery:@"SELECT name FROM DefaultItems WHERE productId=?",@(productId)];
            while ([rs3 next]) {
                [item setObject:[rs3 stringForColumnIndex:0] forKey:@"name"];
            }
            
            [items addObject:item];
        }
    }];
    
    return items;
}

-(NSString *)user{
    __block NSString* str = @"";
    
    [GlobalDatabaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT username FROM userMaster"];
        while ([rs next]) {
            str=[rs stringForColumnIndex:0];
        }
    }];
    return str;
}
@end
