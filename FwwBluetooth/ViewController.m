

#import "ViewController.h"
#import <sqlite3.h>
#import "cellItem.h"
#import "PeopleCell.h"
#import<CoreBluetooth/CoreBluetooth.h>
//#import  <CoreBluetooth/CBCentral.h>
//#import  <CoreBluetooth/CBCentralManager.h>
//#import  <CoreBluetooth/CBUUID.h>
//#import  <CoreBluetooth/CBPeripheral.h>
//#import  <CoreBluetooth/CBCharacteristic.h>
//#import  <CoreBluetooth/CBService.h>

@interface ViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>
{
    CBCharacteristic  *wforcharacteristic;
}
@property (nonatomic, retain) CBCentralManager *centralManager;
@property (nonatomic, retain) CBPeripheral *peripheral;
//@property (nonatomic, retain) CBPeripheralManager *connect;
@property (weak, nonatomic) IBOutlet UILabel *label1;

@property (weak, nonatomic) IBOutlet UITextField *text;
@end


@implementation ViewController
@synthesize centralManager,text,label1;
@synthesize arrPeople;
//@synthesize fieldAddress;
@synthesize fieldAge;
@synthesize fieldCity;
@synthesize fieldName;
@synthesize insertButton;
@synthesize PeopleTableView;
- (NSString *)dataFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(
                                                         NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"data.sqlite"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    self.centralManager.delegate=self;
    
    //tableView中显示的数据包装
    arrPeople = [[NSMutableArray alloc]init];
    
    //建立表（程序第一次运行时建立）
    sqlite3 *database;
    if (sqlite3_open([[self dataFilePath] UTF8String], &database)
        != SQLITE_OK) {
        sqlite3_close(database);
        NSAssert(0, @"Failed to open database");
    }
    //建立表的SQL语句，主键为ROW，自增；其他键为NAME,AGE,ADDRESS,CITY。
    NSString *createSQL = @"CREATE TABLE IF NOT EXISTS PEOPLE "
    "(ROW INTEGER PRIMARY KEY AUTOINCREMENT, NAME TEXT, AGE INTEGER, ADDRESS TEXT, CITY TEXT);";
//将出错信心保存在errorMsg中
    char *errorMsg;
    
    if (sqlite3_exec (database, [createSQL UTF8String],
                      NULL, NULL, &errorMsg) != SQLITE_OK) {
        sqlite3_close(database);
        //如果出错，则输出errorMsg
        NSAssert(0, @"Error creating table: %s", errorMsg);
    }
    //查询数据库，并以ROW排序
    NSString *query = @"SELECT ROW, NAME, AGE, ADDRESS, CITY FROM PEOPLE ORDER BY ROW";
    sqlite3_stmt *statement;//至于这个参数，网上的说法“这个相当于ODBC的Command对象，用于保存编译好的SQL语句”；
    if (sqlite3_prepare_v2(database, [query UTF8String],
                           -1, &statement, nil) == SQLITE_OK)
    {
        while (sqlite3_step(statement) == SQLITE_ROW) {//对表中的数据进行遍历，并转为item加入arrPeople中
            NSLog(@"%lu",(unsigned long)arrPeople.count);
            cellItem *item = [[cellItem alloc]init];
            int row = sqlite3_column_int(statement, 1);
            char *nameChar = (char *)sqlite3_column_text(statement, 0);
            int age = sqlite3_column_int(statement,2);
            char *addressChar = (char *)sqlite3_column_text(statement,3);
            char *cityChar = (char *)sqlite3_column_text(statement, 4);
            NSLog(@"row:%d name:%s age:%d add:%s city:%s",row,nameChar,age,addressChar,cityChar);
            item.row = [[NSString alloc] initWithFormat:@"%d",row];
            item.age = [[NSString alloc] initWithFormat:@"%d",age];
            item.name = [[NSString alloc] initWithUTF8String:nameChar];
            item.address = [[NSString alloc] initWithUTF8String:addressChar];
            item.city = [[NSString alloc] initWithUTF8String:cityChar];
            [arrPeople addObject:item];
            
        }
        sqlite3_finalize(statement);//结束之前清除statement对象，
    }
    sqlite3_close(database);//关闭数据库
    
    //这几行代码是当程序在后台运行时执行的函数
    UIApplication *app = [UIApplication sharedApplication];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(applicationWillResignActive:)
     name:UIApplicationWillResignActiveNotification
     object:app];
    
    //插入数据的按钮；按多次就会插入多条
    [insertButton addTarget:self action:@selector(insertButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
}
//后台运行时执行的函数，也是执行插入数据的操作
- (void)applicationWillResignActive:(NSNotification *)notification
{
    [self insertData];//插入数据函数
}
//插入数据的按钮响应器
- (void)insertButtonPressed:(id)sender
{
    [self insertData];//插入数据函数
}
//插入数据函数的实现，用的是绑定变量的方法。
- (void)insertData
{
     int count = arrPeople.count;
    sqlite3 *database;
    if (sqlite3_open([[self dataFilePath] UTF8String], &database)
        != SQLITE_OK) {
        sqlite3_close(database);
        NSAssert(0, @"Failed to open database");
    }
    cellItem *item = [[cellItem alloc] init];
    item.row = [[NSString alloc]initWithFormat:@"%d",count];
    item.name = fieldName.text;
    item.age = fieldAge.text;
    item.address = label1.text;
    item.city = fieldCity.text;
    //插入或更新一行，不指定主键ROW··则ROW会自增
    //INSERT OR REPLACE实现了插入或更新两个操作
    char *update = "INSERT OR REPLACE INTO PEOPLE (NAME, AGE, ADDRESS, CITY) "
    "VALUES (?, ?, ?, ?);";
    char *errorMsg = NULL;
    sqlite3_stmt *stmt;
    if (sqlite3_prepare_v2(database, update, -1, &stmt, nil)
        == SQLITE_OK) {
        
        sqlite3_bind_text(stmt, 1, [item.name UTF8String], -1, NULL);
        sqlite3_bind_int(stmt, 2, [item.age intValue]);
        sqlite3_bind_text(stmt, 3, [item.address UTF8String], -1, NULL);
        sqlite3_bind_text(stmt, 4, [item.city UTF8String], -1, NULL);
        
    }
    if (sqlite3_step(stmt) != SQLITE_DONE)
        NSAssert(0, @"Error updating table: %s", errorMsg);
    sqlite3_finalize(stmt);//结束之前清除statement变量
    
    sqlite3_close(database);//关闭数据库
    [arrPeople addObject:item];//tableView里的数据的增加
    [self.PeopleTableView reloadData];//动态更新tableView
    
    NSLog(@"insert %d",count);

}
//删除表中row = rowId的那一行
- (void)deleteData:(int)rowId
{
    sqlite3 *database;
    if (sqlite3_open([[self dataFilePath] UTF8String], &database)
        != SQLITE_OK) {
        sqlite3_close(database);
        NSAssert(0, @"Failed to open database");
    }
    char *errmsg;
    NSString *deleteRow = [[NSString alloc]initWithFormat:@"DELETE FROM PEOPLE WHERE ROW = %d",rowId];
    sqlite3_exec(database, [deleteRow UTF8String], NULL, NULL, &errmsg);
    NSLog(@"%s",errmsg);
    sqlite3_close(database);

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [arrPeople count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
       
    static NSString *PeopleCellIdentifier = @"PeopleCellIdentifier";
    //自定义的TableViewCell
    PeopleCell *cell = [tableView dequeueReusableCellWithIdentifier:
                             PeopleCellIdentifier];
    if (cell == nil) {
        cell = [[PeopleCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier: PeopleCellIdentifier];
    }
    
    NSInteger row = [indexPath row];
    cellItem *item = [arrPeople objectAtIndex:row];
    cell.row.text = [[NSString alloc]initWithFormat:@"%ld",(long)row];
    cell.name.text = item.name;
    cell.age.text = item.age;
    cell.address.text = item.address;
    cell.city.text = item.city;
    
    
    return  cell;
    
}



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    return 67;
}

#pragma Table view delegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //点击某一行则删除改行
    NSInteger row = [indexPath row];
    cellItem *item = [arrPeople objectAtIndex:row];
    [self deleteData:[item.row intValue]];//数据库中删除
    [arrPeople removeObjectAtIndex:row];//tableView数据中删除
    [self.PeopleTableView reloadData];//动态更新tableView
    
}
- (IBAction)text11:(id)sender {
    [self resignFirstResponder];
}


//开蓝牙
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSString * state;
    
    switch ([central state])
    {
        case CBCentralManagerStateUnsupported:
            state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;
        case CBCentralManagerStateUnauthorized:
            state = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBCentralManagerStatePoweredOff:
            state = @"Bluetooth is currently powered off.";
            break;
        case CBCentralManagerStatePoweredOn:
            state = @"work";
            break;
        case CBCentralManagerStateUnknown:
        default:
            ;
    }
    
    NSLog(@"中心设备的状态: %@", state);
    if([state isEqual:@"work"])
    {
        UIAlertView *alertView=[[UIAlertView alloc] initWithTitle:@"通知" message:@"蓝牙正常工作" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alertView show];
        
    }}
