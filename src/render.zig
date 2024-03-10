const std = @import("std");
// 导入一些需要的模块
const print = std.debug.print;
const sdl = @import("./sdl.zig");
const qjs = @import("./qjs.zig");
const text = @import("./component/text.zig");
const view = @import("./component/view.zig");
pub fn render(direct: []const u8) !void {
    const allocator = std.heap.page_allocator;
    var parser = std.json.Parser.init(allocator, false);
    defer parser.deinit();
    // 解析传递进来的direct参数，direct参数应该是一个JSON字符串
    var tree = parser.parse(direct) catch |err| {
        std.debug.print("error: {s}", .{@errorName(err)});
        return;
    };
    // 从解析出来的JSON中获取需要的属性值
    var _type = tree.root.Object.get("type").?.String;
    var _x = tree.root.Object.get("x").?.String;
    var _y = tree.root.Object.get("y").?.String;
    var _w = tree.root.Object.get("w").?.String;
    var _h = tree.root.Object.get("h").?.String;
    // 将字符串类型的坐标和大小转为整数
    const xx = try std.fmt.parseInt(i32, _x, 10);
    const yy = try std.fmt.parseInt(i32, _y, 10);
    const ww = try std.fmt.parseInt(i32, _w, 10);
    const hh = try std.fmt.parseInt(i32, _h, 10);
    // 根据_type的类型调用不同的绘制函数
    if (std.mem.eql(u8, _type, "#text")) {
        var _data = tree.root.Object.get("data").?.String;
        const terminated = try allocator.dupeZ(u8, _data);
        defer allocator.free(terminated);
        text.drawFont(terminated[0..terminated.len], xx, yy);
    }
    if (std.mem.eql(u8, _type, "VIEW")) {
        view.drawView(xx, yy, ww, hh);
    }
    // 提交所有的渲染操作到渲染器，并更新整个窗口的画面
    _ = sdl.SDL_RenderPresent(sdl.renderer);
}
