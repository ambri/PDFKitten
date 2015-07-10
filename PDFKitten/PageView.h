#import <UIKit/UIKit.h>
#import "Page.h"

@class PageView;
@class PDFPageDetailsView;

@protocol PageViewDelegate <NSObject>

#pragma mark - Required

/* Asks the delegate how many pages are in the document */
- (NSInteger)numberOfPagesInPageView:(PageView *)pageView;

/* Asks the delegate for a page view object */
- (Page *)pageView:(PageView *)pageView viewForPage:(NSInteger)page;

#pragma mark Optional

@optional

/* Tells the delegate when the document stopped scrolling at a page */
- (void)pageView:(PageView *)pageView didScrollToPage:(NSInteger)pageNumber;

/* Asks the delegate for a keyword */
- (NSString *)keywordForPageView:(PageView *)pageView;

/* Detailed view for page */
- (PDFPageDetailsView *)pageView:(PageView *)pageView detailedViewForPage:(NSInteger)page;

@end

#pragma mark

@interface PageView : UIView <UIScrollViewDelegate> {
    UIScrollView *_scrollView;
    
    NSInteger numberOfPages;
    NSInteger pageNumber;
    BOOL verticalScroll;
    NSMutableSet *visiblePages;
    IBOutlet id <PageViewDelegate> __unsafe_unretained dataSource;
}

#pragma mark -

/* Called when user has pressed the info button */
- (IBAction)detailedInfoButtonPressed:(id)sender;

/* Causes the page view to reload pages */
- (void)reloadData;

/* Scroll to a specific page */
- (void)setPage:(NSInteger)aPage animated:(BOOL)animated;

/* Page at the given index */
- (Page *)pageAtIndex:(NSInteger)index;

/* The page currently visible */
@property(nonatomic, assign) NSInteger page;

/* Data source for pages */
@property(nonatomic, unsafe_unretained) id <PageViewDelegate> dataSource;

- (void)setVerticalScroll:(BOOL)vertical;

- (void)setSelections:(NSArray *)array;

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation;

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation;

- (void)setPagedHyperlinks:(NSDictionary *)pagedHyperlinks;
@end
