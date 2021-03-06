#Diamond-Square Algo Python example
import random
import time

def diamond_square(w, h):

    global arry, width, height, rand
    width = w
    height = h
    rand = 12
    arry = [ [0]* w for i in range(height)]
    #Initialize random corners
    arry[0][0] = random.randint(0, rand)
    arry[0][width-1] = random.randint(0, rand)
    arry[height-1][0] = random.randint(0, rand)
    arry[height-1][width-1] = random.randint(0, rand)

    
    arry[0][0] = 0xbb
    arry[0][width-1] = 0xbb
    arry[height-1][0] = 0xee
    arry[height-1][width-1] = 0xee
    
    # print(arry[0][0])
    # print(arry[0][width-1])
    # print(arry[height-1][0])
    # print(arry[height-1][width-1])
    
    step_size = width-1
    
    while step_size > 1:
        
        half = step_size // 2
        r = random.randint(0, rand)
        for i in range(half, height, step_size):
            for j in range(half, width, step_size):
                diamond_step(i, j, step_size, r)
        
        col = 0
        for i in range(0, width, half):
            col+=1
            if(col % 2):
                for j in range(half, height, step_size):
                    square_step(i, j, step_size, r)
            else:
                for j in range(0, height, step_size):
                    square_step(i, j, step_size, r)
                    
        step_size = step_size // 2
        rand = rand-1

   
def diamond_step(x, y, step_size, r):
    global arry
    avg = (arry[x-step_size//2][y+step_size//2] + arry[x+step_size//2][y+step_size//2] + arry[x+step_size//2][y-step_size//2] + arry[x-step_size//2][y-step_size//2]) // 4
    arry[x][y] = avg + r
    arry[x][y] = avg 
    

def square_step(x, y, step_size, r):
    global arry, width, height
    avg = 0
    count = 0
    if (x-step_size//2 >= 0):
        # print("first: ", arry[x-step_size//2][y])
        avg += arry[x-step_size//2][y]
        # print((x-step_size//2), (x-step_size//2)%width)
        # count+=1
    else:
        # print((x-step_size//2), (x-step_size//2)%width - 1 )
        # print("first: ", arry[(x-step_size//2)%width - 1][y])
        avg += arry[(x-step_size//2)%width - 1][y]

    if (y-step_size//2 >= 0):
        # print(arry[x][y-step_size//2])
        # print ("second: ", arry[x][y-step_size//2])
        avg += arry[x][y-step_size//2]
        # count+=1
    else:
        avg += arry[x][(y-step_size//2)%width -1]

    if (x+step_size//2 < width):
        # print ("third: ", arry[x+step_size//2][y])
        avg += arry[x+step_size//2][y]
        # count+=1
    else:
        avg += arry[(x+step_size//2)%width + 1][y]

    if (y+step_size//2 < height):
        # print ("fourth: ", arry[x][y+step_size//2])
        avg += arry[x][y+step_size//2]
        # count+=1
    else:
        avg += arry[x][(y+step_size//2)%width + 1]
    avg += r
    arry[x][y] = avg // 4
    # print("AVEG:", avg // 4)
    # print()
   
   
global arry
size = 257
start_time = time.time()
diamond_square(size,size)
print("--- %s seconds ---" % (time.time() - start_time))

# for i in range(size):
    # for j in range(size):
        # print('%.2f '% arry[height-1-i][j], end='')
    # print("")
    