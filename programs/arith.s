# ThetaCore: arithmetic and memory
# expects x1=5 x2=7 x3=12 x4=2 x5=12, mem[64]=12

        addi    x1, x0, 5           # x1 = 5
        addi    x2, x0, 7           # x2 = 7
        add     x3, x1, x2          # x3 = 12
        sub     x4, x2, x1          # x4 = 2
        sw      x3, 64(x0)          # mem[64] = 12
        lw      x5, 64(x0)          # x5 = 12
        ecall