//扫描蓝牙
- (IBAction)scan:(id)sender {
    [self.centralManager scanForPeripheralsWithServices:nil options:nil];
}

- (IBAction)button:(UIButton *)sender {
    [self.centralManager cancelPeripheralConnection:self.peripheral];
}

/*- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
 {
 // static int i = 0;
 NSString *str = [NSString stringWithFormat:@"Did discover peripheral. peripheral: %@ rssi: %@, UUID: %@ advertisementData: %@ ", peripheral, RSSI, peripheral.identifier.UUIDString, advertisementData];
 NSLog(@"%@",str);
 [self.connect:peripheral];
 
 }
 - (IBAction)connect:(id)sender {
 [self.centralManager connectPeripheral:[self.discoverdPeriparals firstObject]  options:nil];
 }*/
//蓝牙特性值,并连接
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    
    if([peripheral.name hasPrefix:@"BT06"])
    {
        //[self connect:peripheral];
        NSString *str = [NSString stringWithFormat:@"Did discover peripheral. peripheral: %@ rssi: %@, UUID: %@ advertisementData: %@ ", peripheral, RSSI, peripheral.identifier.UUIDString, advertisementData];
        NSLog(@"%@",str);
        
        //peripheral.delegate = self;
        // [CBPeripheral  :peripheral];
        
        if([peripheral.name hasPrefix:@"BT06"])
        {
            //[self connect:peripheral];
            //[self.centralManager stopScan];
            peripheral.delegate = self;
            self.peripheral=peripheral;
            [centralManager  connectPeripheral:self.peripheral  options:nil];
            NSLog(@"连接外设:%@",peripheral);
        }
    }
    
}

