//
//  ViewController.m
//  AILabTest
//
//  Created by zk on 2019/8/28.
//  Copyright © 2019 zk. All rights reserved.
//

#import "ViewController.h"
#import "DrawView.h"
#import <YYKit.h>



#define DRAW_SCALE 3

@interface ViewController ()
@property (weak, nonatomic) IBOutlet DrawView *printView;
@property (weak, nonatomic) IBOutlet UITextField *numText;



@property (nonatomic, strong) NSMutableArray *movePixels;




@end

@implementation ViewController


- (NSMutableArray *)movePixels {
    if (!_movePixels) {
        _movePixels = [NSMutableArray array];
    }
    return _movePixels;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.printView.layer.borderWidth = 1.0;
    self.printView.layer.borderColor = [UIColor redColor].CGColor;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [self.view addGestureRecognizer:tap];
    
}

- (void)tapAction:(UIGestureRecognizer*)tapGr {
    [self.numText resignFirstResponder];
    
}

- (IBAction)undoAction:(id)sender {
    
    [self.printView undo];
    
}

- (IBAction)clearAction:(id)sender {
    
    [self.printView clean];
    [self.movePixels removeAllObjects];
    
}

- (IBAction)confirmAction:(id)sender {
    
    [self.movePixels removeAllObjects];

    for (UIBezierPath *path in self.printView.paths) {
        NSArray *array = [self convertBezierPathToArray:path];
        [self.movePixels addObject:array];
    }
//    NSLog(@"%@",self.movePixels);
    [self postPixelsToServer];
}

- (NSArray *)convertBezierPathToArray:(UIBezierPath*) bezierPath {

    NSMutableArray *array = [NSMutableArray array];
    CGPathRef yourCGPath = bezierPath.CGPath;
    NSMutableArray *bezierPoints = [NSMutableArray array];
    CGPathApply(yourCGPath, (__bridge void *)(bezierPoints), MyCGPathApplierFunc);
    
    for (int i = 0; i < bezierPoints.count; ++i) {
        CGPoint point = [bezierPoints[i] CGPointValue];
        [array addObject:@(point.x * DRAW_SCALE)];
        [array addObject:@(point.y * DRAW_SCALE)];
    }
    return array;
}


/**
 *@brief:将BezierPath中的点转为字符串
 */
- (NSString*)convertBezierPathToNSString:(UIBezierPath*) bezierPath{
    
    NSString *pathString = @"";
    
    CGPathRef yourCGPath = bezierPath.CGPath;
    NSMutableArray *bezierPoints = [NSMutableArray array];
    CGPathApply(yourCGPath, (__bridge void *)(bezierPoints), MyCGPathApplierFunc);
    
    for (int i = 0; i < [bezierPoints count]; ++i) {
        
        CGPoint point = [bezierPoints[i] CGPointValue];
        pathString = [pathString stringByAppendingString:[NSString stringWithFormat:@"%f",point.x]];
        pathString = [pathString stringByAppendingFormat:@"%@",@","];
        pathString = [pathString stringByAppendingString:[NSString stringWithFormat:@"%f",point.y]];
        pathString = [pathString stringByAppendingString:@","];
        
    }
    
    return pathString;
}


void MyCGPathApplierFunc (void *info, const CGPathElement *element) {
    NSMutableArray *bezierPoints = (__bridge NSMutableArray *)info;
    
    CGPoint *points = element->points;
    CGPathElementType type = element->type;
    
    switch(type) {
        case kCGPathElementMoveToPoint: // contains 1 point
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[0]]];
            break;
            
        case kCGPathElementAddLineToPoint: // contains 1 point
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[0]]];
            break;
            
        case kCGPathElementAddQuadCurveToPoint: // contains 2 points
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[0]]];
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[1]]];
            break;
            
        case kCGPathElementAddCurveToPoint: // contains 3 points
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[0]]];
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[1]]];
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[2]]];
            break;
            
        case kCGPathElementCloseSubpath: // contains no point
            break;
    }
}

- (void)postPixelsToServer {
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    [dict setObject:@"xueersi_ai_ocr_mathsxpmsx" forKey:@"sid"];
    
    [dict setObject:self.numText.text?:@"" forKey:@"standAns"];
    
    NSDate *date = [NSDate date];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyyMMddHHmmss";
    NSString *dateStr = [df stringFromDate:date];
//    NSTimeInterval tim = [date timeIntervalSince1970] * 1000;
//    NSString *dateStr = [NSString stringWithFormat:@"%.0f",tim];
    [dict setObject:[NSString stringWithFormat:@"iOS_%@",dateStr] forKey:@"token"];
    
    [dict setObject:@(1002) forKey:@"problemKind"];
    
    [dict setObject:@(self.printView.frame.size.width * DRAW_SCALE) forKey:@"viewW"];
    
    [dict setObject:@(self.printView.frame.size.height * DRAW_SCALE) forKey:@"viewH"];
    
    NSString *pixelsStr = [self.movePixels jsonStringEncoded];
    [dict setObject:pixelsStr forKey:@"movePixels"];
    
    NSString *BOUNDARY = @"PP**OCR**LIB";
    NSString *a_boundary = [NSString stringWithFormat:@"\r\n--%@_a\r\n",BOUNDARY];
    NSString *b_boundary = [NSString stringWithFormat:@"\r\n--%@_b\r\n",BOUNDARY];

    NSString *postStr = [NSString stringWithFormat:@"%@%@%@",a_boundary,[dict jsonStringEncoded],b_boundary];
    
    NSLog(@"%@",postStr);
    
    NSData *postData = [postStr dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://43.228.39.217:10122"]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:postData];
    

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        NSString *reStr = @"";
        if (!error) {
            reStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            
        
        } else {
            reStr = error.description;
        }
        
        if ([reStr isNotBlank]) {
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:reStr preferredStyle:(UIAlertControllerStyleAlert)];
            
            UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleCancel) handler:nil];
            [alert addAction:confirm];
            [self presentViewController:alert animated:YES completion:nil];
        }
        
        
        
    }];
    [task resume];
    
    
}



@end
