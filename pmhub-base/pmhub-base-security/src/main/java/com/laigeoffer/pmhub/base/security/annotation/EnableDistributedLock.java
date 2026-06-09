package com.laigeoffer.pmhub.base.security.annotation;

import com.laigeoffer.pmhub.base.security.aspect.DistributedLockAspect;
import java.lang.annotation.*;
import org.springframework.context.annotation.Import;

/**
 * @description EnableDistributedLock 元注解，开启分布式锁功能
 * @create 2024-06-17-10:56
 */
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Import({DistributedLockAspect.class})
public @interface EnableDistributedLock {}
