#import "RootViewController.h"  
#import "PDFPage.h"
#import "DocumentsView.h"
#import "PDFFontCollection.h"
#import "PDFPageDetailsView.h"

@interface RootViewController ()

@property (nonatomic) SearchResultsViewController *searchResultsViewController;

@property (nonatomic) UIPopoverController *recentSearchesPopoverController;

@end

@implementation RootViewController {
    NSInteger pageNumber;
}

#pragma mark - Initialization

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder]))
	{
        NSURL *pdfURL = [NSURL fileURLWithPath:self.documentPath];
        pdfKitten = [PDFKitten loadDocument:pdfURL];
        [pdfKitten setDelegate:self];
	}
	return self;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    if ([popoverController isEqual:libraryPopover])
    {
         libraryPopover = nil;
    }
}

- (void)didSelectDocument:(NSURL *)url
{
	[libraryPopover dismissPopoverAnimated:YES];
    libraryPopover = nil;

    pdfKitten = [PDFKitten loadDocument:url];
    [pdfKitten setDelegate:self];
    [pageView setSelections:nil];
    [pageView setPagedHyperlinks:nil];
	[pageView reloadData];
}

- (IBAction)showLibraryPopover:(UIBarButtonItem *)sender
{
    if (libraryPopover)
    {
        [libraryPopover dismissPopoverAnimated:NO];
         libraryPopover = nil;
        return;
    }
    
    DocumentsView *docView = [[DocumentsView alloc] init];
	docView.delegate = self;
    libraryPopover = [[UIPopoverController alloc] initWithContentViewController:docView];
    libraryPopover.delegate = self;
    [libraryPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
}

#pragma mark PageViewDelegate

/* The number of pages in the current PDF document */
- (NSInteger)numberOfPagesInPageView:(PageView *)pageView
{
	return [pdfKitten numberOfPages];
}

- (PDFFontCollection *)activeFontCollection
{
	Page *page = [pageView pageAtIndex:pageView.page];
	PDFContentView *pdfPage = (PDFContentView *) [(PDFPage *) page contentView];
	return [[pdfPage scanner] fontCollection];
}

/* Return the detailed view corresponding to a page */
- (PDFPageDetailsView *)pageView:(PageView *)aPageView detailedViewForPage:(NSInteger)page
{
	PDFFontCollection *collection = [self activeFontCollection];
	PDFPageDetailsView *detailedView = [[PDFPageDetailsView alloc] initWithFont:collection];
	return detailedView;
}

// TODO: Assign page to either the page or its content view, not both.

/* Page view object for the requested page */
- (Page *)pageView:(PageView *)aPageView viewForPage:(NSInteger)pNumber {
    pageNumber = pNumber;
	PDFPage *page = nil;
	if (page) {
        [page setMinimumZoomScale:0.5];
        [page setZoomScale:1 animated:NO];
    } else {
		page = [[PDFPage alloc] initWithFrame:CGRectZero];
	}

    page.pageNumber = pageNumber;
    CGPDFPageRef pdfPage = [pdfKitten getPage:pageNumber];
    [pdfKitten findHyperlinksForPage:pageNumber];
    [page setPage:pdfPage];
    
    return page;
}

- (NSString *)keywordForPageView:(PageView *)pageView
{
	return keyword;
}

// TODO: add user interface for choosing document

- (NSString *)documentPath
{
	return [[NSBundle mainBundle] pathForResource:@"Kurt the Cat" ofType:@"pdf"];
}

#pragma mark Search

- (void)searchBarSearchButtonClicked:(UISearchBar *)aSearchBar
{
	keyword = [aSearchBar text];
    if ([keyword length] > 0) {
        [pdfKitten startSearchFromPage:pageNumber withKeyword:keyword];
        [self.searchResultsViewController setKeyword:keyword];
    }

	[aSearchBar resignFirstResponder];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)aSearchBar {
    if (self.recentSearchesPopoverController == nil) {
        self.searchResultsViewController = [[SearchResultsViewController alloc] initWithStyle:UITableViewStylePlain];
        self.searchResultsViewController.delegate = self;
        
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.searchResultsViewController];
        navigationController.navigationBarHidden = TRUE;

        // Create the popover controller to contain the navigation controller.
        UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:navigationController];
        popover.delegate = self;

        // Ensure the popover is not dismissed if the user taps in the search bar by adding
        // the search bar to the popover's list of pass-through views.
        popover.passthroughViews = @[searchBar];

        self.recentSearchesPopoverController = popover;
    }

    [self.recentSearchesPopoverController presentPopoverFromRect:[searchBar bounds] inView:searchBar permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)scanResults:(NSArray *)selections {
    [pageView setSelections:selections];
    [self.searchResultsViewController setResults:selections];
    [self.searchResultsViewController.tableView reloadData];
}

- (void)scanResultsUpdated:(NSArray *)selections {
    [self performSelectorOnMainThread:@selector(scanResults:) withObject:selections waitUntilDone:YES];
}

- (void)foundHyperlinks:(NSDictionary *)pagedHyperlinks {
    [pageView setPagedHyperlinks:pagedHyperlinks];
}

- (void)hyperlinks:(NSDictionary *)pagedHyperlinks {
    [self performSelectorOnMainThread:@selector(foundHyperlinks:) withObject:pagedHyperlinks waitUntilDone:YES];
}

- (void)searchSelectionPicked:(PDFSelection*)selection {
    [pageView setPage:selection.pageNumber-1];
}

@end
