// 引入 LVGL 库，一个开源的图形库
const lv = @import("./lvgl.zig");
// 引入标准库
const std = @import("std");
// 定义一个公用函数 runLvgl，不返回任何内容
pub fn runLvgl() void {
    // 初始化 LVGL 库
    lv.lv_init();
    // 在函数结束时，自动反初始化 LVGL 库
    defer lv.lv_deinit();
    // 初始化显示器，分辨率设为 640 x 480
    lv.lv_port_disp_init(640, 480);
    // 在函数结束时，自动反初始化显示器
    defer lv.lv_port_disp_deinit();
    // 初始化输入设备（如触摸屏，鼠标等），参数为 true 表示启用输入设备
    lv.lv_port_indev_init(true);
    // 在函数结束时，自动反初始化输入设备
    defer lv.lv_port_indev_deinit();
    // 获取当前活跃的屏幕
    _ = lv.lv_scr_act();
    // 设置活跃屏幕的背景颜色，0x003a57 是颜色的 HEX 值
    lv.lv_obj_set_style_bg_color(lv.lv_scr_act(), lv.lv_color_hex(0x003a57), lv.LV_PART_MAIN);
    // 在当前活跃的屏幕上创建一个标签，赋值给变量 label
    var label = lv.lv_label_create(lv.lv_scr_act());
    // 为标签设置文本内容，"Hello world"
    _ = lv.lv_label_set_text(label, "Hello world");
    // 设置屏幕中文本对象的颜色，0xFFFFFF 是白色的 HEX 值
    _ = lv.lv_obj_set_style_text_color(lv.lv_scr_act(), lv.lv_color_hex(0xffffff), lv.LV_PART_MAIN);
    // 将标签对象 label 居中对齐至屏幕
    _ = lv.lv_obj_align(label, lv.LV_ALIGN_CENTER, 0, 0);
    // 通过标准库的 time.milliTimestamp 快速获取当前的毫秒级时间戳，赋值给变量 lastTick
    var lastTick: i64 = std.time.milliTimestamp();
    // 开始一个无限循环，用于更新 LVGL 的状态
    while (true) {
        // 更新 LVGL 的 tick 数值，值等于当前的毫秒级时间戳减去上一次更新的时间戳
        lv.lv_tick_inc(@as(u32, @intCast(std.time.milliTimestamp() - lastTick)));
        // 更新 lastTick 的值为当前的毫秒级时间戳
        lastTick = std.time.milliTimestamp();
        // 调用 LVGL 的任务处理函数，用于处理界面更新、输入事件等
        _ = lv.lv_task_handler();
    }
}
