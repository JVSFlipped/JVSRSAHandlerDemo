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
//RSA密钥文件名,目前没有此类调用,后续可能会添加
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
    //将字典转成json字符串
    NSString *jsonString = [self conversionDictionary:dict];
    //转成UTF8Data
    NSData *UTF8Data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    //加密过程
    NSData *RSAEncryptData = [self encryptionData:UTF8Data WithRSAKeyType:keyType];
    //转成base64的string
    NSString *encryptString = [RSAEncryptData base64EncodedString];
    return encryptString;
}

//解密字符串
- (NSDictionary *)decryptString:(NSString *)encryptedString WithRSAKeyType:(KeyType)keyType
{
    //将要解密的字符串base64解码
    NSData *encryptedData = [[NSData alloc] initWithBase64EncodedString:encryptedString options:NSDataBase64DecodingIgnoreUnknownCharacters];
    //解密过程
    NSData *jsonData = [self decryptData:encryptedData WithRSAKeyType:keyType];
    //将data转成string
    NSString *josnString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    //转成字典输出
    NSDictionary *dict = [self dictionaryWithJsonString:josnString];
    return dict;
}


//加密方法,这里主要是分段内容
- (NSData *)encryptionData:(NSData *)expressData WithRSAKeyType:(KeyType)keyType
{
    if (expressData && [expressData length]) {
        //计划分段加密长度
        NSInteger planSubLength = kEncryptionLength;
        //数据总长度
        NSInteger sumLength = [expressData length];
        //分段数
        NSInteger blockCount = sumLength/planSubLength + ((sumLength%planSubLength)?1:0);
        //总的数据,存放解密后的数据
        NSMutableData *sumData = [[NSMutableData alloc ] initWithCapacity:0];
        for(int i = 0;i < blockCount; i++)
        {
            //实际分段长度,注意最后一段不够的问题
            int relSubLength = (int)MIN(planSubLength, sumLength - i*planSubLength);
            if (relSubLength != 117) {
                
            }
            //定义放置待加密数据的数组, 因为要按128进行拼接, 所以长度为 128
            unsigned char expressArr[kDecryptionLength];
            //C函数方法,将数组初始化置空
            bzero(expressArr, sizeof(expressArr));
            //在expressArr中放入目标要加密的数据
            memcpy(expressArr, [[expressData subdataWithRange:NSMakeRange(i*planSubLength, relSubLength)] bytes], relSubLength);
            //定义存放加密后数据的数组,因为明文长度不得大于密文长度,所以这里的长度为计划长度(密文,较长)
            unsigned char encryptedArr[planSubLength];
            //同上,将数组初始化置空
            bzero(encryptedArr, sizeof(encryptedArr));
            //加密expressArr中的数据并放入encryptedArr数组中
            [self encryptFrom:expressArr length:(int)relSubLength to:encryptedArr WithKeyType:keyType];
            // 将数组中数据拼接起来
            int k=0;
            // 因为解密的时候是128解密的, 所以这里按128位进行拼接
            for(int j = 0;j< kDecryptionLength;j++)
            {
                if(encryptedArr[j] != '\0')
                {
                    k = j+1;
                }
            }
            // Base64编码长度必定是4的倍数, 所以这里需要做此处理
            if(k%4 != 0){
                k = ((int)(k/4) + 1)*4;
            }
            //拼接加密后数据
            [sumData appendData:[NSData dataWithBytes:encryptedArr length:k]];
        }
        return sumData;
    }
    return nil;
}
//加密部分
- (NSInteger)encryptFrom:(const unsigned char *)expressArr length:(int)length to:(unsigned char *)encryptedArr WithKeyType:(KeyType)keyType
{
    //导入文件中密钥
    if (![self importRSAKeyWithType:keyType])
        return 0;
    if (expressArr != NULL && encryptedArr != NULL) {
        NSInteger status;
        switch (keyType) {
            case KeyTypePrivate:{
                //私钥加密
                status =  RSA_private_encrypt(length, expressArr,encryptedArr, _rsa, (int)kRSAPaddingType);
            }
                break;
                
            default:{
                //公钥加密
                status =  RSA_public_encrypt(length,expressArr,encryptedArr, _rsa,  (int)kRSAPaddingType);
            }
                break;
        }
        return status;
    }
    return -1;
}


//解密方法(主要是分段)
- (NSData *)decryptData:(NSData *)encryptedData WithRSAKeyType:(KeyType)keyType
{
    if (encryptedData && [encryptedData length]) {
        //计划解密长度
        NSInteger planSubLength = kDecryptionLength;
        //数据总长度
        NSInteger sumLength = [encryptedData length];
        //分段数
        NSInteger blockCount = sumLength/planSubLength + ((sumLength%planSubLength)?1:0);
        //存放解密后的数据
        NSMutableData *sumData = [[NSMutableData alloc ] initWithCapacity:0];
        for(int i = 0;i < blockCount; i++)
        {
            //实际分段的长度,注意最后一段不够的情况
            int realSubLength = (int)MIN(planSubLength, sumLength - i*planSubLength);
            //定义存放待解密数据的数组encryptedArr(密文,较长)
            unsigned char encryptedArr[planSubLength];
            //C函数,初始化置空encryptedArr数组
            bzero(encryptedArr, sizeof(encryptedArr));
            //将待解密的data数据存放入encryptedArr数组中
            memcpy(encryptedArr, [[encryptedData subdataWithRange:NSMakeRange(i*planSubLength, realSubLength)] bytes], realSubLength);
            //定义存放解密出来的数据的数组expressArr(明文,较短)
            unsigned char expressArr[realSubLength];
            //初始化置空expressArr数组
            bzero(expressArr, sizeof(expressArr));
            //解密encryptedArr中的数据并存入expressArr中
            [self decryptFrom:encryptedArr length:realSubLength to:expressArr WithKeyType:keyType];
            int k=0;
            // 拼接
            for(int j = 0;j< planSubLength;j++)
            {
                if(expressArr[j] != '\0')
                {
                    k = j+1;
                }
            }
            //拼接解密出来的数据
            [sumData appendData:[NSData dataWithBytes:expressArr length:k]];
        }
        return sumData;
    }
    return nil;
}
//解密方法
- (NSInteger)decryptFrom:(const unsigned char *)encryptedArr length:(int)length to:(unsigned char *)expressArr WithKeyType:(KeyType)keyType
{
    //获取密钥
    if (![self importRSAKeyWithType:keyType])
        return -1;
    if (encryptedArr != NULL && expressArr != NULL) {
        int status;
        switch (keyType) {
            case KeyTypePrivate:{
                //私钥解密
                status =  (int)RSA_private_decrypt(length, encryptedArr,expressArr, _rsa, (int)kRSAPaddingType);
            }
                break;
            default:{
                //公钥解密
                status =  RSA_public_decrypt(length, encryptedArr, expressArr, _rsa,  (int)kRSAPaddingType);
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

