FregLenDistr <-R6Class(
  classname = "FregLenDistr",
  inherit = BaseProc,
  public = list(
    initialize = function(atacProc,reportPrefix=NULL,bedInput=NULL,editable=FALSE){
      super$initialize("FregLenDistr",editable,list(arg1=atacProc))
      if(private$singleEnd){
          private$writeLog("This process is for pair-end sequencing data.",isWarnning=TRUE)
      }
      if(!is.null(atacProc)){
        private$paramlist[["bedInput"]] <- atacProc$getParam("bedOutput");
        regexProcName<-sprintf("(BED|bed|Bed|%s)",atacProc$getProcName())
      }else{
          regexProcName<-"(BED|bed|Bed)"
      }
      if(!is.null(bedInput)){
        private$paramlist[["bedInput"]] <- bedInput;
      }
      if(is.null(reportPrefix)){
          if(!is.null(private$paramlist[["bedInput"]])){
              prefix<-private$getBasenamePrefix(private$paramlist[["bedInput"]],regexProcName)
              private$paramlist[["reportPrefix"]] <- file.path(.obtainConfigure("tmpdir"),paste0(prefix,".",self$getProcName(),".report"))
          }
          #private$paramlist[["reportPrefix"]] <- paste(private$paramlist[["bedInput"]],".lenreport",sep="");
      }else{
        private$paramlist[["reportPrefix"]] <- reportPrefix;
      }

        private$paramValidation()
    }

  ),
  private = list(
      processing = function(){
          readslist<-read.table(file = private$paramlist[["bedInput"]],nrows = 1)
          bedcol=length(colnames(readslist))
          if(bedcol>3){
              readslist<-read.table(file = private$paramlist[["bedInput"]],colClasses=c("character","integer","integer",rep("NULL",bedcol-3)))
          }else{
              readslist<-read.table(file = private$paramlist[["bedInput"]])
          }



          readlens<-readslist$V3-readslist$V2

          #read length distribution
          allreadslen <-as.data.frame(readlens)
          colnames(allreadslen)<-"length"
          ggplot(allreadslen)+geom_histogram(bins = max(allreadslen),aes(x=length))
          ggsave(paste0(private$paramlist[["reportPrefix"]],".lendistr.pdf"))

          #readslen<-names(readscounts)
          #readslen<-cbind(readlen,readscounts)
          #ggplot(allreadslen)+geom_density(aes(x="length",fill="clarity"))

          #period distribution

          readscounts<-table(readlens)

          readscounts<-data.frame(readscounts)
          colnames(readscounts)<-c("length","counts")

          write.table(x=readscounts,file = paste0(private$paramlist[["reportPrefix"]],".lendistr.txt"),quote = FALSE,row.names = FALSE,sep="\t")

          readscounts$length=as.integer(as.character(readscounts$length))
          mg<-data.frame(length=1:max(readscounts$length))
          readscounts <- merge(readscounts,mg,by="length",all = TRUE)
          readscounts$counts[is.na(readscounts$counts)]<-0
          rs<-Mod(fft(readscounts$counts))/length(readscounts$counts)
          t<-length(readscounts$counts)/(1:(length(readscounts$counts)-1))
          rs<-rs[2:length(rs)]
          # t<-t[1:as.integer(length(t)/2)]
          #rs<-rs[1:as.integer(length(rs)/2)]
          tp<-rep(0,length(rs))
          tp[t>10&t<11]<-1
          tp[t>100&t<200]<-2
          rs1<-as.data.frame(cbind(t[t<20&t>2],rs[t<20&t>2],tp[t<20&t>2]))
          #rs_1<-as.data.frame(cbind(t[t<20&t>2&tp==0],rs[t<20&t>2&tp==0],tp[t<20&t>2&tp==0]))
          #rs_2<-as.data.frame(cbind(t[t<20&t>2&tp!=0],rs[t<20&t>2&tp!=0],tp[t<20&t>2&tp!=0]))
          #colnames(rs_1)<-c("perior","strength","check")
          #colnames(rs_2)<-c("perior","strength","check")
          colnames(rs1)<-c("perior","strength","check")
          # ggplot(rs1)+geom_line(aes(x=perior,y=strength))+geom_vline(xintercept = 10)+geom_vline(xintercept = 11)
          #ggplot(rs1,aes(x=perior,y=strength))+geom_area(aes(fill="valence",color=check))
          checkdna=1
          ggplot(rs1)+geom_ribbon(data=subset(rs1,perior<=min(rs1$perior[rs1$check==checkdna])),aes(x=perior,ymin=0,ymax=strength),fill="blue")+geom_ribbon(data=subset(rs1,perior>=max(rs1$perior[rs1$check==checkdna])),aes(x=perior,ymin=0,ymax=strength),fill="blue")+geom_ribbon(data=subset(rs1,check==checkdna),aes(x=perior,ymin=0,ymax=strength),fill="red")
          ggsave(paste0(private$paramlist[["reportPrefix"]],".dnagroove.pdf"))

          rs2<-as.data.frame(cbind(t[t<400&t>2],rs[t<400&t>2],tp[t<400&t>2]))
          #rs2<-as.data.frame(cbind(t[t<500&t>2&rs>10&rs<11],rs[t<500&t>2&rs>10&rs<11]))
          colnames(rs2)<-c("perior","strength","check")
          #ggplot(rs2,aes(x=perior,y=strength))+geom_area(aes(fill="valence"))
          #ggplot(rs2)+geom_line(aes(x=perior,y=strength))+geom_vline(xintercept = 150)+geom_vline(xintercept = 200)
          #ggplot(allreadslen)+geom_density(aes(x="strength",fill="clarity"))
          checkhistone=2
          ggplot(rs2)+geom_ribbon(data=subset(rs2,perior<=min(rs2$perior[rs2$check==checkhistone])),aes(x=perior,ymin=0,ymax=strength),fill="blue")+geom_ribbon(data=subset(rs2,perior>=max(rs2$perior[rs2$check==checkhistone])),aes(x=perior,ymin=0,ymax=strength),fill="blue")+geom_ribbon(data=subset(rs2,check==checkhistone),aes(x=perior,ymin=0,ymax=strength),fill="red")
          ggsave(paste0(private$paramlist[["reportPrefix"]],".histone.pdf"))

      },
    checkRequireParam = function(){
      if(is.null(private$paramlist[["bedInput"]])){
        stop("bedInput is required.")
      }


    },
    checkAllPath = function(){
        private$checkFileExist(private$paramlist[["bedInput"]])
        private$checkPathExist(private$paramlist[["reportPrefix"]])
    }
  )


)

atacFregLenDistr<-function(atacProc,reportPrefix=NULL,bedInput=NULL){
    atacproc<-FregLenDistr$new(atacProc,reportPrefix,bedInput)
    atacproc$process()
    return(atacproc)
}