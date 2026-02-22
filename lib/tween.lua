--- @brief 缓动动画库
--- @brief 提供丰富的缓动函数和缓动动画核心实现,支持多种数学曲线的插值动画
---
--- @original 基于官方Utils模板内的Tween模块二次修改
--- @modification 修改为纯函数式实现，去除Tween.New，改为Tween.Create
---
--- @cname Tween

local Tween = {}

local pow = function(x, y) return x ^ y end
local sin, cos, pi, sqrt, abs, asin = math.sin, math.cos, math.pi, math.sqrt, math.abs, math.asin

-- ============================================
-- 缓动函数集合
-- ============================================

--- @function
--- @description 线性缓动,匀速运动
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量(目标值-起始值)
--- @param d number 持续时间
--- @return number value 当前值
--- @range 服务端、客户端
local function linear(t, b, c, d) return c * t / d + b end

--- @function
--- @description 二次方缓入,加速进入
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @return number value 当前值
--- @range 服务端、客户端
local function inQuad(t, b, c, d) return c * pow(t / d, 2) + b end

--- @function
--- @description 二次方缓出,减速退出
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @return number value 当前值
--- @range 服务端、客户端
local function outQuad(t, b, c, d)
    local ratio = t / d
    return -c * ratio * (ratio - 2) + b
end

--- @function
--- @description 二次方缓入缓出,先加速后减速
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @return number value 当前值
--- @range 服务端、客户端
local function inOutQuad(t, b, c, d)
    local ratio = t / d * 2
    if ratio < 1 then 
        return c / 2 * ratio * ratio + b 
    end
    return -c / 2 * ((ratio - 1) * (ratio - 3) - 1) + b
end

--- @function
--- @description 三次方缓入,快速加速进入
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @return number value 当前值
--- @range 服务端、客户端
local function inCubic(t, b, c, d) return c * pow(t / d, 3) + b end

--- @function
--- @description 三次方缓出,快速减速退出
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @return number value 当前值
--- @range 服务端、客户端
local function outCubic(t, b, c, d) return c * (pow(t / d - 1, 3) + 1) + b end

--- @function
--- @description 三次方缓入缓出
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @return number value 当前值
--- @range 服务端、客户端
local function inOutCubic(t, b, c, d)
    local ratio = t / d * 2
    if ratio < 1 then 
        return c / 2 * ratio * ratio * ratio + b 
    end
    ratio = ratio - 2
    return c / 2 * (ratio * ratio * ratio + 2) + b
end

--- @function
--- @description 四次方缓入
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @return number value 当前值
--- @range 服务端、客户端
local function inQuart(t, b, c, d) return c * pow(t / d, 4) + b end

--- @function
--- @description 四次方缓出
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @return number value 当前值
--- @range 服务端、客户端
local function outQuart(t, b, c, d) return -c * (pow(t / d - 1, 4) - 1) + b end

--- @function
--- @description 四次方缓入缓出
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @return number value 当前值
--- @range 服务端、客户端
local function inOutQuart(t, b, c, d)
    local ratio = t / d * 2
    if ratio < 1 then 
        return c / 2 * pow(ratio, 4) + b 
    end
    return -c / 2 * (pow(ratio - 2, 4) - 2) + b
end

--- @function
--- @description 五次方缓入
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @return number value 当前值
--- @range 服务端、客户端
local function inQuint(t, b, c, d) return c * pow(t / d, 5) + b end

--- @function
--- @description 五次方缓出
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @return number value 当前值
--- @range 服务端、客户端
local function outQuint(t, b, c, d) return c * (pow(t / d - 1, 5) + 1) + b end

--- @function
--- @description 五次方缓入缓出
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @return number value 当前值
--- @range 服务端、客户端
local function inOutQuint(t, b, c, d)
    local ratio = t / d * 2
    if ratio < 1 then 
        return c / 2 * pow(ratio, 5) + b 
    end
    return c / 2 * (pow(ratio - 2, 5) + 2) + b
end

--- @function
--- @description 正弦曲线缓入
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @return number value 当前值
--- @range 服务端、客户端
local function inSine(t, b, c, d) return -c * cos(t / d * (pi / 2)) + c + b end

