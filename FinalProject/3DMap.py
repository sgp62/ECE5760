import numpy as np

[x,y]=np.meshgrid(np.linspace(0,8,num=9),np.linspace(0,8,num=9));
print(x)
z = np.array([
[187,	176,	152,	139,	61,	  142,	148,	177,	187],
[165,	162,	151,	134,	122,	135,	153,	164,	165],
[148,	153,	159,	159,	160,	160,	159,	155,	149],
[131,	143,	165,	185,	193,	186,	169,	148,	131],
[87,	141,	176,	203,	243,	206,	185,	145,	87],
[148,	161,	187,	211,	223,	213,	193,	163,	148],
[181,	187,	201,	212,	227,	213,	200,	190,	181],
[208,	205,	205,	211,	217,	212,	205,	206,	208],
[238,	203,	203,	191,	216,	192,	203,	202,	238]
])

x_flat = np.matrix.flatten(x); #Gridded longitude
y_flat = np.matrix.flatten(y); #Gridded latitude
z_flat = np.matrix.flatten(z)/np.max(z) * 255; #Gridded elevation

import matplotlib.pyplot as plt
plt.scatter(x_flat,y_flat,600,z_flat, marker="s")
plt.colorbar(label='Elevation above sea level [m]')
plt.xlabel('Longitude [°]')
plt.ylabel('Latitude [°]')

plt.show() 



# show hight map in 3d
fig = plt.figure()
ax = fig.add_subplot(111, projection='3d')
ax.plot_surface(x, y, z)
plt.title('z as 3d height map')
plt.show()
