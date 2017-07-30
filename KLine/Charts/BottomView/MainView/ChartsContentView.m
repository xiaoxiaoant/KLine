//
//  ChartsContentView.m
//  KLine
//
//  Created by 陈蕃坊 on 2017/7/29.
//  Copyright © 2017年 DanDanLiCai. All rights reserved.
//

#import "ChartsContentView.h"

//model
#import "TimeLineTotalModel.h"

@interface ChartsContentView()

//分时图数据模型
@property (nonatomic, strong) TimeLineTotalModel *timeLineTotalModel;



@property (nonatomic, assign) ChartsType chartsType;

/** 区间个数 */
@property (nonatomic, assign) NSUInteger sectionCount;

/** 时间数组 */
@property (nonatomic, strong) NSArray *timeArr;

@end

@implementation ChartsContentView

//=================================================================
//                           懒加载
//=================================================================
#pragma mark - 懒加载
- (NSArray *)timeArr {
    if (_timeArr == nil) {
        _timeArr = @[
                     @"9:30",
                     @"10:00",
                     @"10:30",
                     @"11:00",
                     @"11:30",
                     @"12:00",
                     @"13:30",
                     @"14:00",
                     @"14:30",
                     @"15:00",
                     @"15:30",
                     ];
    }
    
    return _timeArr;
}

//=================================================================
//                           绘图
//=================================================================
#pragma mark - 绘图

- (void)reDrawWithLineData:(id)lineData chartsType:(ChartsType)chartsType {
    self.timeLineTotalModel = lineData;
    self.chartsType = chartsType;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    if (self.timeLineTotalModel == nil) {
        return;
    }
    
    self.sectionCount = 11;
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGFloat y = 0;
    CGFloat width = rect.size.width;
    CGFloat x = 0;
    CGFloat height = 0;
    //绘制MA
    height = MAHeight;
//    [self drawBackgroundInRect:CGRectMake(x, y, width, height) ctx:ctx];
    
    //=================
    //     绘制背景
    //=================
    height = rect.size.height - MAHeight;
    y = MAHeight;
    [self drawBackgroundInRect:CGRectMake(x, y, width, height) ctx:ctx];
    
    
    //=================
    //    绘制折线图
    //=================
    height = (rect.size.height - MAHeight - DateHeight - MAVOLHeight) * LinechartHeightRate;
    [self drawChartsLineInRect:CGRectMake(x, y, width, height) ctx:ctx];
    
    //=================
    //    绘制时间
    //=================
    y = y + height;
    height = DateHeight;
    [self drawDateInRect:CGRectMake(x + 1, y, width - 2, height) ctx:ctx];
    
    
}

//=================================================================
//                           绘制背景
//=================================================================
#pragma mark - 绘制背景

- (void)drawBackgroundInRect:(CGRect)rect ctx:(CGContextRef)ctx {
    CGContextSetStrokeColorWithColor(ctx, BackgroundLineColor.CGColor);
    //绘制矩形
    CGContextAddRect(ctx, rect);
    
    //绘制竖线
    CGFloat x;
    CGFloat startY = rect.origin.y;
    CGFloat endY = startY + rect.size.height;
    CGFloat width = rect.size.width / self.sectionCount;
    
    for (int i = 1; i < self.sectionCount; i++) {
        x = width * i;
        
        CGContextMoveToPoint(ctx, x, startY);
        CGContextAddLineToPoint(ctx, x, endY);
        CGContextStrokePath(ctx);
    }
    
    
    
    
    
}

//=================================================================
//                           绘制MA
//=================================================================
#pragma mark - 绘制MA
- (void)drawMAInRect:(CGRect)rect ctx:(CGContextRef)ctx {
    
}


