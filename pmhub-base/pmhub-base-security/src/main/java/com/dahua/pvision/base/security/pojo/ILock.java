package com.dahua.pvision.base.security.pojo;

import com.dahua.pvision.base.security.service.redisson.IDistributedLock;
import java.util.Objects;
import lombok.AllArgsConstructor;
import lombok.Getter;

@AllArgsConstructor
public class ILock implements AutoCloseable {
    /** 持有的锁对象 */
    @Getter private Object lock;

    /** 分布式锁接口 */
    @Getter private IDistributedLock distributedLock;

    @Override
    public void close() throws Exception {
        if (Objects.nonNull(lock)) {
            distributedLock.unLock(lock);
        }
    }
}
