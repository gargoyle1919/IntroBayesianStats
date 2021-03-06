#Problem 2
#a
interexp<-read.table("interexp.dat",header=T)
apply(interexp,2,mean,na.rm=T)
apply(interexp,2,var,na.rm=T)
cor(interexp[!(is.na(interexp$yA)|is.na(interexp$yB)),])
#b
mean.a.hat<-mean(interexp$yA,na.rm = T)
mean.b.hat<-mean(interexp$yB,na.rm = T)
var.a.hat<-var(interexp$yA,na.rm = T)
var.b.hat<-var(interexp$yB,na.rm = T)
cor.hat<-cor(interexp[!(is.na(interexp$yA)|is.na(interexp$yB)),])[1,2]
interexp.b<-interexp
interexp.b[,1]<-ifelse(is.na(interexp[,1]),mean.a.hat+(interexp[,2]-mean.b.hat)*cor.hat*sqrt(var.a.hat/var.b.hat),interexp[,1])
interexp.b[,2]<-ifelse(is.na(interexp[,2]),mean.b.hat+(interexp[,1]-mean.a.hat)*cor.hat*sqrt(var.b.hat/var.a.hat),interexp[,2])
t.test(interexp.b[,1],interexp.b[,2],paired = T)
t.test(interexp.b[,1],interexp.b[,2],paired = T)$conf.int
#c

#prior parameters
n<-nrow(interexp); p<-ncol(interexp)


#starting values
Sigma<-cov(interexp.b)
Y.full<-interexp.b
O<-1*(!is.na(interexp))


#code from Chapter 7, Hoff
#Generate random multivariate normal variable
rmvnorm<-
  function(n,mu,Sigma) {
    p<-length(mu)
    res<-matrix(0,nrow=n,ncol=p)
    if( n>0 & p>0 ) {
      E<-matrix(rnorm(n*p),n,p)
      res<-t(  t(E%*%chol(Sigma)) +c(mu))
    }
    res
  }

#sample from the Wishart distribution
rwish<-function(n,nu0,S0)
{
  sS0 <- chol(S0)
  S<-array( dim=c( dim(S0),n ) )
  for(i in 1:n)
  {
    Z <- matrix(rnorm(nu0 * dim(S0)[1]), nu0, dim(S0)[1]) %*% sS0
    S[,,i]<- t(Z)%*%Z
  }
  S[,,1:n]
}

#Gibbs sampler
THETA<-SIGMA<-Y.MISS<-NULL
set.seed(1)
for(s in 1:1000){
  
  #update theta
  ybar<-apply(Y.full,2,mean)
  theta<-rmvnorm(1,ybar,Sigma/n)
  
  #update Sigma
  Stheta<-(t(Y.full)-c(theta))%*%t(t(Y.full)-c(theta))
  Sigma<-solve(rwish(1,1+n,Stheta))
  
  #update missing data
  for(i in 1:n){
    b<-(O[i,]==0)
    a<-(O[i,]==1)
    iSa<-solve(Sigma[a,a])
    beta.j<-Sigma[b,a]%*%iSa
    theta.j<-theta[b]+beta.j%*%(t(Y.full[i,a])-theta[a])
    Sigma.j<-Sigma[b,b]-beta.j%*%Sigma[a,b]
    Y.full[i,b]<-rmvnorm(1,theta.j,Sigma.j)
  }
  
  #save results
  THETA<-rbind(THETA,theta); SIGMA<-rbind(SIGMA, c(Sigma))
  Y.MISS<-rbind(Y.MISS,Y.full[O==0])
}

#posterior mean
mean(THETA[,1]-THETA[,2])

#posterior confidence interval
quantile(THETA[,1]-THETA[,2],prob=c(0.025,0.975))

#Problem 3
#a

#load data
azdiabetes<-read.table("azdiabetes.dat",header=T)
attach(azdiabetes)

#separate into two groups
azdiabetes.n<-azdiabetes[diabetes=="No",1:7]
azdiabetes.d<-azdiabetes[diabetes=="Yes",1:7]

#for diabetics
#prior parameters
n.d<-nrow(azdiabetes.d)
mu0.d<-ybar.d<-apply(azdiabetes.d,2,mean)
L0.d<-S0.d<-cov(azdiabetes.d)
nu0.d<-9

#starting value
Sigma.d<-L0.d
THETA.d<-SIGMA.d<-NULL

