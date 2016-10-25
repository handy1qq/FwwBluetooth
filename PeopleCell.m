//
//  PeopleCell.m
//  SQLite3_Test
//
//  Created by yaodd on 13-7-9.
//  Copyright (c) 2013年 jitsun. All rights reserved.
//  数据库内容的tableView的Cell

#import "PeopleCell.h"

@implementation PeopleCell
@synthesize city;
@synthesize name;
@synthesize address;
@synthesize age;
@synthesize row;
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
