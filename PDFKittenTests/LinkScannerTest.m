//
//  LinkScannerTest.m
//  PDFKitten
//
//  Created by Adam Boardman on 06/12/2013.
//  Copyright (c) 2013 Chalmers Göteborg. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PDFKitten.h"

@interface LinkScannerTest : XCTestCase

@end

@implementation LinkScannerTest

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testLinkScanner
{
    NSURL *pdfURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"hyperlink" ofType:@"pdf"]];
    PDFKitten *pdfKitten = [PDFKitten loadDocument:pdfURL];
    [pdfKitten findHyperlinksForPage:0];
    while ([pdfKitten hyperlinkFindInProgress]) {
        sleep(1);
    }
    NSArray *links=[pdfKitten getHyperlinksForPage:0];
    NSLog(@"links: %@",links);
    XCTAssertTrue([links count] == 3, @"wrong number of links");
}

@end
