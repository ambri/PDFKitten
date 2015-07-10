//
//  PDFKittenTest.m
//  PDFKitten
//
//  Created by Adam Boardman on 12/11/2013.
//  Copyright (c) 2013 Chalmers Göteborg. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PDFKitten.h"

@interface PDFKittenTest : XCTestCase

@end

@implementation PDFKittenTest

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

- (void)testCatsInKurt
{
    NSURL *pdfURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Kurt the Cat" ofType:@"pdf"]];
    PDFKitten *pdfKitten = [PDFKitten loadDocument:pdfURL];
    [pdfKitten startSearchFromPage:0 withKeyword:@"cat"];
    while ([pdfKitten scanInProgress]) {
        sleep(1);
    }
    NSArray *cats=[pdfKitten getSelections];
    XCTAssertTrue([cats count] == 4, @"wrong number of cats");
}

@end
