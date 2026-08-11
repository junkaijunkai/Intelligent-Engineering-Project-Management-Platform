package com.dahua.pvision.base.security;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import com.dahua.pvision.base.security.aspect.PreAuthorizeAspect;
import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;
import org.junit.jupiter.api.Test;
import org.springframework.aop.aspectj.AspectJExpressionPointcut;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;

class AutoConfigurationMetadataTest {

    @Test
    void everyDeclaredAutoConfigurationClassMustExist() throws IOException {
        ClassLoader classLoader = getClass().getClassLoader();
        Properties factories = new Properties();

        try (InputStream input = classLoader.getResourceAsStream("META-INF/spring.factories")) {
            assertNotNull(input, "META-INF/spring.factories must exist");
            factories.load(input);
        }

        String configuredClasses =
                factories.getProperty(EnableAutoConfiguration.class.getName(), "");
        for (String configuredClass : configuredClasses.split(",")) {
            String className = configuredClass.trim();
            if (!className.isEmpty()) {
                assertDoesNotThrow(
                        () -> Class.forName(className, false, classLoader),
                        () -> "Missing auto-configuration class: " + className);
            }
        }
    }

    @Test
    void authorizationPointcutMustReferenceExistingAnnotations() {
        AspectJExpressionPointcut pointcut = new AspectJExpressionPointcut();
        pointcut.setExpression(PreAuthorizeAspect.POINTCUT_SIGN);

        assertDoesNotThrow(pointcut::getClassFilter);
    }
}
