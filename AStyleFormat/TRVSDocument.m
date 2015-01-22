//
//  NSDocument+TRVSClangFormat.m
//  ClangFormat
//
//  Created by Travis Jeffery on 1/11/14.
//  Modifided by Edward Chen on 1/22/15.
//  Copyright (c) 2014 Travis Jeffery. All rights reserved.
//

#import "TRVSDocument.h"
#import <objc/runtime.h>
#import "TRVSFormatter.h"
#import "TRVSXcode.h"
#import "AStyleHooker.h"

static BOOL trvs_formatOnSave;

@interface IDESourceCodeDocument(Hook)
- (void) saveDocumentWithDelegate_:(id) delegate
                   didSaveSelector:(SEL) didSaveSelector
                       contextInfo:(void *) contextInfo;


- (void) autosaveDocumentWithDelegate_:(id) delegate
                   didAutosaveSelector:(SEL) didAutosaveSelector
                           contextInfo:(void *) contextInfo;
@end

@interface IDERunPauseContinueToolbarButton(HooK)
- (void) performRunAction_:(id) arg1;
@end

@interface IDEWorkspaceTabController(Hook)
- (void) buildActiveRunContext_:(id) arg1;
- (void) runActiveRunContext_:(id) arg1;
@end

@implementation TRVSDocument

- (void) saveDocumentWithDelegate:(id) delegate
                  didSaveSelector:(SEL) didSaveSelector
                      contextInfo:(void *) contextInfo
{
    if ([TRVSDocument trvs_shouldFormatBeforeSaving:(IDESourceCodeDocument *) self])
    {
        [[TRVSFormatter sharedFormatter] formatDocument:(IDESourceCodeDocument *) self];
    }
    
    [(IDESourceCodeDocument *) self saveDocumentWithDelegate_:delegate
                                              didSaveSelector:didSaveSelector
                                                  contextInfo:contextInfo];
}

- (void) autosaveDocumentWithDelegate:(id) delegate
                  didAutosaveSelector:(SEL) didAutosaveSelector
                          contextInfo:(void *) contextInfo
{
    if ([TRVSDocument trvs_shouldFormatBeforeSaving:(IDESourceCodeDocument *) self])
    {
        [[TRVSFormatter sharedFormatter] formatDocument:(IDESourceCodeDocument *) self];
    }
    
    [(IDESourceCodeDocument *) self autosaveDocumentWithDelegate_:delegate
                                              didAutosaveSelector:didAutosaveSelector
                                                      contextInfo:contextInfo];
}

+ (void) hook:(NSString *) method
{
    NSString *cls = @"IDESourceCodeDocument";
    NSString *thisCls = NSStringFromClass([self class]);
    [AStyleHooker hookClass:cls method:method byClass:thisCls method:method];
}

+ (void) unhook:(NSString *) method
{
    NSString *cls = @"IDESourceCodeDocument";
    [AStyleHooker unhookClass:cls method:method];
}

+ (void) hook
{
    [self hook:@"saveDocumentWithDelegate:didSaveSelector:contextInfo:"];
    [self hook:@"autosaveDocumentWithDelegate:didAutosaveSelector:contextInfo:"];
}

+ (void) unhook
{
    [self unhook:@"saveDocumentWithDelegate:didSaveSelector:contextInfo:"];
    [self unhook:@"autosaveDocumentWithDelegate:didAutosaveSelector:contextInfo:"];
}

+ (void) settrvs_formatOnSave:(BOOL) formatOnSave
{
    trvs_formatOnSave = formatOnSave;
}

+ (BOOL) trvs_formatOnSave
{
    return trvs_formatOnSave;
}

+ (BOOL) trvs_shouldFormatBeforeSaving:(NSDocument *) document
{
    return [self trvs_formatOnSave] &&
    [self trvs_shouldFormat:document] &&
    [TRVSXcode sourceCodeDocument] == document;
}

+ (BOOL) trvs_shouldFormat:(NSDocument *) document
{
    return [[NSSet setWithObjects:@"c", @"h", @"cpp", @"cc", @"hpp", @"ipp", @"m", @"mm", nil] containsObject:[[document.fileURL pathExtension] lowercaseString]];
}

@end

@implementation IDERunPauseContinueToolbarButtonHook

+ (void) hook:(NSString *) method
{
    NSString *cls = @"IDERunPauseContinueToolbarButton";
    NSString *thisCls = NSStringFromClass([self class]);
    [AStyleHooker hookClass:cls method:method byClass:thisCls method:method];
}

+ (void) unhook:(NSString *) method
{
    NSString *cls = @"IDERunPauseContinueToolbarButton";
    [AStyleHooker unhookClass:cls method:method];
}

+ (void) hook
{
    [self hook:@"performRunAction:"];
}

+ (void) unhook
{
    [self unhook:@"performRunAction:"];
}

- (void) performRunAction:(id) obj
{
    if ([TRVSDocument trvs_shouldFormatBeforeSaving:[TRVSXcode sourceCodeDocument]])
    {
        [[TRVSFormatter sharedFormatter] formatDocument:[TRVSXcode sourceCodeDocument]];
    }
    
    [(IDERunPauseContinueToolbarButton *) self performRunAction_:obj];
}

@end

@implementation IDEWorkspaceTabControllerHook

+ (void) hook:(NSString *) method
{
    NSString *cls = @"IDEWorkspaceTabController";
    NSString *thisCls = NSStringFromClass([self class]);
    [AStyleHooker hookClass:cls method:method byClass:thisCls method:method];
}

+ (void) unhook:(NSString *) method
{
    NSString *cls = @"IDEWorkspaceTabController";
    [AStyleHooker unhookClass:cls method:method];
}

+ (void) hook
{
    [self hook:@"buildActiveRunContext:"];
    [self hook:@"runActiveRunContext:"];
}

+ (void) unhook
{
    [self unhook:@"buildActiveRunContext:"];
    [self unhook:@"runActiveRunContext:"];
}

- (void) buildActiveRunContext:(id) obj
{
    if ([TRVSDocument trvs_shouldFormatBeforeSaving:[TRVSXcode sourceCodeDocument]])
    {
        [[TRVSFormatter sharedFormatter] formatDocument:[TRVSXcode sourceCodeDocument]];
    }
    
    [(IDEWorkspaceTabController *) self buildActiveRunContext_:obj];
}

- (void) runActiveRunContext:(id) obj
{
    if ([TRVSDocument trvs_shouldFormatBeforeSaving:[TRVSXcode sourceCodeDocument]])
    {
        [[TRVSFormatter sharedFormatter] formatDocument:[TRVSXcode sourceCodeDocument]];
    }
    
    [(IDEWorkspaceTabController *) self runActiveRunContext_:obj];
}

@end