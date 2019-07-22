//
//  StringCrypto.h
//  AcnSDK
//
//  Created by Alexey Chechetkin on 07/02/2018.
//  Copyright © 2018 Arrow. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString(Crypto)

@property(nonatomic, readonly, nonnull) NSString *sha256;

- (NSString * _Nonnull) hmacForKey:(NSString * _Nonnull)key;
- (NSString * _Nonnull) hmacForKeyData:(NSData * _Nonnull)dataKey;
+ (NSString * _Nonnull) hexStringForChars:(unsigned char * _Nonnull)chars length:(NSUInteger)length;

@end
