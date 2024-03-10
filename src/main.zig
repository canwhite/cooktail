// 导入Zig标准库
const std = @import("std");
// 从标准库中导入 print 函数，一般用于调试和输出信息
const print = std.debug.print;
// 引入本地文件，这可能是你的项目特殊的一部分
const sld = @import("./sdl.zig");
const qjs = @import("./qjs.zig");
const llv = @import("./lv.zig");
// 使用别名简化对文件系统(fs)和内存管理(mem)函数的访问
const fs = std.fs;
const mem = std.mem;
// 定义主函数，这是Zig程序的入口点
pub fn main() !void {
    // 调用llv模块中的runLvgl函数，似乎是开始运行LVGL图形库的部分
    llv.runLvgl();

    // 这行代码定义了一个名为allocator的常量，它使用的是C语言的内存分配器进行内存管理。
    const allocator = std.heap.c_allocator;
    // 创建一个参数迭代器，用来遍历命令行参数。使用try可以捕获可能出现的错误。
    var argIter = try std.process.argsWithAllocator(allocator);
    // 使用下划线接收并忽略了第一个参数，通常第一个参数是程序自身的路径。
    _ = argIter.next();
    // 获取下一个参数，应该是要执行的JavaScript文件的路径。如果没有下一个参数，函数将返回一个InvalidSource错误。
    // const file = mem.span(argIter.next()) orelse return error.InvalidSource;
    // // 这行代码会读取文件内容，如读取失败则直接返回错误。这里限制了文件大小上限为1MB。
    // const src = try fs.cwd().readFileAlloc(allocator, file, 1024 * 1024);
    // // 使用defer关键字执行延迟操作，无论函数如何结束，总能保证分配的内存被释放掉，可以防止内存泄漏。
    // defer allocator.free(src);
    // // 运行JavaScript代码，如果执行过程中出现错误，就直接返回错误。
    // try qjs.runMicrotask(allocator, src);
}
