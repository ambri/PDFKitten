//
//  SearchResultsViewController.m
//  PDFKitten
//

#import "SearchResultsViewController.h"
#import "PDFSelection.h"

@interface SearchResultsViewController ()

@end

@implementation SearchResultsViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_results count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"SearchResultsCell";

    UITableViewCell *cell = (UITableViewCell *) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

    NSInteger row = [indexPath row];
    PDFSelection *selection = [_results objectAtIndex:(NSUInteger) row];
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:selection.searchContext];
    NSRange keywordRange = [selection.searchContext rangeOfString:_keyword options:NSCaseInsensitiveSearch];
    [string addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:keywordRange];

    [cell.textLabel setAttributedText:string];
    [cell.detailTextLabel setText:[@(selection.pageNumber) description]];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = [indexPath row];
    PDFSelection *selection = [_results objectAtIndex:(NSUInteger) row];
    [_delegate searchSelectionPicked:selection];
}


@end
