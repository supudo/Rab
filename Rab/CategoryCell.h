//
//  CategoryCell.h
//  Rab
//
//  Created by Sergey Petrov on 2/27/14.
//  Copyright (c) 2014 supudo.net. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncImageView.h"

@class CategoryCell;

@interface CategoryCell : UITableViewCell

@property (weak, nonatomic) IBOutlet AsyncImageView *imgThumbnail;
@property (weak, nonatomic) IBOutlet UITextView *txtTitle;

@end
