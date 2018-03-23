//
//  JVSRSAHandler.h
//  JVSRSADemo
//
//  Created by 程硕 on 2018/3/18.
//  Copyright © 2018年 Flipped. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "rsa.h"
#import "pem.h"
#import "err.h"
typedef enum {
    KeyTypePublic,
    KeyTypePrivate
}KeyType;
@interface JVSRSAHandler : NSObject

@property(nonatomic, assign) RSA *rsa;

+ (instancetype)shareInstance;

//加密字典
- (NSString *)encryptDictionary:(NSDictionary*)dict WithRSAKeyType:(KeyType)keyType;

//解密base64字符串
- (NSDictionary *)decryptString:(NSString *)encryptedString WithRSAKeyType:(KeyType)keyType;

//加密数据
- (NSData *)encryptionData:(NSData *)expressData WithRSAKeyType:(KeyType)keyType;

//解密数据
- (NSData *)decryptData:(NSData *)encryptedData WithRSAKeyType:(KeyType)keyType;


@end
