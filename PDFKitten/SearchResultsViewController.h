//
//  SearchResultsViewController.h
//  PDFKitten
//

#import <UIKit/UIKit.h>

@class SearchResultsViewController;
@class PDFSelection;

@protocol SearchResultsDelegate

// sent when the user selects a row in the recent searches list

- (void)searchSelectionPicked:(PDFSelection *)selection;

@end


@interface SearchResultsViewController : UITableViewController

@property(nonatomic, weak) id <SearchResultsDelegate> delegate;

@property(nonatomic, retain) NSString *keyword;
@property(nonatomic, retain) NSArray *results;

@end