//判断是否连接外设蓝牙

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    peripheral.delegate =self;
    
    if([peripheral.name hasPrefix:@"BT06"])    {
        
        NSLog(@"Peripheral connected");
        
        //发现周边所有服务
        [peripheral discoverServices:nil];
    }
    
}


//判断是否发现服务

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error{
    //    if (error)
    //    {
    //        //NSLog(@"Error updating value for characteristic %@ error: %@", characteristic.UUID, [error localizedDescription]);
    //               //return;
    //    }
    
    //    //    NSLog(@"收到的数据：%@",characteristic.value);
    //    //[self decodeData:characteristic.value];
    // [peripheral discoverServices:@[[CBUUID UUIDWithString:@"FFE0"]]];
    for (CBService *service in peripheral.services) {
        
        NSLog(@"Discovered service %@", service.UUID);
        
        if ([service.UUID isEqual:[CBUUID UUIDWithString:@"FFE0"]]) {
            
            NSLog(@"发现服务:%@", service.UUID);
            
            [peripheral discoverCharacteristics:nil forService:service];
            
        }
        
        
        
        NSLog(@"Discovering characteristics for service %@", peripheral.services);
        [peripheral discoverCharacteristics:nil forService:service];
    }}


//查询服务所带的特征值
- (void)peripheral:(CBPeripheral *)peripheral  didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        
        NSLog(@"Discovered characteristic %@", characteristic);
        
        
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"FFE1"]]) {
            NSLog(@"监听特征:%@",characteristic);//监听特征
            //  _writeCharacteristic = characteristic;
            [self.peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        // [peripheral writeValue:dataforCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
        NSLog(@"Reading value for characteristic %@", service.characteristics);
        [peripheral readValueForCharacteristic:characteristic];
        wforcharacteristic = characteristic;
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral  didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    //读取数据
    NSData *data = characteristic.value;
    NSLog(@"%@",data);
    NSString *shuju = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    label1.text=shuju;
    
    
    
    //    NSLog(@"Writing value for characteristic %@", characteristic.value);
    //    NSData *dataforcha=[[NSData alloc] init];
    //    [ self.peripheral writeValue:dataforcha forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    //
    //
    
}
//写数据

- (IBAction)send:(id)sender
{
    NSData *dataforcha;
    //  NSLog(@"Writing value for characteristic %@", characteristic.value);
    //定义一个字符串
    NSString *aString =[[NSString alloc]init];
    //把text的值赋值给aString
    aString=text.text;
    //把aString转换为数据类型为NSData；
    dataforcha = [aString dataUsingEncoding: NSUTF8StringEncoding];
    // NSData *dataforcha=[[NSD
    [self.peripheral writeValue:dataforcha forCharacteristic:wforcharacteristic type:CBCharacteristicWriteWithResponse];
    [self.text resignFirstResponder];
}

//- (void)writeValue:(NSData *)dataforcha forCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type
//{
//
//    NSLog(@"Writing value for characteristic %@", characteristic.value);
//    //定义一个字符串
//    NSString *aString =[[NSString alloc]init];
//    //把text的值赋值给aString
//    aString=text.text;
//    //把aString转换为数据类型为NSData；
//    dataforcha = [aString dataUsingEncoding: NSUTF8StringEncoding];
//       // NSData *dataforcha=[[NSData alloc] init];
//    //显示
//        //官方
////    NSLog(@"Writing value for characteristic %@", interestingCharacteristic);
//    [peripheral writeValue:dataToWrite forCharacteristic:interestingCharacteristic
//                      type:CBCharacteristicWriteWithResponse];
//


//}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    
    // NSLog(@"%lu", (unsigned long)characteristic.properties);
    //
    //    NSString *aString ;
    //   aString=text.text;
    //  NSData *ss = [aString dataUsingEncoding: NSUTF8StringEncoding];
    //    dataforcha=ss;
    ////    //NSData *data = [NSData dataWithBytes:[@"test" UTF8String] length:@"test".length];
    ////
    ////
    ////   // [peripheral writeValue:aData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    //    NSLog(@"阿萨德%@",aString);
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"FFE1"]])
    {
        NSLog(@"----数据更新----");
        NSLog(@"characteristic.value:%@",characteristic.value);
    }
}


@end
