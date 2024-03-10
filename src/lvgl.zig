// pub usingnamespace 是一个范围限定符，它允许我们在当前作用域访问引入的所有声明。
// @cImport 是一个内建函数，它的作用是读取并导入C头文件，并将他们作为编译时的符号出现在Zig语言的作用域中。该函数返回一个结构体，包含所有导入的C头文件中定义的函数、变量和类型。
pub usingnamespace @cImport({
    // @cDefine 是一个内建函数，用来在C预处理器中定义宏。在这里，"USE_SDL" 和 "ZIG" 被定义为 "1"。
    @cDefine("USE_SDL", "1");
    @cDefine("ZIG", "1");
    // @cInclude 是一个内建函数，它用来导入C头文件。这里导入了 LVGL 库以及其显示和输入设备的头文件。
    @cInclude("lvgl.h");
    @cInclude("lv_port_disp.h");
    @cInclude("lv_port_indev.h");
});
