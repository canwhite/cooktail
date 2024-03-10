//SDL是一个访问音频、键盘、鼠标、操纵杆以及图形硬件的库。
//在这里，SDL被用来创建一个窗口，提供图形渲染，并处理用户的输入

// 导入Zig标准库
const std = @import("std");
// cImport 将C库导入Zig
// 这里导入了SDL，这是一套开放源代码的跨平台多媒体开发库
// 使用SDL库的头文件
const sdl = @cImport({
    @cInclude("SDL.h");
    @cInclude("SDL_image.h");
    @cInclude("SDL_ttf.h");
});
// 其他的一些导入
const assert = @import("std").debug.assert;
const text = @import("./component/text.zig");
const print = std.debug.print;
const qjs = @import("./qjs.zig");
const r = @import("./render.zig");
// 引入sdl命名空间的所有公共成员
pub usingnamespace sdl;
// SDL_Window结构体用于表示一个窗口
pub var window: ?*sdl.SDL_Window = null;
// SDL_Renderer结构体用于渲染操作
pub var renderer: ?*sdl.SDL_Renderer = null;
// runsdl函数用于初始化SDL，创建窗口和渲染器，并运行事件循环
pub fn runsdl() anyerror!void {
    // 初始化SDL库
    _ = sdl.SDL_Init(sdl.SDL_INIT_VIDEO | sdl.SDL_INIT_AUDIO);
    // 确保在退出时调用SDL_Quit来清理
    defer sdl.SDL_Quit();
    // 创建窗口和渲染器
    _ = sdl.SDL_CreateWindowAndRenderer(
        640, // 窗口宽度
        480, // 窗口高度
        sdl.SDL_WINDOW_RESIZABLE | sdl.SDL_WINDOW_ALLOW_HIGHDPI,
        &window,
        &renderer,
    );
    // 确保在退出时销毁窗口
    defer sdl.SDL_DestroyWindow(window);
    // 其他代码是事件循环，用于处理用户输入以及每帧的渲染
    // 这是一个永久进行的事件循环
    eventloop: while (true) {
        // 创建一个SDL_Event实例用于存储查询到的事件
        var event: sdl.SDL_Event = undefined;
        // SDL_PollEvent获取一個事件，如果获取成功则返回1，否则返回0
        while (sdl.SDL_PollEvent(&event) != 0) {
            // 根据事件类型执行不同的操作
            switch (event.type) {
                // SDL_QUIT事件表示用户要关闭窗口
                sdl.SDL_QUIT => {
                    // 使用标签 (eventloop) 跳出事件循环
                    break :eventloop;
                },
                // SDL_KEYDOWN事件表示用户按下了一个键
                sdl.SDL_KEYDOWN => {},
                // SDL_MOUSEBUTTONDOWN事件表示用户按下了鼠标
                sdl.SDL_MOUSEBUTTONDOWN => {
                    // 为JavaScript函数提供参数
                    var args = [_]qjs.JSValue{ qjs.JS_NewInt32(qjs.js_ctx, event.motion.x), qjs.JS_NewInt32(qjs.js_ctx, event.motion.y) };
                    // 调用JavaScript函数“bubblingClick”，并传入2个参数
                    _ = qjs.js_call("bubblingClick", 2, &args);
                },
                // 其他类型的事件目前不做处理
                else => {},
            }
        }
        // 调用getRenderQueue JavaScript函数来更新渲染队列，参数为空
        var args = [_]qjs.JSValue{};
        var direct = qjs.js_call("getRenderQueue", 0, &args);
        // 如果渲染队列不为空，调用渲染函数进行渲染
        if (!std.mem.eql(u8, direct, "null")) {
            try r.render(direct);
        } else {}
        //  为了达到每秒60帧的刷新率，延迟执行时间以达到控制帧数的目的
        sdl.SDL_Delay(1000 / 60);
    }
}
