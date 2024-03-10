const std = @import("std");
const log = std.debug.print;

pub fn build(b: *std.Build) void {
    // 创建一个目标和优化选项的标准配置
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // -- 这段代码是使用Zig编程语言创建一个名为"quickjs"的静态库的过程。

    // 添加一个名为"quickjs"的静态库，初始源文件路径为"src/dummy.zig"
    // 目标和优化级别使用前面创建的目标和优化选项
    const quickjs = b.addStaticLibrary(.{
        .name = "quickjs",
        .root_source_file = .{ .path = "src/dummy.zig" },
        .target = target,
        .optimize = optimize,
    });
    // 把"clib/quickjs"路径添加到编译器查找包含文件的路径列表中
    quickjs.addIncludePath(.{ .path = "clib/quickjs" });
    // 禁用C代码的运行时错误检测，通常是为了提高自包含库的执行性能
    quickjs.disable_sanitize_c = true;
    // 要编译的C源文件列表
    var files = [_][]const u8{
        "clib/quickjs/cutils.c",
        "clib/quickjs/libbf.c",
        "clib/quickjs/libunicode.c",
        "clib/quickjs/quickjs-libc.c",
        "clib/quickjs/quickjs.c",
        "clib/quickjs/libregexp.c",
    };
    var flags = [_][]const u8{
        "-g",
        "-Wall",
        "-D_GNU_SOURCE",
        "-DCONFIG_VERSION=\"2021-03-27\"",
        "-DCONFIG_BIGNUM",
    };
    // 把C源文件和编译标志添加到静态库项目中
    quickjs.addCSourceFiles(&files, &flags);
    // 链接静态库项目需要的C标准库
    quickjs.linkLibC();
    // 安装静态库二进制文件，也就是生成exe
    b.installArtifact(quickjs);

    // 添加一个名为"fre"的可执行文件，源代码路径为"src/main.zig"
    // 目标和优化级别使用前面创建的目标和优化选项
    const exe = b.addExecutable(.{
        .name = "fre",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    // 把"clib/quickjs"路径添加到编译器查找包含文件的路径列表中
    exe.addIncludePath(.{ .path = "clib/quickjs" });
    // 链接所需要的C标准库
    exe.linkLibC();
    // 链接前面创建的"quickjs"静态库
    exe.linkLibrary(quickjs);
    // 安装可执行文件
    b.installArtifact(exe);
    // 如果目标操作系统是Windows
    // 则添加"clib/mingw-w64-winpthreads/include"路径到编译器查找包含文件的路径列表中
    // 并添加"clib/mingw-w64-winpthreads/lib/libpthread.a"对象文件到程序中
    if (target.getOsTag() == .windows) {
        quickjs.addIncludePath(.{ .path = "clib/mingw-w64-winpthreads/include" });
        exe.addObjectFile(.{ .path = "clib/mingw-w64-winpthreads/lib/libpthread.a" });
    }

    // TODO: init lvgl
    // 这里先链接了C标准库，其余过程和quickjs类似
    exe.linkLibC();

    exe.addIncludePath(.{ .path = "./clib/lvgl" });
    exe.addIncludePath(.{ .path = "./clib/lvgl_drv" });

    const cflags = [_][]const u8{
        "-DLV_HOR_RES=800",
        "-DLV_VER_RES=480",
        "-DLV_CONF_INCLUDE_SIMPLE=1",
        "-fno-sanitize=all",
    };

    const lvgl_source_files = [_][]const u8{
        // core
        "clib/lvgl/src/core/lv_group.c",
        "clib/lvgl/src/core/lv_indev.c",
        "clib/lvgl/src/core/lv_indev_scroll.c",
        "clib/lvgl/src/core/lv_disp.c",
        "clib/lvgl/src/core/lv_theme.c",
        "clib/lvgl/src/core/lv_refr.c",
        "clib/lvgl/src/core/lv_obj.c",
        "clib/lvgl/src/core/lv_obj_class.c",
        "clib/lvgl/src/core/lv_obj_pos.c",
        "clib/lvgl/src/core/lv_obj_tree.c",
        "clib/lvgl/src/core/lv_obj_draw.c",
        "clib/lvgl/src/core/lv_obj_style.c",
        "clib/lvgl/src/core/lv_obj_style_gen.c",
        "clib/lvgl/src/core/lv_obj_scroll.c",
        "clib/lvgl/src/core/lv_event.c",
        //hal
        "clib/lvgl/src/hal/lv_hal_indev.c",
        "clib/lvgl/src/hal/lv_hal_tick.c",
        "clib/lvgl/src/hal/lv_hal_disp.c",
        //draw
        "clib/lvgl/src/draw/lv_draw.c",
        "clib/lvgl/src/draw/lv_draw_label.c",
        "clib/lvgl/src/draw/lv_draw_arc.c",
        "clib/lvgl/src/draw/lv_draw_rect.c",
        "clib/lvgl/src/draw/lv_draw_mask.c",
        "clib/lvgl/src/draw/lv_draw_line.c",
        "clib/lvgl/src/draw/lv_draw_img.c",

        "clib/lvgl/src/draw/sw/lv_draw_sw.c",
        "clib/lvgl/src/draw/sw/lv_draw_sw_blend.c",
        "clib/lvgl/src/draw/sw/lv_draw_sw_arc.c",
        "clib/lvgl/src/draw/sw/lv_draw_sw_rect.c",
        "clib/lvgl/src/draw/sw/lv_draw_sw_letter.c",
        "clib/lvgl/src/draw/sw/lv_draw_sw_img.c",
        "clib/lvgl/src/draw/sw/lv_draw_sw_line.c",
        "clib/lvgl/src/draw/sw/lv_draw_sw_polygon.c",
        "clib/lvgl/src/draw/sw/lv_draw_sw_gradient.c",

        "clib/lvgl/src/draw/lv_img_buf.c",
        "clib/lvgl/src/draw/lv_img_decoder.c",
        "clib/lvgl/src/draw/lv_img_cache.c",

        //misc
        "clib/lvgl/src/misc/lv_gc.c",
        "clib/lvgl/src/misc/lv_utils.c",
        "clib/lvgl/src/misc/lv_fs.c",
        "clib/lvgl/src/misc/lv_color.c",
        "clib/lvgl/src/misc/lv_async.c",
        "clib/lvgl/src/misc/lv_area.c",
        "clib/lvgl/src/misc/lv_anim.c",
        "clib/lvgl/src/misc/lv_txt.c",
        "clib/lvgl/src/misc/lv_tlsf.c",
        "clib/lvgl/src/misc/lv_timer.c",
        "clib/lvgl/src/misc/lv_style.c",
        "clib/lvgl/src/misc/lv_ll.c",
        "clib/lvgl/src/misc/lv_log.c",
        "clib/lvgl/src/misc/lv_printf.c",
        "clib/lvgl/src/misc/lv_mem.c",
        "clib/lvgl/src/misc/lv_math.c",
        "clib/lvgl/src/misc/lv_style_gen.c",
        // widgets
        "clib/lvgl/src/widgets/lv_arc.c",
        "clib/lvgl/src/widgets/lv_btn.c",
        "clib/lvgl/src/widgets/lv_btnmatrix.c",
        "clib/lvgl/src/widgets/lv_bar.c",
        "clib/lvgl/src/widgets/lv_dropdown.c",
        "clib/lvgl/src/widgets/lv_textarea.c",
        "clib/lvgl/src/widgets/lv_checkbox.c",
        "clib/lvgl/src/widgets/lv_switch.c",
        "clib/lvgl/src/widgets/lv_roller.c",
        "clib/lvgl/src/widgets/lv_slider.c",
        "clib/lvgl/src/widgets/lv_table.c",
        "clib/lvgl/src/widgets/lv_img.c",
        "clib/lvgl/src/widgets/lv_label.c",
        "clib/lvgl/src/widgets/lv_line.c",
        // extra
        "clib/lvgl/src/extra/lv_extra.c",
        "clib/lvgl/src/extra/widgets/tabview/lv_tabview.c",
        "clib/lvgl/src/extra/widgets/win/lv_win.c",
        "clib/lvgl/src/extra/widgets/msgbox/lv_msgbox.c",
        "clib/lvgl/src/extra/widgets/chart/lv_chart.c",
        "clib/lvgl/src/extra/widgets/spinner/lv_spinner.c",
        "clib/lvgl/src/extra/widgets/calendar/lv_calendar.c",
        "clib/lvgl/src/extra/widgets/calendar/lv_calendar_header_arrow.c",
        "clib/lvgl/src/extra/widgets/calendar/lv_calendar_header_dropdown.c",
        "clib/lvgl/src/extra/widgets/meter/lv_meter.c",
        "clib/lvgl/src/extra/widgets/keyboard/lv_keyboard.c",
        "clib/lvgl/src/extra/widgets/list/lv_list.c",
        "clib/lvgl/src/extra/widgets/menu/lv_menu.c",
        "clib/lvgl/src/extra/layouts/flex/lv_flex.c",
        "clib/lvgl/src/extra/themes/default/lv_theme_default.c",
        // font
        "clib/lvgl/src/font/lv_font.c",
        "clib/lvgl/src/font/lv_font_fmt_txt.c",
        "clib/lvgl/src/font/lv_font_montserrat_14.c",

        // lvgl_drv
        "clib/lvgl_drv/lv_sdl_disp.c",
        "clib/lvgl_drv/lv_port_indev.c",
        "clib/lvgl_drv/lv_xbox_disp.c",
    };

    //不过这里相当于可执行文件直接添上了C Source Files，而不是生成静态库再添加
    exe.addCSourceFiles(
        &lvgl_source_files,
        &cflags,
    );

    // TODO: init sdl

    // 如果目标操作系统是macOS且CPU架构是ARM64（主要针对M1芯片的Mac）
    if (target.getOsTag() == .macos and target.getCpuArch().isAARCH64()) {
        const homebrew_path = "/opt/homebrew";
        // 把"/opt/homebrew/include/SDL2"路径添加到编译器查找包含文件的路径列表中
        exe.addIncludePath(.{ .path = homebrew_path ++ "/include/SDL2" });
        // 把"/opt/homebrew/lib"路径添加到编译器查找库文件的路径列表中
        exe.addLibraryPath(.{ .path = homebrew_path ++ "/lib" });
        // 链接系统库SDL2
        exe.linkSystemLibrary("SDL2");
    } else {
        const sdl_path = "D:\\SDL2_2.28.4\\x86_64-w64-mingw32\\";
        // 把"D:\\SDL2_2.28.4\\x86_64-w64-mingw32\\include"路径添加到编译器查找包含文件的路径列表中
        exe.addIncludePath(.{ .path = sdl_path ++ "include" });
        // 把"D:\\SDL2_2.28.4\\x86_64-w64-mingw32\\lib\\x64"路径添加到编译器查找库文件的路径列表中
        exe.addLibraryPath(.{ .path = sdl_path ++ "lib\\x64" });
        // 安装所需的DLL文件
        b.installBinFile(sdl_path ++ "lib\\x64\\SDL2.dll", "SDL2.dll");
        b.installBinFile(sdl_path ++ "lib\\x64\\SDL2_image.dll", "SDL2_image.dll");
        b.installBinFile(sdl_path ++ "lib\\x64\\SDL2_ttf.dll", "SDL2_ttf.dll");
        // 链接系统库sdl2、sdl2_image、sdl2_ttf
        exe.linkSystemLibrary("sdl2");
        exe.linkSystemLibrary("sdl2_image");
        exe.linkSystemLibrary("sdl2_ttf");
    }
    // This line of code specifies the subsystem of the executable as Windows.
    // exe.subsystem = .Windows;

    // 链接C库
    exe.linkLibC();
    // b.installArtifact(exe); 的目标是把工件放在一个能被用户或其他系统找到的地方，在执行build的时候被触发
    // b.addRunArtifact(exe); 的目标是让工件能被执行（用于开发和测试），在执行run的时候被触发，
    const run_cmd = b.addRunArtifact(exe);
    // 将运行应用程序的步骤设为安装步骤的依赖，确保在运行应用程序之前完成安装
    run_cmd.step.dependOn(b.getInstallStep());
    // 如果命令行参数存在，将它们添加到运行应用程序的参数中
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    // 添加一个运行应用程序的步骤，并设定其依赖
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
    // 添加单元测试，指定源文件、目标和优化级别
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    // 将单元测试加到运行工件
    const run_unit_tests = b.addRunArtifact(unit_tests);
    // 添加运行单元测试的步骤，并设定其依赖
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
