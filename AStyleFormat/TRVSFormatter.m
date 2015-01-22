//
//  TRVSFormatter.m
//  ClangFormat
//
//  Created by Travis Jeffery on 1/9/14.
//  Modifided by Edward Chen on 1/22/15..
//  Copyright (c) 2014 Travis Jeffery. All rights reserved.
//

#import "TRVSFormatter.h"
#import "TRVSXcode.h"
#import "TRVSCodeFragment.h"
#import "TRVSDocument.h"

@interface TRVSFormatter()

@property (nonatomic, copy) NSSet *supportedFileTypes;

@end

@implementation TRVSFormatter

+ (instancetype) sharedFormatter
{
    static id sharedFormatter = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^
                  {
                      sharedFormatter = [[self alloc] initWithStyle:[[NSBundle bundleForClass:self] pathForResource:@"astylerc" ofType:@""]
                                                     executablePath:[[NSBundle bundleForClass:self] pathForResource:@"astyle" ofType:@""]];
                  });
    
    return sharedFormatter;
}

- (instancetype) initWithStyle:(NSString *) stylePath
                executablePath:(NSString *) executablePath
{
    if (self = [self init])
    {
        self.styleFilePath = stylePath;
        self.executablePath = executablePath;
    }
    return self;
}

- (void) formatActiveFile
{
    [self formatRanges:@[ [NSValue valueWithRange:[TRVSXcode wholeRangeOfTextView]] ]
            inDocument:[TRVSXcode sourceCodeDocument]];
}

- (void) formatSelectedCharacters
{
    if (![TRVSXcode textViewHasSelection])
    {
        return;
    }
    
    DVTSourceTextView *textView = [TRVSXcode textView];
    [self formatRanges:[textView selectedRanges]
            inDocument:[TRVSXcode sourceCodeDocument]];
}

- (void) formatSelectedFiles
{
    [[TRVSXcode selectedFileNavigableItems]
     enumerateObjectsUsingBlock: ^ (IDEFileNavigableItem * fileNavigableItem,
                                    NSUInteger idx,
                                    BOOL * stop)
     {
         NSDocument *document = [IDEDocumentController retainedEditorDocumentForNavigableItem:fileNavigableItem
                                                                                        error:NULL];
         
         if ([document isKindOfClass:NSClassFromString(@"IDESourceCodeDocument") ])
         {
             IDESourceCodeDocument *sourceCodeDocument = (IDESourceCodeDocument *) document;
             
             [self formatRanges:@[
                                  [NSValue valueWithRange:NSMakeRange(0, [[sourceCodeDocument textStorage] length]) ]
                                  ]
                     inDocument:sourceCodeDocument];
             
             [document saveDocument:nil];
         }
         
         [IDEDocumentController releaseEditorDocument:document];
     }];
}

- (void) formatDocument:(IDESourceCodeDocument *) document
{
    NSScrollView *scrollView = [[TRVSXcode textView] enclosingScrollView];
    NSClipView *clipView = [scrollView contentView];
    NSRect rect = clipView.visibleRect;
    
    NSUInteger location = [[TRVSXcode textView] selectedRange].location;
    NSUInteger length = [[document textStorage] length];
    
    [self formatRanges:@[ [NSValue valueWithRange:NSMakeRange(0, length) ] ]
            inDocument:document];
    
    if (location >= ([[document textStorage] length] - 1))
    {
        location = [[document textStorage] length] - 1;
    }
    
    [clipView scrollToPoint:rect.origin];
    [scrollView reflectScrolledClipView:clipView];
    
    NSRange range = NSMakeRange(location, 0);
    [[TRVSXcode textView] setSelectedRange:range];
}

#pragma mark - Private

- (void) formatRanges:(NSArray *) ranges
           inDocument:(IDESourceCodeDocument *) document
{
    if (![TRVSDocument trvs_shouldFormat:document])
    {
        return;
    }
    
    DVTSourceTextStorage *textStorage = [document textStorage];
    
    NSArray *lineRanges = [self lineRangesOfCharacterRanges:ranges usingTextStorage:textStorage];
    NSArray *continuousLineRanges = [self continuousLineRangesOfRanges:lineRanges];
    [self fragmentsOfContinuousLineRanges:continuousLineRanges
                         usingTextStorage:textStorage
                             withDocument:document
                                    block: ^ (NSArray * fragments, NSArray * errors)
     {
         if (errors.count == 0)
         {
             NSArray *selectionRanges = [self selectionRangesAfterReplacingFragments:fragments
                                                                    usingTextStorage:textStorage
                                                                        withDocument:document];
             
             if (selectionRanges.count > 0)
             {
                 [[TRVSXcode textView] setSelectedRanges:selectionRanges];
                 [[TRVSXcode textView] indentSelection:[TRVSXcode textView]];
             }
         }
         else
         {
             NSAlert *alert = [NSAlert new];
             alert.messageText = [(NSError *) errors.firstObject localizedDescription];
             [alert runModal];
         }
     }];
}

