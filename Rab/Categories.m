//
//  Categories.m
//  Rab
//
//  Created by Sergey Petrov on 2/27/14.
//  Copyright (c) 2014 supudo.net. All rights reserved.
//

#import "Categories.h"
#import "CategoryCell.h"
#import "AsyncImageView.h"

@interface Categories ()
@property (nonatomic, strong) NSMutableArray *arrCategories;
@property int selectedRow;
@end

@implementation Categories

@synthesize arrCategories, fsCategories;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setTitle:NSLocalizedString(@"Categories", @"Categories")];
    self.selectedRow = 0;
    self.arrCategories = self.fsCategories;
    [self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"openSubCategories"]) {
        Categories *ce = (Categories *)segue.destinationViewController;
        [ce setFsCategories:[[self.fsCategories objectAtIndex:self.selectedRow] objectAtIndex:3]];
        [ce setIsTop:NO];
    }
}

#pragma mark - Table delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.arrCategories count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CategoryCell *cell = nil;
    if (self.isTop)
        cell = [tableView dequeueReusableCellWithIdentifier:@"FSCategoryCell" forIndexPath:indexPath];
    else
        cell = [tableView dequeueReusableCellWithIdentifier:@"FSCategoryCell2" forIndexPath:indexPath];
    [cell setAccessoryType:UITableViewCellAccessoryNone];
    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
    [cell setBackgroundColor:[UIColor clearColor]];
    
    NSMutableArray *cat = [self.arrCategories objectAtIndex:indexPath.row];

    cell.imgThumbnail.imageURL = [NSURL URLWithString:[cat objectAtIndex:2]];

    [cell.txtTitle setText:[cat objectAtIndex:1]];
    [cell.txtTitle setTextColor:[UIColor darkGrayColor]];
    [cell.txtTitle setFont:[UIFont fontWithName:[RABSettings sharedInstance].fontName size:18.0]];
    [cell.txtTitle setBackgroundColor:[UIColor whiteColor]];
    [cell.txtTitle setUserInteractionEnabled:NO];
    [cell.txtTitle.layer setBorderWidth:2.0];
    [cell.txtTitle.layer setCornerRadius:2.0];
    [cell.txtTitle.layer setBorderColor:[UIColor clearColor].CGColor];
    [cell.txtTitle.layer setShadowColor:[UIColor grayColor].CGColor];
    [cell.txtTitle.layer setShadowOffset:CGSizeZero];
    [cell.txtTitle.layer setShadowRadius:4.0];
    [cell.txtTitle.layer setShadowOpacity:0.7];
    [cell.txtTitle sizeToFit];
    CGPoint p = cell.txtTitle.center;
    p.y = cell.frame.size.height / 2;
    [cell.txtTitle setCenter:p];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0.0, cell.contentView.frame.size.width, 1)];
    lineView.backgroundColor = [UIColor darkGrayColor];
    [cell.contentView addSubview:lineView];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedRow = indexPath.row;
    if (self.isTop) {
        [RABSettings sharedInstance].fsSelectedCategoryID = [[self.arrCategories objectAtIndex:self.selectedRow] objectAtIndex:0];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[RABSettings sharedInstance].fsSelectedCategoryID forKey:@"fsSelectedCategoryID"];
        [defaults synchronize];
        [self.navigationController popToRootViewControllerAnimated:YES];

        //[self performSegueWithIdentifier:@"openSubCategories" sender:self];
        //[self.tableView reloadData];
    }
    else {
        [RABSettings sharedInstance].fsSelectedCategoryID = [[self.arrCategories objectAtIndex:self.selectedRow] objectAtIndex:0];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

@end