--- @function
--- @description 正弦曲线缓出
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @return number value 当前值
--- @range 服务端、客户端
local function outSine(t, b, c, d) return c * sin(t / d * (pi / 2)) + b end

--- @function
--- @description 正弦曲线缓入缓出
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @return number value 当前值
--- @range 服务端、客户端
local function inOutSine(t, b, c, d) return -c / 2 * (cos(pi * t / d) - 1) + b end

--- @function
--- @description 指数曲线缓入
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @return number value 当前值
--- @range 服务端、客户端
local function inExpo(t, b, c, d)
    if t == 0 then return b end
    return c * pow(2, 10 * (t / d - 1)) + b - c * 0.001
end

--- @function
--- @description 指数曲线缓出
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @return number value 当前值
--- @range 服务端、客户端
local function outExpo(t, b, c, d)
    if t == d then return b + c end
    return c * 1.001 * (-pow(2, -10 * t / d) + 1) + b
end

--- @function
--- @description 指数曲线缓入缓出
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @return number value 当前值
--- @range 服务端、客户端
local function inOutExpo(t, b, c, d)
    if t == 0 then return b end
    if t == d then return b + c end
    local ratio = t / d * 2
    if ratio < 1 then 
        return c / 2 * pow(2, 10 * (ratio - 1)) + b - c * 0.0005 
    end
    return c / 2 * 1.0005 * (-pow(2, -10 * (ratio - 1)) + 2) + b
end

--- @function
--- @description 圆形曲线缓入
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @return number value 当前值
--- @range 服务端、客户端
local function inCirc(t, b, c, d) return -c * (sqrt(1 - pow(t / d, 2)) - 1) + b end

--- @function
--- @description 圆形曲线缓出
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @return number value 当前值
--- @range 服务端、客户端
local function outCirc(t, b, c, d) return c * sqrt(1 - pow(t / d - 1, 2)) + b end

--- @function
--- @description 圆形曲线缓入缓出
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @return number value 当前值
--- @range 服务端、客户端
local function inOutCirc(t, b, c, d)
    local ratio = t / d * 2
    if ratio < 1 then 
        return -c / 2 * (sqrt(1 - ratio * ratio) - 1) + b 
    end
    ratio = ratio - 2
    return c / 2 * (sqrt(1 - ratio * ratio) + 1) + b
end

--- @function
--- @description 计算弹性缓动参数
--- @param p number 周期
--- @param a number 振幅
--- @param c number 变化量
--- @param d number 持续时间
--- @return number p 周期
--- @return number a 振幅
--- @return number s 偏移量
--- @range 服务端、客户端
local function calculatePAS(p, a, c, d)
    p, a = p or d * 0.3, a or 0
    if a < abs(c) then return p, c, p / 4 end
    return p, a, p / (2 * pi) * asin(c / a)
end

--- @function
--- @description 弹性缓入,类似弹簧被压缩后释放
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @param a number 振幅
--- @param p number 周期
--- @return number value 当前值
--- @range 服务端、客户端
local function inElastic(t, b, c, d, a, p)
    if t == 0 then return b end
    t = t / d
    if t == 1 then return b + c end
    local s
    p, a, s = calculatePAS(p, a, c, d)
    t = t - 1
    return -(a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p)) + b
end

--- @function
--- @description 弹性缓出,类似弹簧释放
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @param a number 振幅
--- @param p number 周期
--- @return number value 当前值
--- @range 服务端、客户端
local function outElastic(t, b, c, d, a, p)
    if t == 0 then return b end
    t = t / d
    if t == 1 then return b + c end
    local s
    p, a, s = calculatePAS(p, a, c, d)
    return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p) + c + b
end

