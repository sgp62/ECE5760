dt = (1./256)
x = [-1.]
y = [0.1]
z = [25.]
sigma = 10.0
beta = 8./3.
rho = 28.0

def dx(sigma, x, y):
    return sigma*(y-x)

def dy(rho, x, y, z):
    return x*(rho-z)-y

def dz(beta, x, y, z):
    return x*y - beta*z

for i in range(10000):
    x.extend([x[i] + dt*dx(sigma, x[i], y[i])])
    y.extend([y[i] + dt*dy(rho, x[i], y[i], z[i])])
    z.extend([z[i] + dt*dz(beta, x[i], y[i], z[i])])
	
	print(x[-1])
	print(y[-1])
	print(z[-1])