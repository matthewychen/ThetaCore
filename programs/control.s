# ThetaCore: control flow
# a not-taken branch, a taken branch, and a jump with link
# expects x1=5 x2=5 x3=1 x4=0 x5=28 x6=0

        addi    x1, x0, 5
        addi    x2, x0, 5
        bne     x1, x2, skip_a      # not taken, x1 == x2
        addi    x3, x0, 1           # runs
        beq     x1, x2, skip_b      # taken
skip_a:
        addi    x4, x0, 99          # skipped
skip_b:
        jal     x5, done            # x5 = PC+4 = 28
        addi    x6, x0, 77          # skipped
done:
        ecall