#Gibbs Sampler
set.seed(10)
for(s in 1:10000)
{
  #update theta
  Ln.d<-solve(solve(L0.d)+n.d*solve(Sigma.d))
  mun.d<-Ln.d%*%(solve(L0.d)%*%mu0.d+n.d*solve(Sigma.d)%*%ybar.d)
  theta.d<-rmvnorm(1,mun.d,Ln.d)
  
  #update Sigma
  Sn.d<-S0.d+(t(azdiabetes.d)-c(theta.d))%*%t(t(azdiabetes.d)-c(theta.d))
  Sigma.d<-solve(rwish(1,nu0.d+n.d,solve(Sn.d)))
  
  #save results
  THETA.d<-rbind(THETA.d,theta.d); SIGMA.d<-rbind(SIGMA.d,c(Sigma.d))
}

#for non-diabetics
#prior parameters
n.n<-nrow(azdiabetes.n)
mu0.n<-ybar.n<-apply(azdiabetes.n,2,mean)
L0.n<-S0.n<-cov(azdiabetes.n)
nu0.n<-9

#starting value
Sigma.n<-L0.n
THETA.n<-SIGMA.n<-NULL

#Gibbs Sampler
set.seed(10)
for(s in 1:10000)
{
  #update theta
  Ln.n<-solve(solve(L0.n)+n.n*solve(Sigma.n))
  mun.n<-Ln.n%*%(solve(L0.n)%*%mu0.n+n.n*solve(Sigma.n)%*%ybar.n)
  theta.n<-rmvnorm(1,mun.n,Ln.n)
  
  #update Sigma
  Sn.n<-S0.n+(t(azdiabetes.n)-c(theta.n))%*%t(t(azdiabetes.n)-c(theta.n))
  Sigma.n<-solve(rwish(1,nu0.n+n.n,solve(Sn.n)))
  
  #save results
  THETA.n<-rbind(THETA.n,theta.n); SIGMA.n<-rbind(SIGMA.n,c(Sigma.n))
}

#compare posterior marginal distribution
c.interval<-list()
for(i in 1:7)
{
  c.interval[[i]]<-rbind(quantile(THETA.n[,i],prob=c(.025,.5,.975)),quantile(THETA.d[,i],prob=c(.025,.5,.975)))
}
c.interval

#approximation
theta.greater<-function(i){mean(sample(THETA.d[,i],10000,replace = T)>sample(THETA.n[,i],10000,replace = T))}
p.greater<-NULL
for(i in 1:7)
{
  p.greater<-c(p.greater,theta.greater(i))
}
p.greater

#b

#Posterior mean of Sigma
round(matrix(apply(SIGMA.d,2,mean),ncol=7,byrow=T),4)
round(matrix(apply(SIGMA.n,2,mean),ncol=7,byrow=T),4)

#Plot of posterior samples of Sigma
par(mar=c(1,1,.5,.5)*1.75,mfrow=c(7,7),mgp=c(1.75,.75,0))
for(i in 1:49){plot(SIGMA.d[,i],SIGMA.n[,i])}

#Problem 4
#c

divorce<-read.table("divorce.dat")
x<-divorce[,1]
y<-divorce[,2]
n<-nrow(divorce)
tauB2<-tauC2<-16

#Initial values
beta<-0
c<-0
z<-NULL
for(i in 1:n){
  mu<-beta*x[i]
  if(y[i]==1) {u<-runif(1,pnorm(c-mu),1)}else{u<-runif(1,0,pnorm(c-mu))}
  z<-c(z,mu+qnorm(u))
}
C<-Z<-BETA<-NULL

#
beta.var<-1/(sum(x^2)+1/tauB2)
for(i in 1:10000){
  
  #update beta
  beta<-rnorm(1,sum(divorce[,1]*z)*beta.var,sqrt(beta.var))
  
  #update c
  z.a<-max(z[y==0])
  z.b<-min(z[y==1])
  u<-runif(1,pnorm(z.a/sqrt(tauC2)),pnorm(z.b/sqrt(tauC2)))
  c<-sqrt(tauC2)*qnorm(u)
  
  #update z
  z<-NULL
  for(i in 1:n){
    mu<-beta*x[i]
    if(y[i]==1) {u<-runif(1,pnorm(c-mu),1)}else{u<-runif(1,0,pnorm(c-mu))}
    z<-c(z,mu+qnorm(u))
  }
  
  #save result
  BETA<-c(BETA,beta)
  C<-c(C,c)
  Z<-rbind(Z,z)
}
library(coda)
effectiveSize(BETA)
effectiveSize(C)
effectiveSize(Z)
acf(C)
acf(BETA)
par(mar=c(1,1,.5,.5)*1.75,mfrow=c(5,5),mgp=c(1.75,.75,0))
for(i in 1:25){acf(Z[,i])}

#d

quantile(BETA,probs = c(0.025,0.975))#95% confidence interval for beta

length((BETA>0)==TRUE)/10000
