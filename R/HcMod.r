# Function to Compute Hc based on pipe model
HcPipeMod <- function(initVar,pCROBAS){
  h <- initVar[3] - 1.3
  b <- pi * initVar[4]^2 / 40000
  p_ksi <- pCROBAS[38,initVar[1]]
  p_rhof <- pCROBAS[15,initVar[1]]
  p_z <- pCROBAS[11,initVar[1]]
  
  rc <- ((p_rhof * b)/(p_ksi * h^p_z))^(1/(p_z-1))
  Lc <- min(initVar[3],h * rc)
  Hc <- initVar[3]-Lc
return(Hc)  
}

###function to replace HC NAs in initial variable initVar
findHcNAs <- function(initVar,pHcMod,pCrobas,HcModV){
  if(is.vector(initVar)){
    if(is.na(initVar[6])){
      H=initVar[3]
      D=initVar[4]
      age=initVar[2]
      BA_sp=initVar[5]
      BA_tot=initVar[5]
      N_tot=initVar[5]/(pi*((initVar[4]/2/100)**2))
      D.aver=initVar[4]
      H.aver=initVar[3]
      
      inModHc <- c(pHcMod[,initVar[1]],H,D,age,BA_sp,BA_tot,N_tot,
                   D.aver,H.aver,initVar[1])
      if(HcModV==1){
        initVar[6] <- HcPipeMod(initVar,pCrobas)
      }else{
        initVar[6] <- model.Hc(inModHc)  
      }
      
    }
  } else if(any(is.na(initVar[6,]))){
    initVar[1,][which(initVar[1,]==0)] <- 1 ###deals with 0 species ID
    HcNAs <- which(is.na(initVar[6,]))
    H=initVar[3,HcNAs]
    D=initVar[4,HcNAs]
    age=initVar[2,HcNAs]
    BA_sp=initVar[5,HcNAs]
    BA_tot=sum(initVar[5,],na.rm = T)
    N_tot=sum(initVar[5,]/(pi*((initVar[4,]/2/100)**2)),na.rm = T)
    D.aver=sum(initVar[4,]*initVar[5,]/sum(initVar[5,],na.rm = T),na.rm = T)
    H.aver=sum(initVar[3,]*initVar[5,]/sum(initVar[5,],na.rm = T),na.rm = T)
    if(length(HcNAs)==1){
      if(HcModV==1){
        initVar[6,HcNAs] <- HcPipeMod(initVar[,HcNAs],pCrobas)
      }else{
        inModHc <- c(pHcMod[,initVar[1,HcNAs]],H,D,age,BA_sp,BA_tot,
                     N_tot,D.aver,H.aver,initVar[1,HcNAs])
        initVar[6,HcNAs] <- model.Hc(inModHc) 
      }
    }else{
      if(HcModV==1){
        initVar[6,HcNAs] <- apply(initVar[,HcNAs],2,HcPipeMod,pCrobas)
      }else{
        inModHc <- rbind(pHcMod[,initVar[1,HcNAs]],H,D,age,BA_sp,BA_tot,
                       N_tot,D.aver,H.aver,initVar[1,HcNAs])
        initVar[6,HcNAs] <- apply(inModHc,2,model.Hc) 
      }
    }
  }
  return(initVar)
}

model.Hc <- function(inputs){ 
  spID = inputs[16]
  Hc = HcModDef[[spID]](inputs)
  return(Hc)
}

HcModDef <- list()
###default HcModel for pisy and pipi
HcModDef[[1]] <- HcModDef[[5]]<- function(inputs){ 
  pValues=inputs[1:7]
  H=inputs[8]
  D=inputs[9]
  age=inputs[10]
  BA_sp=inputs[11]
  BA_tot=inputs[12]
  N_tot=inputs[13]
  D.aver=inputs[14]
  H.aver=inputs[15]
  BA.other <- BA_tot - BA_sp
  Hc_sim=H/(1+exp(pValues[1]+pValues[2]*D/H+pValues[3]*D+
                    pValues[4]*H+pValues[5]*D.aver/H.aver+pValues[6]*log(BA_sp+1)+
                    pValues[7]*log(BA.other+1)))
  
  return(pmin(Hc_sim,0.95*H,na.rm = T)) 
} 

###default HcModel for piab FI and DE
HcModDef[[2]]<- HcModDef[[10]] <- function(inputs){ 
  pValues=inputs[1:7]
  H=inputs[8]
  D=inputs[9]
  age=inputs[10]
  BA_sp=inputs[11]
  BA_tot=inputs[12]
  N_tot=inputs[13]
  D.aver=inputs[14]
  H.aver=inputs[15]
  BA.other <- BA_tot - BA_sp
  Hc_sim=H/(1+exp(pValues[1]+pValues[2]*D/H+pValues[3]*D+pValues[4]*H.aver+
                    pValues[5]*BA_sp/BA_tot+pValues[6]*log(BA_sp+1)))
  
  return(pmin(Hc_sim,0.95*H,na.rm = T)) 
} 

###default HcModel for beal
HcModDef[[3]] <- function(inputs){ 
  pValues=inputs[1:7]
  H=inputs[8]
  D=inputs[9]
  age=inputs[10]
  BA_sp=inputs[11]
  BA_tot=inputs[12]
  N_tot=inputs[13]
  D.aver=inputs[14]
  H.aver=inputs[15]
  BA.other <- BA_tot - BA_sp
  Hc_sim=H/(1+exp(pValues[1]+pValues[2]*N_tot/1000+pValues[3]*D/H+
                    pValues[4]*H.aver+pValues[5]*log(BA_sp+1)+pValues[6]*log(BA.other+1)))
  
  return(pmin(Hc_sim,0.95*H,na.rm = T)) 
} 

###default HCmodel for fasy
HcModDef[[4]] <-function(inputs){ 
  pValues=inputs[1:7]
  H=inputs[8]
  D=inputs[9]
  age=inputs[10]
  BA_sp=inputs[11]
  BA_tot=inputs[12]
  N_tot = inputs[13]
  Hc_sim <-  H/(1+exp(pValues[1]+pValues[2]*N_tot/1000+
                        pValues[3]*log(BA_tot)+pValues[4]*D/H+pValues[5]*log(H)))
  return(pmin(Hc_sim,0.95*H,na.rm = T)) 
} 

###default HCmodel for eugl and eugrur
HcModDef[[6]] <- HcModDef[[9]] <- HcModDef[[11]]<-function(inputs){ 
  pValues=inputs[1:7]
  H=inputs[8]
  D=inputs[9]
  age=inputs[10]
  BA_sp=inputs[11]
  BA_tot=inputs[12]
  N_tot = inputs[13]
  Hc_sim <- H*exp(pValues[1]+pValues[2]*N_tot/1000+
                    pValues[3]*log(BA_tot)+pValues[4]*D/H +pValues[5]*H)
  return(pmin(Hc_sim,0.95*H,na.rm = T)) 
} 

###default HCmodel for robs and popu
HcModDef[[7]] <- HcModDef[[8]] <-function(inputs){ 
  pValues=inputs[1:7]
  H=inputs[8]
  D=inputs[9]
  age=inputs[10]
  BA_sp=inputs[11]
  BA_tot=inputs[12]
  Hc_sim <- H/(1+exp(pValues[1]-pValues[2]*log(BA_tot)+pValues[3]*D/H))
  return(pmin(Hc_sim,0.95*H,na.rm = T)) 
} 
