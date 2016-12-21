//
//  CommentsNode.m
//  Sample
//
//  Created by Hannah Troisi on 3/21/16.
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the root directory of this source tree. An additional grant
//  of patent rights can be found in the PATENTS file in the same directory.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
//  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "CommentsNode.h"

#define INTER_COMMENT_SPACING 5
#define NUM_COMMENTS_TO_SHOW  3

@implementation CommentsNode
{
  CommentFeedModel              *_commentFeed;
  NSMutableArray <ASTextNode *> *_commentNodes;
  ASDisplayNode                 *_redNode;
  BOOL                           _redNodeEnabled;
}

#pragma mark - Lifecycle

- (instancetype)init
{
  self = [super init];
  if (self) {
    self.automaticallyManagesSubnodes = YES;

    _commentNodes = [[NSMutableArray alloc] init];
    
    _redNode = ({
      ASDisplayNode *node = [[ASDisplayNode alloc] init];
      node.backgroundColor = [UIColor redColor];
      node.style.minHeight = ASDimensionMake(30);
      node;
    });
  }
  return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
  NSMutableArray *nodesForStack = [NSMutableArray arrayWithArray:_commentNodes];
  if (_redNodeEnabled) {
    [nodesForStack insertObject:_redNode atIndex:0];
  }
  
  return [ASStackLayoutSpec
          stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical
          spacing:INTER_COMMENT_SPACING
          justifyContent:ASStackLayoutJustifyContentStart
          alignItems:ASStackLayoutAlignItemsStretch
          children:nodesForStack];
}

#pragma mark - Instance Methods

- (void)updateWithCommentFeedModel:(CommentFeedModel *)feed
{
  _commentFeed = feed;
  [_commentNodes removeAllObjects];
  
  if (_commentFeed) {
    [self createCommentLabels];
    
    BOOL addViewAllCommentsLabel = [feed numberOfCommentsForPhotoExceedsInteger:NUM_COMMENTS_TO_SHOW];
    NSAttributedString *commentLabelString;
    int labelsIndex = 0;
    
    if (addViewAllCommentsLabel) {
      commentLabelString         = [_commentFeed viewAllCommentsAttributedString];
      [_commentNodes[labelsIndex] setAttributedText:commentLabelString];
      labelsIndex++;
    }
    
    NSUInteger numCommentsInFeed = [_commentFeed numberOfItemsInFeed];
    
    for (int feedIndex = 0; feedIndex < numCommentsInFeed; feedIndex++) {
      commentLabelString         = [[_commentFeed objectAtIndex:feedIndex] commentAttributedString];
      [_commentNodes[labelsIndex] setAttributedText:commentLabelString];
      labelsIndex++;
    }
    
    [self setNeedsLayout];
  }
}


#pragma mark - Helper Methods

- (void)createCommentLabels
{
  BOOL addViewAllCommentsLabel = [_commentFeed numberOfCommentsForPhotoExceedsInteger:NUM_COMMENTS_TO_SHOW];
  NSUInteger numCommentsInFeed = [_commentFeed numberOfItemsInFeed];
  
  NSUInteger numLabelsToAdd    = (addViewAllCommentsLabel) ? numCommentsInFeed + 1 : numCommentsInFeed;
  
  for (NSUInteger i = 0; i < numLabelsToAdd; i++) {
    
    ASTextNode *commentLabel   = [[ASTextNode alloc] init];
    commentLabel.maximumNumberOfLines = 3;
    
    [_commentNodes addObject:commentLabel];
  }
}

- (void)didLoad {
  [super didLoad];
  
  [self.view addGestureRecognizer:({
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap)];
  })];
}

- (void)didTap {
  _redNodeEnabled = !_redNodeEnabled;
  
  ASCellNode *cellNode = (ASCellNode *)self.supernode;
  [self transitionLayoutWithAnimation:YES shouldMeasureAsync:NO measurementCompletion:^{
    // Allows cell node to resize.
    [cellNode setNeedsLayout];
  }];
}

- (void)animateLayoutTransition:(id<ASContextTransitioning>)context {
  BOOL (^inserted)(ASDisplayNode *) = ^BOOL(ASDisplayNode *node) {
    return [[context insertedSubnodes] containsObject:node];
  };
  
  BOOL (^removed)(ASDisplayNode *) = ^BOOL(ASDisplayNode *node) {
    return [[context removedSubnodes] containsObject:node];
  };
  
  BOOL insertedRedNode = inserted(_redNode);
  BOOL removedRedNode = removed(_redNode);
  if (insertedRedNode) {
    _redNode.alpha = 0;
  }
  
  [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState animations:^{
    if (insertedRedNode || removedRedNode) {
      _redNode.alpha = insertedRedNode ? 1 : 0;
    }
    for (ASTextNode *textNode in _commentNodes) {
      BOOL textNodeInserted = inserted(textNode);
      BOOL textNodeRemoved = removed(textNode);
      CGRect textNodeInitialFrame = [context initialFrameForNode:textNode];
      CGRect textNodeFinalFrame = [context finalFrameForNode:textNode];
      // The frame changes from/to CGRectZero during insertions and removals respectively, therefore we have to take this into account.
      BOOL textNodeFrameChanged = !CGRectEqualToRect(textNodeInitialFrame, textNodeFinalFrame) && !textNodeRemoved && !textNodeInserted;
      if (textNodeFrameChanged) {
        textNode.frame = textNodeFinalFrame;
      }
    }
    
  } completion:^(BOOL finished) {
    [context completeTransition:finished];
  }];
}

@end