--- @function
--- @description 弹性缓入缓出
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @param a number 振幅
--- @param p number 周期
--- @return number value 当前值
--- @range 服务端、客户端
local function inOutElastic(t, b, c, d, a, p)
    if t == 0 then return b end
    local ratio = t / d * 2
    if ratio == 2 then return b + c end
    local s
    p, a, s = calculatePAS(p, a, c, d)
    ratio = ratio - 1
    if ratio < 0 then 
        return -0.5 * (a * pow(2, 10 * ratio) * sin((ratio * d - s) * (2 * pi) / p)) + b 
    end
    return a * pow(2, -10 * ratio) * sin((ratio * d - s) * (2 * pi) / p) * 0.5 + c + b
end

--- @function
--- @description 回退缓入,先后退再前进
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @param s number 回退幅度
--- @return number value 当前值
--- @range 服务端、客户端
local function inBack(t, b, c, d, s)
    s = s or 1.70158
    t = t / d
    return c * t * t * ((s + 1) * t - s) + b
end

--- @function
--- @description 回退缓出,先前进再回退
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @param s number 回退幅度
--- @return number value 当前值
--- @range 服务端、客户端
local function outBack(t, b, c, d, s)
    s = s or 1.70158
    t = t / d - 1
    return c * (t * t * ((s + 1) * t + s) + 1) + b
end

--- @function
--- @description 回退缓入缓出
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @param s number 回退幅度
--- @return number value 当前值
--- @range 服务端、客户端
local function inOutBack(t, b, c, d, s)
    s = (s or 1.70158) * 1.525
    local ratio = t / d * 2
    if ratio < 1 then 
        return c / 2 * (ratio * ratio * ((s + 1) * ratio - s)) + b 
    end
    ratio = ratio - 2
    return c / 2 * (ratio * ratio * ((s + 1) * ratio + s) + 2) + b
end

--- @function
--- @description 弹跳缓出,类似小球落地弹跳
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @return number value 当前值
--- @range 服务端、客户端
local function outBounce(t, b, c, d)
    local ratio = t / d
    if ratio < 1 / 2.75 then
        return c * (7.5625 * ratio * ratio) + b
    elseif ratio < 2 / 2.75 then
        ratio = ratio - (1.5 / 2.75)
        return c * (7.5625 * ratio * ratio + 0.75) + b
    elseif ratio < 2.5 / 2.75 then
        ratio = ratio - (2.25 / 2.75)
        return c * (7.5625 * ratio * ratio + 0.9375) + b
    end
    ratio = ratio - (2.625 / 2.75)
    return c * (7.5625 * ratio * ratio + 0.984375) + b
end

--- @function
--- @description 弹跳缓入
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @return number value 当前值
--- @range 服务端、客户端
local function inBounce(t, b, c, d) return c - outBounce(d - t, 0, c, d) + b end

--- @function
--- @description 弹跳缓入缓出
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @return number value 当前值
--- @range 服务端、客户端
local function inOutBounce(t, b, c, d)
    local halfDuration = d / 2
    if t < halfDuration then 
        return inBounce(t * 2, 0, c, d) * 0.5 + b 
    end
    return outBounce(t * 2 - d, 0, c, d) * 0.5 + c * 0.5 + b
end

--- @function
--- @description 抛物线曲线,可设置抛物线高度
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @param height number 抛物线高度
--- @return number value 当前值
--- @range 服务端、客户端
local function parabola(t, b, c, d, height)
    height = height or 0
    local p = t / d
    local extra = 4 * height * p * (1 - p)
    return b + c * p + extra
end

--- @function
--- @description 弹簧振荡曲线
--- @param t number 当前时间
--- @param b number 起始值
--- @param c number 变化量
--- @param d number 持续时间
--- @param damping number 阻尼系数
--- @param frequency number 振荡频率
--- @return number value 当前值
--- @range 服务端、客户端
local function spring(t, b, c, d, damping, frequency)
    damping = damping or 4
    frequency = frequency or 30
    local x = t / d
    local s = 1 - math.exp(-damping * x) * math.cos(frequency * x)
    return b + c * s
end

