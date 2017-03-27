/cmd_.*\/.*.o := .*/d
/deps_.*\/.*.o := \\/d
/.*\/.*\.o: \$(deps_.*\/.*\.o)/d
/\$(deps_.*\/.*\.o):/d
/^$/d
s/^ \+//g
s/ \\$//g
s/source_.*\/.*\.o := \(.*\)/\1/g
s:\$(wildcard \(.*\)):\1:g
#s:^\([^\/].*\):/media/software/work/bobluo/hengs/repo/out/target/product/msm8937_64/obj/KERNEL_OBJ/\1:g
p
