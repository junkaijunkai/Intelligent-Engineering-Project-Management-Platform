package com.dahua.pvision.base.core.interceptor;

import com.alibaba.fastjson2.JSON;
import com.dahua.pvision.base.core.annotation.RepeatSubmit;
import com.dahua.pvision.base.core.config.redis.RedisService;
import com.dahua.pvision.base.core.constant.CacheConstants;
import com.dahua.pvision.base.core.filter.RepeatedlyRequestWrapper;
import com.dahua.pvision.base.core.core.text.Convert;
import com.dahua.pvision.base.core.utils.StringUtils;
import com.dahua.pvision.base.core.utils.http.HttpHelper;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import javax.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;

/** 判断请求url和数据是否和上一次相同， 如果和上次相同，则是重复提交表单。 有效时间为10秒内。 */
// @Component
public class SameUrlDataInterceptor extends RepeatSubmitInterceptor {
    public final String REPEAT_PARAMS = "repeatParams";

    public final String REPEAT_TIME = "repeatTime";

    // 令牌自定义标识
    @Value("${token.header}")
    private String header;

    @Autowired private RedisService redisService;

    @SuppressWarnings("unchecked")
    @Override
    public boolean isRepeatSubmit(HttpServletRequest request, RepeatSubmit annotation) {
        String nowParams = "";
        if (request instanceof RepeatedlyRequestWrapper) {
            RepeatedlyRequestWrapper repeatedlyRequest = (RepeatedlyRequestWrapper) request;
            nowParams = HttpHelper.getBodyString(repeatedlyRequest);
        }

        // body参数为空，获取Parameter的数据
        if (StringUtils.isEmpty(nowParams)) {
            nowParams = JSON.toJSONString(request.getParameterMap());
        }
        Map<String, Object> nowDataMap = new HashMap<String, Object>();
        nowDataMap.put(REPEAT_PARAMS, nowParams);
        nowDataMap.put(REPEAT_TIME, System.currentTimeMillis());

        // 请求地址（作为存放cache的key值）
        String url = request.getRequestURI();

        // 唯一值（没有消息头则使用请求地址）
        String submitKey = StringUtils.trimToEmpty(request.getHeader(header));

        // 唯一标识（指定key + url + 消息头）
        String cacheRepeatKey = CacheConstants.REPEAT_SUBMIT_KEY + url + submitKey;

        Object sessionObj = redisService.getCacheObject(cacheRepeatKey);
        if (sessionObj instanceof Map) {
            Map<?, ?> sessionMap = (Map<?, ?>) sessionObj;
            Object preDataObject = sessionMap.get(url);
            if (preDataObject instanceof Map) {
                Map<?, ?> preDataMap = (Map<?, ?>) preDataObject;
                if (compareParams(nowDataMap, preDataMap)
                        && compareTime(nowDataMap, preDataMap, annotation.interval())) {
                    return true;
                }
            }
        }
        Map<String, Object> cacheMap = new HashMap<String, Object>();
        cacheMap.put(url, nowDataMap);
        redisService.setCacheObject(
                cacheRepeatKey, cacheMap, annotation.interval(), TimeUnit.MILLISECONDS);
        return false;
    }

    /** 判断参数是否相同 */
    private boolean compareParams(Map<?, ?> nowMap, Map<?, ?> preMap) {
        String nowParams = Convert.toStr(nowMap.get(REPEAT_PARAMS), "");
        String preParams = Convert.toStr(preMap.get(REPEAT_PARAMS), "");
        return nowParams.equals(preParams);
    }

    /** 判断两次间隔时间 */
    private boolean compareTime(Map<?, ?> nowMap, Map<?, ?> preMap, int interval) {
        Long time1 = Convert.toLong(nowMap.get(REPEAT_TIME));
        Long time2 = Convert.toLong(preMap.get(REPEAT_TIME));
        if (time1 == null || time2 == null) {
            return false;
        }
        if ((time1 - time2) < interval) {
            return true;
        }
        return false;
    }
}