--- @variable
--- @description 缓动函数映射表,包含所有可用的缓动函数
Tween.easing = {
    linear = linear,

    inQuad = inQuad,
    outQuad = outQuad,
    inOutQuad = inOutQuad,

    inCubic = inCubic,
    outCubic = outCubic,
    inOutCubic = inOutCubic,

    inQuart = inQuart,
    outQuart = outQuart,
    inOutQuart = inOutQuart,

    inQuint = inQuint,
    outQuint = outQuint,
    inOutQuint = inOutQuint,

    inSine = inSine,
    outSine = outSine,
    inOutSine = inOutSine,

    inExpo = inExpo,
    outExpo = outExpo,
    inOutExpo = inOutExpo,

    inCirc = inCirc,
    outCirc = outCirc,
    inOutCirc = inOutCirc,

    inElastic = inElastic,
    outElastic = outElastic,
    inOutElastic = inOutElastic,

    inBack = inBack,
    outBack = outBack,
    inOutBack = inOutBack,

    inBounce = inBounce,
    outBounce = outBounce,
    inOutBounce = inOutBounce,

    parabola = parabola,
    spring = spring
}

-- ============================================
-- Tween 核心实现 (函数式风格)
-- ============================================

local MetaRegistry = setmetatable({}, { __mode = "k" })

--- @function
--- @description 递归拷贝表,支持元表
--- @param dest table 目标表
--- @param srcKeys table 源键表
--- @param srcVals table 源值表
--- @return table copiedTable 拷贝后的表
--- @range 服务端、客户端
local function copyTables(dest, srcKeys, srcVals)
    srcVals = srcVals or srcKeys
    -- 元表处理
    local keysMeta = MetaRegistry[srcKeys]
    if keysMeta and not MetaRegistry[dest] then
        MetaRegistry[dest] = keysMeta
        setmetatable(dest, keysMeta)
    end
    -- 递归复制
    for key, keyVal in pairs(srcKeys) do
        dest[key] = type(keyVal) == 'table'
            and copyTables({}, keyVal, srcVals[key])
            or srcVals[key]
    end
    return dest
end

--- @function
--- @description 递归检查主体和目标的类型是否匹配
--- @param subj table 主体对象
--- @param tgt table 目标对象
--- @param pathStack table 路径数组
--- @range 服务端、客户端
local function checkSubjectAndTargetRecursively(subj, tgt, pathStack)
    pathStack = pathStack or {}
    for key, tgtVal in pairs(tgt) do
        local tgtType = type(tgtVal)
        local currentPath = copyTables({}, pathStack)
        table.insert(currentPath, tostring(key))

        if tgtType == 'number' then
            assert(type(subj[key]) == 'number',
                "Parameter '" .. table.concat(currentPath, '/') .. "' is missing or isn't a number")
        elseif tgtType == 'table' then
            checkSubjectAndTargetRecursively(subj[key], tgtVal, currentPath)
        else
            assert(tgtType == 'number',
                "Parameter '" .. table.concat(currentPath, '/') .. "' must be a number or table")
        end
    end
end

--- @function
--- @description 获取缓动函数
--- @param easing string|function 缓动函数名或函数
--- @return function easingFunc 缓动函数
--- @range 服务端、客户端
local function getEasingFunction(easing)
    easing = easing or "linear"
    if type(easing) == 'string' then
        local func = Tween.easing[easing]
        if type(func) ~= 'function' then
            error("Invalid easing function: " .. easing)
        end
        return func
    end
    return easing
end

--- @function
--- @description 对主体对象执行缓动计算
--- @param subj table 主体对象
--- @param tgt table 目标值
--- @param initVal table 初始值
--- @param currentTime number 当前时间
--- @param totalDuration number 持续时间
--- @param easeFn function 缓动函数
--- @range 服务端、客户端
local function performEasingOnSubject(subj, tgt, initVal, currentTime, totalDuration, easeFn)
    for key, tgtVal in pairs(tgt) do
        if type(tgtVal) == 'table' then
            performEasingOnSubject(subj[key], tgtVal, initVal[key], currentTime, totalDuration, easeFn)
        else
            subj[key] = easeFn(currentTime, initVal[key], tgtVal - initVal[key], totalDuration)
        end
    end
end

