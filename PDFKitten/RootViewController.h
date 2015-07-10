#import "PageViewController.h"
#import "PageView.h"
#import "PDFKitten.h"
#import "PDFSelection.h"
#import "SearchResultsViewController.h"

@interface RootViewController : UIViewController <PageViewDelegate, UIPopoverControllerDelegate, UISearchBarDelegate, SearchResultsDelegate, PDFKittenDelegate> {
	PDFKitten *pdfKitten;
    UIPopoverController *libraryPopover;
	IBOutlet PageView *pageView;
	IBOutlet UISearchBar *searchBar;
	NSString *keyword;
}

@property (unsafe_unretained, nonatomic, readonly) NSString *documentPath;

@end
