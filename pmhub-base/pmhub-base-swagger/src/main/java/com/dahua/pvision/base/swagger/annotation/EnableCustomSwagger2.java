package com.dahua.pvision.base.swagger.annotation;

import com.dahua.pvision.base.swagger.config.SwaggerAutoConfiguration;
import java.lang.annotation.*;
import org.springframework.context.annotation.Import;

@Target({ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@Import({SwaggerAutoConfiguration.class})
public @interface EnableCustomSwagger2 {}
