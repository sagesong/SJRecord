//
//  UIImage+Resizable.m
//  
//

#import "UIImage+Resizable.h"

@implementation UIImage (Resizable)

+ (instancetype)resizableWithImageName:(NSString *)imageName
{
    UIImage *image = [UIImage imageNamed:imageName];
    
    return [image stretchableImageWithLeftCapWidth:image.size.width * 0.5 topCapHeight:image.size.height * 0.5];

}

@end
