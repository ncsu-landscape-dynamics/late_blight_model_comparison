library(terra)
library(tigris)

# Formula from Meentemeyer et al. 2011
sodweather <- function(x){
  y = -0.066 + 0.056*x - 0.0036*(x - 15)^2 - 0.0003*(x - 15)^3
}

# Take some potential temps to calculate the weather coefficient
sodv2 <- lapply(seq(-2, 32, by=0.25), sodf)

sodvf2 <- data.frame(t = seq(-2,32,by=0.25), dv = unlist(sodv2))

# The coefficient has a hump at small, positive temps.
# Remove the hump and use a line.
xs <- c(0,0.25,0.5,0.75,1,1.25,1.5,1.75,2,2.25,2.5)
yx <- c(0.1365, 0.12749, 0.11969, 0.11307, 0.1076, 0.10326,0.1,0.0978, 0.0967, 0.0966,0.0974)
m1 <- lm(yx ~ xs)
summary(m1)

# Simplify the SOD data frame
sodvf2[sodvf2$t < 0, "dv"] <- 0 
sodvf2[4,] <- c(1, 1*0.04835)
sodvf2 <- sodvf2[sodvf2$dv > 0.0,]
sodvf2[9:19, "dv"] <- sodvf2[9:19, "t"] * 0.0155


thresh1 <- 0.25*max(sodvf2$dv)
thresh2 <- 0.5*max(sodvf2$dv)
thresh3 <- 0.75*max(sodvf2$dv)

dsv <- function(precip, tmean) {
  prec_val = ifel(precip >= 2, 1, 0)
  
  t_val = ifel(tmean > 13.75 & tmean < 24.75, 4, 
        ifel(tmean > 10.25 & tmean <= 13.75 | tmean >=24.75 & tmean < 26.5, 3,
             ifel(tmean <= 10.25 & tmean > 6.75 | tmean >= 26.5 & tmean < 28.0, 2,
                 ifel(tmean <= 6.75 | tmean >= 28.0 , 1, 0))))
  
  dsv_val = prec_val * t_val
  
  return(dsv_val)
}

# Geographical focus
co1 <- counties(state = c("CA","OR"))
co1 <- co1[co1$NAME %in% c("Coos","Curry","Douglas","Josephine"),]#,"Del Norte"),]

txl <- list.files("Q:/Shared drives/Data/Original/Daymet/tmax", full.names = T)
tnl <- list.files("Q:/Shared drives/Data/Original/Daymet/tmin", full.names = T)
prl <- list.files("Q:/Shared drives/Data/Original/Daymet/precip/", full.names = T)
txl <- txl[30:41]
tnl <- tnl[30:41]
prl <- prl[30:41]

# Set the focus to the right projection
r0 <- rast(txl[1])
co1 <- vect(co1)
co1 <- project(co1, y=crs(r0))

codsv <- list()

dsvf <- function(i){
  mx = rast(txl[i])
  mn = rast(tnl[i])
  pr = rast(prl[i])
  mx = crop(mx, co1, mask=T)
  mn = crop(mn, co1, mask=T)
  precip = crop(pr, co1, mask=T)
  
  tmean = (mx+mn)/2
  print(tmean)
  
  codsv = dsv(precip, tmean)
  return(codsv)
}


tdsv <- for(i in 1:length(txl)){
  dsvf(i)
}
