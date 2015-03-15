trim = function( x ) {
  gsub("(^[[:space:]]+|[[:space:]]+$)", "", x)
}

isi_cargar = function(x){    
  a = list.files(path=x,pattern="*.txt")  
  b=paste(x, a, sep="")  
  z = do.call("rbind", lapply(b, function(x) read.delim(x, row.names=NULL, stringsAsFactors=FALSE, quote = "", encoding="UTF-8")))
  names(z) = names(z)[-1]
  z = z[,-ncol(z)]
  z$IDU = seq_len(nrow(z))
  return(z)  
}

isi_separar = function(x,y){
  if (!require("plyr")) {
    install.packages("plyr")
    library(plyr)
  } 
  if (y=="C1"){    
    c1=subset(x, select = c(IDU,UT,C1,PY), C1 !='')
    ddply(c1,.(IDU,PY),function(y){
      z <- gsub(pattern ="\\[.+?\\]","", y$C1, perl=T)
      c1_dir = unlist(strsplit(as.character(z), split="; "))
      RS = data.frame(
        C1 = toupper(trim(c1_dir)),
        stringsAsFactors = FALSE
      )
      return(RS)
    })
  }
  else if(y=="AU"){
    ddply(x,.(IDU,PY),function(y){
      au_name = unlist(strsplit(as.character(y$AU), split="; "))
      au_fullname = unlist(strsplit(as.character(y$AF), split="; "))
      RS = data.frame(
        AU = toupper(au_name),
        AF = toupper(trim(au_fullname)),
        stringsAsFactors = FALSE
      )
      return(RS)
    })
  }
  else if(y=="WC"){
    ddply(x,.(IDU,PY),function(y){  
      wc_name = unlist(strsplit(as.character(y$WC), split="; "))
      RS = data.frame(
        WC = toupper(trim(wc_name)),
        stringsAsFactors = FALSE
      )
      return(RS)
    })
    
  }
  else if(y=="CR"){
    cr=subset(x, select = c(IDU,UT,CR,PY), CR !='')
    ddply(cr,.(IDU,PY),function(y){
      cr_name = unlist(strsplit(as.character(y$CR), split="; "))
      RS = data.frame(
        CR = toupper(trim(cr_name)),
        stringsAsFactors = FALSE
      )
      return(RS)
    })
  }
}

isi_exportar_sqlite = function(x,y){
  if (!require("DBI")) {
    install.packages("DBI")
    library(DBI)
  }
  if (!require("RSQLite")) {
    install.packages("RSQLite")
    library(RSQLite)
  }
  drv=dbDriver("SQLite")
  con=dbConnect(drv, dbname ="pgwos.db")
  if(y=="WoS"){
    dbWriteTable(con, "isi_t_pg", x)    
  }
  else if(y=="AU"){
    dbWriteTable(con, "isi_t_au", x)
  }
  else if(y=="C1"){
    dbWriteTable(con, "isi_t_c1", x)
  }
  else if(y=="WC"){
    dbWriteTable(con, "isi_t_wc", x)
  }
  else if(y=="CR"){
    dbWriteTable(con, "isi_t_cr", x)
  }
  dbDisconnect(con)
}

isi_unimetrics_wos = function(x,y,...){
  if (!require("ggplot2")) {
    install.packages("ggplot2")
    library(ggplot2)
  }
  #colores = matrix(hcl(0:5 * 60), 3, 2)
  if(y=="PY"){    
    qplot(factor(PY), data=x, geom="bar", fill=factor(PY))
  }
  else if(y=="DT"){
    #mosaicplot(table(x$PY,x$DT), las=1, col = colores, main = "Tip. Documental")
    qplot(factor(PY), data=x, geom="bar", fill=factor(DT))
  }
  else if(y=="LA"){
    #ggplot(datos, aes(PY))+ geom_bar() + facet_grid(LA ~ .)
    #mosaicplot(table(x$PY,x$LA), las=1, col = colores, main = "Idioma")
    qplot(factor(PY), data=x, geom="bar", fill=factor(LA))
  }
  else if(y=="ACUM"){
    q=as.data.frame(table(x$PY))
    q$'%'=round((q$Freq/sum(q$Freq))*100,3)
    q$Acum=cumsum(q$Freq)
    q$'%Acum'=cumsum(q$'%')
    q$Tasa=round(((q$Freq-q$Freq[1])/q$Freq[1])*100,3)
    return(q)
  }
}

h_index=function (x,y,z){
  if (!require("plyr")) {
    install.packages("plyr")
    library(plyr)
  }
  if (y=="ALL"){
    dat=subset(x, select = c(PY, TC))
    dat=arrange(dat,desc(TC))
    cites=(dat$TC)
    year=dat$PY  
    val=0   
    n=length(cites)  
    rank=c(1:n)  
    order=order(cites, decreasing=T)  
    year=year[order]  
    totcit=cites[order]  
    dif=(cites-rank)  
    for(i in 1:n){
      if (dif[i]>=0)
        val[i]=1
      else    
        val[i]=0
    }
    valor_h_index=sum(val)
    cat("====================================","\n")
    cat("\n","El indice h es: ",valor_h_index, "\n")
    cat("====================================","\n")
  }
  else if(y=="PY"){
    dat=subset(x, select = c(PY, TC), PY ==z)
    dat=arrange(dat,desc(TC))
    cites=(dat$TC)
    year=dat$PY  
    val=0   
    n=length(cites)  
    rank=c(1:n)  
    order=order(cites, decreasing=T)  
    year=year[order]  
    totcit=cites[order]  
    dif=(cites-rank)  
    for(i in 1:n){
      if (dif[i]>=0)
        val[i]=1
      else    
        val[i]=0
    }
    valor_h_index=sum(val)
    cat("====================================","\n")
    cat("\n","El indice h para el", z," es: ", valor_h_index, "\n")
    cat("====================================","\n")
  }
  else if(y=="WC"){
    dat=subset(x,grepl(z,x$WC,i))
    dat=subset(dat, select = c(PY, TC))
    dat=arrange(dat,desc(TC))
    cites=(dat$TC)
    year=dat$PY  
    val=0   
    n=length(cites)  
    rank=c(1:n)  
    order=order(cites, decreasing=T)  
    year=year[order]  
    totcit=cites[order]  
    dif=(cites-rank)  
    for(i in 1:n){
      if (dif[i]>=0)
        val[i]=1
      else    
        val[i]=0
    }
    valor_h_index=sum(val)
    cat("====================================","\n")
    cat("\n","El indice h es: ", valor_h_index, "\n")
    cat("====================================","\n")
  }
}
