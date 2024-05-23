# ASM Prompt
Assembly interpreter for Commander X16

This program in Commodore X16 Downloads page: https://cx16forum.com/forum/viewtopic.php?t=7666

**HOW IT WORKS:** if the inputted instruction is single-byte implied addressing mode one, it takes A, X, Y and PS registers that are cached in zero page, executes the instruction and stores potentially changed registers back to zero page. For more than one byte long instructions, it assembles the instruction from the input the user gave, pulls the registers from zero page, jumps to instruction and pushes the registers back to zero page.

You can assemble this program with this command (you need to install cl65 yourself): `cl65 -t cx16 -o your_output_filename asmprompt.asm`
