#!/usr/bin/env python3
from random import randint

def LookUpTable(val):
    if val == 0:
        out = 64
    elif val == 1:
        out = 121
    elif val == 2:
        out = 36
    elif val == 3:
        out = 48
    elif val == 4:
        out = 25
    elif val == 5:
        out = 18
    elif val == 6:
        out = 2
    elif val == 7:
        out = 120
    elif val == 8:
        out = 0
    elif val == 9:
        out = 16
    elif val == 10:
        out = 8
    elif val == 11:
        out = 3
    elif val == 12:
        out = 70
    elif val == 13:
        out = 33
    elif val == 14:
        out = 6
    else:
        out = 14 
    return out

# param R: random number
# param 7seg_list: 8 integers representing the desired output digits
def print_formatter(R, seg_list):
    _R = list(bin(R)[2:]) # binary represntation of R as a string
    while len(_R) < 18:
        _R.insert(0,'0')
    _R = ''.join(_R)


    # get the binary representation of the 7seg displays
    one,two,three,four,five,six,seven,eight = [list(bin(LookUpTable(o))[2:]) for o in seg_list]
    while len(one) < 8:
        one.insert(0,'0')
    while len(two) < 8:
        two.insert(0,'0')
    while len(three) < 8:
        three.insert(0,'0')
    while len(four) < 8:
        four.insert(0,'0')
    while len(five) < 8:
        five.insert(0,'0')
    while len(six) < 8:
        six.insert(0,'0')
    while len(seven) < 8:
        seven.insert(0,'0')
    while len(eight) < 8:
        eight.insert(0,'0')
    one = ''.join(one)
    two = ''.join(two)
    three = ''.join(three)
    four = ''.join(four)
    five = ''.join(five)
    six = ''.join(six)
    seven = ''.join(seven)
    eight = ''.join(eight)

    _seg = '_'.join([one,two,three,four,five,six,seven,eight])



    print(_R+'_'+_seg)


if __name__ == "__main__":
    SHIFT_AMT = 14#+32
    # upper bound is 262143
    BOUND = (1<<18)-1
    for i in range(BOUND):
        R = i << SHIFT_AMT
        guess = R >> 1
        step = R >> 2
        while step > 0:
            square = guess*guess
            if square == R:
                break
            elif square > R:
                guess -= step
            else:
                guess += step
            step = step >> 1
        final_guess = int(guess*100000)>>(SHIFT_AMT>>1)
        out_values = [int(o) for o in list(str(final_guess))]
        while len(out_values) < 8:
            out_values.insert(0,0)

        print_formatter(i,out_values)
