source("Fun.R")
source("Fun_DR.R")
source("Fun_parallel.R")
library(ivsacim)
library(nleqslv)
expit = function(d) return(exp(d)/(exp(d)+1))

n = 1000
nrep = 100
parameters1 = NULL
parameters2 = NULL
for(i in 1:nrep){
  r = 0.5
  L = runif(n, 0, 1)
  L = matrix(L, nrow = n)
  U = runif(n, 0, 1)
  epsilon = rnorm(n)
  Z_p = expit(r*L)
  Z = rbinom(n, 1, Z_p)
  C = rexp(n)/(0.01 + 0.05*L)
  max_t = 6
  W = rexp(n)/(0.01 + 0.01*L + 0.1*Z + 0.01*U)
  
  F_time = function(t, w, z, l, u, uni) {
    ifelse(t < w, 1 - exp(-0.25*t - 0.1*z*t - 0.075*l*t- 0.075*u*t)-uni, 
           1 - exp(-0.25*t - 0.1*z*w - 0.1*(1-z)*(t-w) - 0.075*l*t
                   - 0.075*u*t) - uni)
  }
  time = nleqslv(rep(0, n), F_time, w = W, z = Z, l = L, u = U, uni = runif(n))$x
  time_c = ifelse(time <= C, time, C)
  time_c = ifelse(time_c <= max_t, time_c, max_t)
  event = ifelse(time<=C & time<=max_t, 1, 0)
  stime = sort(time_c[as.logical(event)])
  k = length(stime)
  D_status = treatment_status(n, k, stime, Z, W, max_t)
  Cov = cbind(L, U)
  s1 = nleqslv(0, ConstantF_left, time = time_c, event = event, IV = Z, 
               Covariates = Cov, D_status = D_status, stime = stime)
  s2 = nleqslv(0, ConstantF_left, time = time_c, event = event, IV = Z,
               Covariates = L, D_status = D_status, stime = stime)
  parameters1 = cbind(parameters1, s1$x)
  parameters2 = cbind(parameters2, s2$x)
  cat("+", "rep ", i, "  add: ", s1$x, "\n", s1$message, "\n",
      "  ignore: ",s2$x, "]]\n", s2$message, "\n",
      sep = "")
}


cat("simulation\n",
    "add:\n",
    apply(parameters1 - matrix(c(0.1, 0.075, 0.075), 
                               nrow = 3, ncol = nrep), 1, mean), "\n",
    apply(parameters1, 1, sd), "\n",
    "ignore:\n",
    apply(parameters2 - matrix(c(0.1, 0.075), 
                               nrow = 2, ncol = nrep), 1, mean), "\n",
    apply(parameters2, 1, sd))