- (NSArray *) selectionRangesAfterReplacingFragments:(NSArray *) fragments
                                    usingTextStorage:(DVTSourceTextStorage *) textStorage
                                        withDocument:(IDESourceCodeDocument *) document
{
    NSMutableArray *selectionRanges = [[NSMutableArray alloc] init];
    
    [fragments enumerateObjectsUsingBlock: ^ (TRVSCodeFragment * fragment,
                                              NSUInteger idx,
                                              BOOL * stop)
     {
         [textStorage beginEditing];
         
         [textStorage replaceCharactersInRange:fragment.range
                                    withString:fragment.formattedString
                               withUndoManager:document.undoManager];
         
         [self addSelectedRangeToSelectedRanges:selectionRanges
                               usingTextStorage:textStorage];
         
         [textStorage endEditing];
     }];
    
    return selectionRanges;
}

- (void) addSelectedRangeToSelectedRanges:(NSMutableArray *) selectionRanges
                         usingTextStorage:(DVTSourceTextStorage *) textStorage
{
    if (selectionRanges.count > 0)
    {
        NSUInteger i = 0;
        
        while (i < selectionRanges.count)
        {
            NSRange range = [[selectionRanges objectAtIndex:i] rangeValue];
            range.location += [textStorage changeInLength];
            [selectionRanges replaceObjectAtIndex:i
                                       withObject:[NSValue valueWithRange:range]];
            i++;
        }
    }
    
    NSRange editedRange = [textStorage editedRange];
    if (editedRange.location != NSNotFound)
    {
        [selectionRanges addObject:[NSValue valueWithRange:editedRange]];
    }
}

- (void) fragmentsOfContinuousLineRanges:(NSArray *) continuousLineRanges
                        usingTextStorage:(DVTSourceTextStorage *) textStorage
                            withDocument:(IDESourceCodeDocument *) document
                                   block:(void (^)(NSArray *fragments,
                                                   NSArray *errors)) block
{
    NSMutableArray *fragments = [[NSMutableArray alloc] init];
    NSMutableArray *errors = [[NSMutableArray alloc] init];
    
    NSString *executablePath = self.executablePath;
    
    [continuousLineRanges enumerateObjectsUsingBlock: ^ (NSValue * rangeValue,
                                                         NSUInteger idx,
                                                         BOOL * stop)
     {
         NSRange characterRange =
         [textStorage characterRangeForLineRange:[rangeValue rangeValue]];
         
         if (characterRange.location == NSNotFound)
         {
             return;
         }
         
         NSString *string = [[textStorage string] substringWithRange:characterRange];
         
         if (!string.length)
         {
             return;
         }
         
         TRVSCodeFragment *fragment = [TRVSCodeFragment fragmentUsingBlock: ^ (TRVSCodeFragmentBuilder * builder)
                                       {
                                           builder.string = string;
                                           builder.range = characterRange;
                                           builder.fileURL = document.fileURL;
                                       }];
         
         __weak typeof(fragment) weakFragment = fragment;
         [fragment formatWithStyle:self.styleFilePath
     usingAStyleFormatAtLaunchPath:executablePath
                             block: ^ (NSString * formattedString,
                                       NSError * error)
          {
              __strong typeof(weakFragment)
              strongFragment = weakFragment;
              if (error)
              {
                  [errors addObject:error];
                  *stop = YES;
              }
              else
              {
                  [fragments addObject:strongFragment];
              }
          }];
     }];
    
    block(fragments, errors);
}

- (NSArray *) lineRangesOfCharacterRanges:(NSArray *) characterRanges
                         usingTextStorage:(DVTSourceTextStorage *) textStorage
{
    NSMutableArray *lineRanges = [[NSMutableArray alloc] init];
    
    [characterRanges enumerateObjectsUsingBlock: ^ (NSValue * rangeValue,
                                                    NSUInteger idx,
                                                    BOOL * stop)
     {
         [lineRanges
          addObject:[NSValue valueWithRange:[textStorage
                                             lineRangeForCharacterRange:
                                             [rangeValue rangeValue]]]];
     }];
    
    return lineRanges;
}

- (NSArray *) continuousLineRangesOfRanges:(NSArray *) ranges
{
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    
    [ranges enumerateObjectsUsingBlock: ^ (NSValue * rangeValue,
                                           NSUInteger idx,
                                           BOOL * stop)
     {
         [indexSet addIndexesInRange:[rangeValue rangeValue]];
     }];
    
    NSMutableArray *continuousRanges = [[NSMutableArray alloc] init];
    
    [indexSet enumerateRangesUsingBlock: ^ (NSRange range, BOOL * stop)
     {
         [continuousRanges addObject:[NSValue valueWithRange:range]];
     }];
    
    return continuousRanges;
}

@end
