//
//  ViewController.h
//  SQLite3Test
//
//  Created by yaodd on 13-7-9.
//  Copyright (c) 2013年 jitsun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import<CoreBluetooth/CoreBluetooth.h>
//#import  <CoreBluetooth/CBCentral.h>
//#import  <CoreBluetooth/CBCentralManager.h>
//#import  <CoreBluetooth/CBPeripheralManager.h>
//#import  <CoreBluetooth/CBUUID.h>
@interface ViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) IBOutlet UITextField *fieldName;
@property (strong, nonatomic) IBOutlet UITextField *fieldAge;
//@property (strong, nonatomic) IBOutlet UITextField *fieldAddress;
@property (strong, nonatomic) IBOutlet UITextField *fieldCity;
@property (strong, nonatomic) IBOutlet UIButton *insertButton;
@property (strong, nonatomic) IBOutlet UITableView *PeopleTableView;


@property (nonatomic, retain) NSMutableArray *arrPeople;

@end
