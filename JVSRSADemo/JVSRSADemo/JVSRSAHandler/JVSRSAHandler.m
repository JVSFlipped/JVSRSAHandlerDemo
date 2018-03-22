//
//  JVSRSAHandler.m
//  JVSRSADemo
//
//  Created by 程硕 on 2018/3/18.
//  Copyright © 2018年 Flipped. All rights reserved.
//

#import "JVSRSAHandler.h"
#import "NSData+Base64.h"
//RSA算法填充类型,前后台要统一
static NSInteger kRSAPaddingType = RSA_PKCS1_PADDING;
//解密长度,前后台要统一
static NSInteger kDecryptionLength = 128;
//RSA公钥文件名
static NSString *kPublicKeyFile = @"rsa_public_key";
//加密长度,前后台要统一
static NSInteger kEncryptionLength = 117;
//RSA密钥文件名
static NSString *kPrivateKeyFile = @"rsa_private_key";


@implementation JVSRSAHandler

+ (id)shareInstance
{
    static JVSRSAHandler *_rsaHandler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _rsaHandler = [[self alloc] init];
    });
    return _rsaHandler;
}

//获取key
- (BOOL)importRSAKeyWithType:(KeyType)type
{
    FILE *file;
    NSString *keyName = type == KeyTypePublic?kPublicKeyFile:kPrivateKeyFile;
    NSString *keyPath = [[NSBundle mainBundle] pathForResource:keyName ofType:@"pem"];
    file = fopen([keyPath UTF8String], "rb");
    if (NULL != file)
    {
        if (type == KeyTypePublic)
        {
            _rsa = PEM_read_RSA_PUBKEY(file, NULL, NULL, NULL);
            assert(_rsa != NULL);
        }
        else
        {
            _rsa = PEM_read_RSAPrivateKey(file, NULL, NULL, NULL);
            assert(_rsa != NULL);
        }
        fclose(file);
        return (_rsa != NULL) ? YES : NO;
    }
    NSException* exception = [NSException exceptionWithName:@"读取密钥失败!" reason:@"没有添加.pem密钥文件或者命名不同于代码内名称" userInfo:nil];
    @throw exception;
    return NO;
}

//加密字典
- (NSString *)encryptDictionary:(NSDictionary*)dict WithRSAKeyType:(KeyType)keyType
{
    NSString *jsonString = [self conversionDictionary:dict];
    NSData *utf8data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSData *RSAEncryptData = [self encryptionData:utf8data WithRSAKeyType:keyType];
    NSString *encryptString = [RSAEncryptData base64EncodedString];
    return encryptString;
}

//解密字符串
- (NSDictionary *)decryptString:(NSString *)encryptedString WithRSAKeyType:(KeyType)keyType
{
    NSData *encryptedData = [[NSData alloc] initWithBase64EncodedString:encryptedString options:NSDataBase64DecodingIgnoreUnknownCharacters];
    NSData *jsonData = [self decryptData:encryptedData WithRSAKeyType:keyType];
    NSString *josnString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSDictionary *dict = [self dictionaryWithJsonString:josnString];
    return dict;
}


//解密方法
- (NSData *)decryptData:(NSData *)encryptedData WithRSAKeyType:(KeyType)keyType
{
    if (encryptedData && [encryptedData length]) {
        NSInteger blockLength = kDecryptionLength;//解密必须是这个长度
        NSInteger sumLen = [encryptedData length];
        NSInteger blockCount = sumLen/blockLength;
        NSMutableData *sumData = [[NSMutableData alloc ] initWithCapacity:0];
        for(NSInteger i = 0;i < blockCount; i++)
        {
            int flen = (int)MIN(blockLength, sumLen - i * blockLength);
            unsigned char from[flen];
            bzero(from, sizeof(from));
            memcpy(from, [[encryptedData subdataWithRange:NSMakeRange(i*blockLength, flen)] bytes], flen);
            unsigned char to[blockLength];
            bzero(to, sizeof(to));
            [self decryptFrom:from flen:flen to:to WithKeyType:keyType];
            int k=0;
            //取出to数组的有效内容长度，不能用strlen，因为to为unsigned char*型，可能有效内容之间也有“\0”
            for(int j = 0;j< blockLength;j++)
            {
                if (to[j] == '\0') {
                    
                }
                if(to[j] != '\0')
                {
                    k = j+1;
                }
            }
            [sumData appendData:[NSData dataWithBytes:to length:k]];
        }
        return sumData;
    }
    return nil;
}
//解密算法
- (NSInteger)decryptFrom:(const unsigned char *)from flen:(int)flen to:(unsigned char *)to WithKeyType:(KeyType)keyType
{
    if (![self importRSAKeyWithType:keyType])
        return -1;
    if (from != NULL && to != NULL) {
        int status;
        switch (keyType) {
            case KeyTypePrivate:{
                status =  (int)RSA_private_decrypt(flen, from,to, _rsa, kRSAPaddingType);
            }
                break;
            default:{
                status =  RSA_public_decrypt(flen,from,to, _rsa,  kRSAPaddingType);
            }
                break;
        }
        return status;
    }
    return -1;
}
//加密方法
- (NSData *)encryptionData:(NSData *)expressData WithRSAKeyType:(KeyType)keyType
{
    if (expressData && [expressData length]) {
        NSInteger blockLength = kEncryptionLength;//加密必须是这个长度
        NSInteger sumLen = [expressData length];
        NSInteger blockCount = sumLen/blockLength + 1;
        NSMutableData *sumData = [[NSMutableData alloc ] initWithCapacity:0];
        for(int i = 0;i < blockCount; i++)
        {
            int flen = (int)MIN(blockLength, sumLen - i * blockLength);
            unsigned char from[flen];
            bzero(from, sizeof(from));
            memcpy(from, [[expressData subdataWithRange:NSMakeRange(i*blockLength, flen)] bytes], flen);
            unsigned char to[kEncryptionLength];
            bzero(to, sizeof(to));
            [self encryptFrom:from flen:flen to:to WithKeyType:keyType];
            //取出to数组的有效内容长度，不能用strlen，因为to为unsigned char*型，可能有效内容之间也有“\0”
            int k=0;
            for(int j = 0;j< 128;j++)
            {
                if(to[j] != '\0')
                {
                    k = j+1;
                }
            }
            [sumData appendData:[NSData dataWithBytes:to length:k]];
        }
        return sumData;
    }
    return nil;
}
//加密算法
- (NSInteger)encryptFrom:(const unsigned char *)from flen:(int)flen to:(unsigned char *)to WithKeyType:(KeyType)keyType
{
    if (![self importRSAKeyWithType:keyType])
        return 0;
    if (from != NULL && to != NULL) {
        int status;
        
        switch (keyType) {
            case KeyTypePrivate:{
                status =  RSA_private_encrypt(flen, from,to, _rsa, kRSAPaddingType);
            }
                break;
                
            default:{
                status =  RSA_public_encrypt(flen,from,to, _rsa,  kRSAPaddingType);
            }
                break;
        }
        return status;
    }
    return -1;
}

//字典转字符串
- (NSString *)conversionDictionary:(NSDictionary *)dic

{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

//字符串转字典
- (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString
{
    if (jsonString == nil) {
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
    if(err) {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}




@end
