# Finch-OS
The Finch Operating Sysytem is a simple operating system written entirely in assembly with partial LLM assistance. It fits within just one file, featuring a bootloader, a kernel, a basic menu, basic sound output, a pseudo-filesystem with multi-diamensional arrays for memory managment and a shell with many commands available, including 5 fun games. As you will notice while exploring it, there are many easter eggs as well. It was created for education and leisure purposes only and it is not meant to be an actual professional product. The repository contains this README.md, the source code in assembly, the ISO image used for running the product, a screenshot1.png and screenshot2.png files.

Some useful tips to get you started;
1. It is strongly recommended to run it on actual hardware.
2. Once you boot into the menu, press "1" to launch the shell and then type "help" to list all available commands.
3. You can quit all games by pressing q.

Known issues;
1. Qemu is the best way to run it virtually. However, a bug is present where characters lose their original green colour after a while and sound might not work properly.
2. On VirtualBox, it will not run at all.
Feel free to fork!