--- @function
--- @description 创建一个 tween 状态对象 (函数式风格)
--- @param duration number 持续时间(秒),必须大于0
--- @param subject table 被缓动的对象,会被直接修改
--- @param target table 目标值,必须包含与subject对应的数字字段
--- @param easing string|function 缓动函数名或自定义函数,默认为"linear"
--- @return table state tween状态对象,包含duration、subject、target、easing、clock、initial字段
--- @range 服务端、客户端
--- @warning subject对象会被直接修改,如需保留原对象请先复制
--- @usage local state = Tween.Create(2, myObj, { x = 100, y = 200 }, "outQuad")
--- Tween.Set(state, 1)  -- 设置到1秒处
--- Tween.Update(state, 0.5)  -- 推进0.5秒
--- Tween.Reset(state)  -- 重置到起始状态
function Tween.Create(duration, subject, target, easing)
    assert(type(duration) == 'number' and duration > 0, "duration must be > 0")
    assert(type(subject) == 'table', "subject must be a table")
    assert(type(target) == 'table', "target must be a table")

    easing = getEasingFunction(easing)
    checkSubjectAndTargetRecursively(subject, target)

    return {
        duration = duration,
        subject = subject,
        target = target,
        easing = easing,
        clock = 0,
        initial = nil  -- 延迟初始化,首次调用时保存初始值
    }
end

--- @function
--- @description 设置 tween 到指定时间点
--- @param state table tween状态对象(由Create创建)
--- @param clock number 时间点(秒)
--- @return boolean finished 是否完成缓动
--- @range 服务端、客户端
function Tween.Set(state, clock)
    assert(type(state) == 'table', "state must be a tween state object")
    assert(type(clock) == 'number', "clock must be a number")

    state.initial = state.initial or copyTables({}, state.target, state.subject)
    state.clock = clock

    if state.clock <= 0 then
        state.clock = 0
        copyTables(state.subject, state.initial)
    elseif state.clock >= state.duration then
        state.clock = state.duration
        copyTables(state.subject, state.target)
    else
        performEasingOnSubject(state.subject, state.target, state.initial, state.clock, state.duration, state.easing)
    end

    return state.clock >= state.duration
end

--- @function
--- @description 重置 tween 到起始状态
--- @param state table tween状态对象(由Create创建)
--- @return boolean finished 是否完成(总是返回false)
--- @range 服务端、客户端
function Tween.Reset(state)
    assert(type(state) == 'table', "state must be a tween state object")
    return Tween.Set(state, 0)
end

--- @function
--- @description 更新 tween,推进指定时间
--- @param state table tween状态对象(由Create创建)
--- @param delta number 时间增量(秒)
--- @return boolean finished 是否完成缓动
--- @range 服务端、客户端
function Tween.Update(state, delta)
    assert(type(state) == 'table', "state must be a tween state object")
    assert(type(delta) == 'number', "delta must be a number")
    return Tween.Set(state, state.clock + delta)
end

--- @function
--- @description 计算指定时间点的值,不修改subject对象 (纯函数)
--- @param initial table 初始值
--- @param target table 目标值
--- @param currentTime number 当前时间
--- @param totalDuration number 持续时间
--- @param easing string|function 缓动函数名或自定义函数,默认为"linear"
--- @return table result 计算结果
--- @range 服务端、客户端
--- @usage local result = Tween.Calculate({ x = 0, y = 0 }, { x = 100, y = 200 }, 1, 2, "outQuad")
--- print(result.x, result.y)  -- 输出: 50 100
function Tween.Calculate(initial, target, currentTime, totalDuration, easing)
    easing = getEasingFunction(easing)

    local result = {}
    local function calculateRecursively(initVal, tgtVal, current, duration, easeFn, res)
        for key, tgtSubVal in pairs(tgtVal) do
            if type(tgtSubVal) == 'table' then
                res[key] = {}
                calculateRecursively(initVal[key], tgtSubVal, current, duration, easeFn, res[key])
            else
                res[key] = easeFn(current, initVal[key], tgtSubVal - initVal[key], duration)
            end
        end
    end

    calculateRecursively(initial, target, currentTime, totalDuration, easing, result)
    return result
end

return Tween
