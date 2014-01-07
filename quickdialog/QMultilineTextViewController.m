//
// Copyright 2011 ESCOZ Inc  - http://escoz.com
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
// file except in compliance with the License. You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
// ANY KIND, either express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//


#import "QuickDialog.h"

@interface QMultilineTextViewController ()

@end

@implementation QMultilineTextViewController {
    BOOL _viewOnScreen;
    BOOL _keyboardVisible;
    UITextView* _textView;
}

@synthesize textView = _textView;
@synthesize resizeWhenKeyboardPresented = _resizeWhenKeyboardPresented;
@synthesize willDisappearCallback = _willDisappearCallback;
@synthesize entryElement = _entryElement;
@synthesize entryCell = _entryCell;


- (id)initWithTitle:(NSString *)title
{
    if ((self = [super init]))
    {
        self.title = (title!=nil) ? title : NSLocalizedString(@"Note", @"Note");
        _textView = [[UITextView alloc] init];
        _textView.delegate = self;
        _textView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _textView.font = [UIFont systemFontOfSize:18.0f];
    }
    return self;
}

- (void)loadView
{
    self.view = _textView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        [self setEdgesForExtendedLayout:UIRectEdgeNone];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    _viewOnScreen = YES;
    [_textView becomeFirstResponder];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    _viewOnScreen = NO;
    if (_willDisappearCallback !=nil){
        _willDisappearCallback();
    }
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)keyboardWillShow:(NSNotification *)notification {
    CGRect keyboardFrame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval animationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    BOOL isPortrait = UIDeviceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation);
    CGFloat keyboardHeight = isPortrait ? keyboardFrame.size.height : keyboardFrame.size.width;

    UIEdgeInsets contentInset = self.textView.contentInset;
    contentInset.bottom = keyboardHeight;


    UIEdgeInsets scrollIndicatorInsets = self.textView.scrollIndicatorInsets;
    scrollIndicatorInsets.bottom = keyboardHeight;

    [UIView animateWithDuration:animationDuration animations:^{
        self.textView.contentInset = contentInset;
        self.textView.scrollIndicatorInsets = scrollIndicatorInsets;
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSTimeInterval animationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    UIEdgeInsets contentInset = self.textView.contentInset;
    contentInset.bottom = 0;

    UIEdgeInsets scrollIndicatorInsets = self.textView.scrollIndicatorInsets;
    scrollIndicatorInsets.bottom = 0;

    [UIView animateWithDuration:animationDuration animations:^{
        self.textView.contentInset = contentInset;
        self.textView.scrollIndicatorInsets = scrollIndicatorInsets;
    }];
}

- (void)setResizeWhenKeyboardPresented:(BOOL)observesKeyboard {
  if (observesKeyboard != _resizeWhenKeyboardPresented) {
    _resizeWhenKeyboardPresented = observesKeyboard;

    if (_resizeWhenKeyboardPresented) {
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    } else {
      [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
      [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    }
  }
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if(_entryElement && _entryElement.delegate && [_entryElement.delegate respondsToSelector:@selector(QEntryDidBeginEditingElement:andCell:)]){
        [_entryElement.delegate QEntryDidBeginEditingElement:_entryElement andCell:self.entryCell];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    _entryElement.textValue = textView.text;
    
    if(_entryElement && _entryElement.delegate && [_entryElement.delegate respondsToSelector:@selector(QEntryDidEndEditingElement:andCell:)]){
        [_entryElement.delegate QEntryDidEndEditingElement:_entryElement andCell:self.entryCell];
    }
    
    if (_entryElement.onValueChanged) {
        _entryElement.onValueChanged();
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if(_entryElement && _entryElement.delegate && [_entryElement.delegate respondsToSelector:@selector(QEntryShouldChangeCharactersInRangeForElement:andCell:)]){
        return [_entryElement.delegate QEntryShouldChangeCharactersInRangeForElement:_entryElement andCell:self.entryCell];
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    [self _showTextViewCaretPosition:textView];
    _entryElement.textValue = textView.text;

    if(_entryElement && _entryElement.delegate && [_entryElement.delegate respondsToSelector:@selector(QEntryEditingChangedForElement:andCell:)]){
        [_entryElement.delegate QEntryEditingChangedForElement:_entryElement andCell:self.entryCell];
    }
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
    [self _showTextViewCaretPosition:textView];
}

- (void)_showTextViewCaretPosition:(UITextView *)textView {
    CGRect caretRect = [textView caretRectForPosition:self.textView.selectedTextRange.end];
    [textView scrollRectToVisible:caretRect animated:NO];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self _showTextViewCaretPosition:self.textView];
}


@end