//=================================================================
//                         绘制折线图
//=================================================================
#pragma mark - 绘制折线图
- (void)drawChartsLineInRect:(CGRect)rect ctx:(CGContextRef)ctx {
    
    CGFloat rectHeight = rect.size.height;
    CGFloat maxY = rect.size.height + rect.origin.y;
    
    NSInteger lineCount = 6;
    CGFloat averageHeight = rectHeight / lineCount;
    CGFloat startX = rect.origin.x;
    CGFloat endX = rect.size.width;
    CGFloat y = rect.origin.y;
    
    //画横线
    for (int i = 1; i <= lineCount; i++) {
        y = y + averageHeight;
        CGContextMoveToPoint(ctx, startX, y);
        CGContextAddLineToPoint(ctx, endX, y);
        CGContextStrokePath(ctx);
    }
    
    //获取最大值，最小值，计算差值
    NSArray <TimeLineModel *>*modelArr = self.timeLineTotalModel.dataArr;
    NSArray *priceArr = [modelArr valueForKeyPath:@"price"];
    CGFloat maxPrice = [[priceArr valueForKeyPath:@"@max.floatValue"] floatValue];
    CGFloat minPrice = [[priceArr valueForKeyPath:@"@min.floatValue"] floatValue];
    CGFloat deltaPrice = maxPrice - minPrice;
    
    //计算竖直方向每个像素所代表的价钱（为了使不会太过于充满屏幕，减去一点高度）
    CGFloat averagePxPrice = deltaPrice / (rectHeight - averageHeight);
    //计算水平方向每个分钟占的宽度
    CGFloat averageTimeWidth = rect.size.width / 330;
    
    //=================
    //     绘制折现图
    //=================
    CGContextSetStrokeColorWithColor(ctx, TimeLineCharColor.CGColor);
    CGFloat lineX = 0;
    CGFloat lineY;
    CGFloat price = 0;
    for (int i = 0; i < modelArr.count; i++) {
        TimeLineModel *model = modelArr[i];
        price = model.price;
        CGFloat height = (price - minPrice) / averagePxPrice;
        lineX = i * averageTimeWidth;
        lineY = maxY - height;
        
        if (i == 0) {
            CGContextMoveToPoint(ctx, lineX, lineY);
        } else {
            CGContextAddLineToPoint(ctx, lineX, lineY);
        }
    }
    CGContextStrokePath(ctx);
    
    //填充色的处理
    CGContextSetFillColorWithColor(ctx, TimeLineCharFillColor.CGColor);
    CGContextMoveToPoint(ctx, 0, maxY);
    for (int i = 0; i < modelArr.count; i++) {
        TimeLineModel *model = modelArr[i];
        price = model.price;
        CGFloat height = (price - minPrice) / averagePxPrice;
        lineX = i * averageTimeWidth;
        lineY = maxY - height;
        
        CGContextAddLineToPoint(ctx, lineX, lineY);
    }
    
    CGContextAddLineToPoint(ctx, lineX, maxY);
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);
    
    
    //均线的处理
    CGContextSetStrokeColorWithColor(ctx, TimeLineAveragePriceColor.CGColor);
    for (int i = 0; i < modelArr.count; i++) {
        TimeLineModel *model = modelArr[i];
        lineX = i * averageTimeWidth;
        CGFloat heiht = (model.averagePrice - minPrice) / averagePxPrice;
        lineY = maxY - heiht;
        
        if (i == 0) {
            CGContextMoveToPoint(ctx, lineX, lineY);
        } else {
            CGContextAddLineToPoint(ctx, lineX, lineY);
        }
    }
    
    CGContextStrokePath(ctx);
    
    
}

//=================================================================
//                        绘制日期、时间
//=================================================================
#pragma mark - 绘制日期、时间
- (void)drawDateInRect:(CGRect)rect ctx:(CGContextRef)ctx {
    
    CGContextSetFillColorWithColor(ctx, BackgroundColor.CGColor);
    CGContextAddRect(ctx, rect);
    CGContextFillPath(ctx);
    
    NSDictionary *attributes = @{
                                NSForegroundColorAttributeName : [UIColor lightGrayColor],
                                NSFontAttributeName : [UIFont systemFontOfSize:13]
                                };

    CGFloat width = rect.size.width / self.sectionCount;
    
    NSString *timeStr = nil;
    CGFloat x = 0;
    CGFloat y = rect.origin.y;
    for (int i = 0; i < self.sectionCount; i++) {
        x = width * i;
        timeStr = self.timeArr[i];
        [timeStr drawAtPoint:CGPointMake(x, y) withAttributes:attributes];
    }
    
}

//=================================================================
//                           绘制MAVOL
//=================================================================
#pragma mark - 绘制MAVOL
- (void)drawMAVOLInRect:(CGRect)rect ctx:(CGContextRef)ctx {
    
}


//=================================================================
//                           绘制成交量
//=================================================================
#pragma mark - 绘制成交量
- (void)drawVolumeInRect:(CGRect)rect ctx:(CGContextRef)ctx {
    
}


@end