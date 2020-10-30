//
//  NSObject+YJKVO.h
//  KVCKVODemo
//
//  Created by 张强 on 2020/10/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (YJKVO)


/// 添加观察者
/// @param observer 观察者
/// @param keyPath keyPath
- (void)yj_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;


/// 移除观察者
/// @param observer 观察者
/// @param keyPath keyPath
- (void)yj_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;


/// kvo 回调方法 (由观察者实现)
/// @param keyPath keyPath
/// @param object 被观察对象
/// @param newValue 新值
- (void)yj_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object newValue:(id)newValue;
    

@end

NS_ASSUME_NONNULL_END
