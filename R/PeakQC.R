PeakQC <-R6Class(
    classname = "PeakQC",
    inherit = BaseProc,
    public = list(
        initialize = function(atacProc, reportOutput=NULL,qcbedInput = c("DHS","blacklist","path/to/bed"),bedInput = NULL,editable=FALSE){
            super$initialize("PeakQC",editable,list(arg1=atacProc))
            if(!is.null(atacProc)){
                private$paramlist[["bedInput"]] <- atacProc$getParam("bedOutput");
                regexProcName<-sprintf("(BED|bed|Bed|%s)",atacProc$getProcName())
            }else{
                regexProcName<-"(BED|bed|Bed)"
            }
            qcbedInput <- qcbedInput[1]
            if(qcbedInput == "DHS"){
                private$paramlist[["qcbedInput"]]<-.obtainConfigure("DHS");
            }else if(qcbedInput == "blacklist"){
                private$paramlist[["qcbedInput"]]<-.obtainConfigure("blacklist");
            }else{
                private$paramlist[["qcbedInput"]]<-qcbedInput;
            }

            if(!is.null(bedInput)){
                private$paramlist[["bedInput"]] <- bedInput;
            }

            if(is.null(reportOutput)){
                if(!is.null(private$paramlist[["bedInput"]])){
                    prefix<-private$getBasenamePrefix(private$paramlist[["bedInput"]],regexProcName)
                    private$paramlist[["reportOutput"]] <- file.path(.obtainConfigure("tmpdir"),paste0(prefix,".",self$getProcName(),".report.txt"))
                }
            }else{
                private$paramlist[["reportOutput"]] <- reportOutput;
            }
            private$paramValidation()
        }
    ),
    private = list(
        processing = function(){
            genome <- Seqinfo(genome = .obtainConfigure("genome"))

            inputbed <- import(private$paramlist[["bedInput"]], genome = genome)


            qcbedInput<-import(private$paramlist[["qcbedInput"]], genome = genome)



            qcval=list();

            qcval[["totalInput"]]<-length(inputbed)
            qcval[["qcbedInput"]]<-length(subsetByOverlaps(inputbed, qcbedInput,ignore.strand = TRUE))
            qcval[["qcbedRate"]]<-qcval[["qcbedInput"]]/qcval[["totalInput"]]

            qcval<-as.matrix(qcval)
            write.table(qcval,file = private$paramlist[["reportOutput"]],sep="\t",quote = FALSE,col.names = FALSE)

        },
        checkRequireParam = function(){
            if(is.null(private$paramlist[["bedInput"]])){
                stop("bedInput is required.")
            }
            if(is.null(private$paramlist[["qcbedInput"]])){
                stop("qcbedInput is required.")
            }

        },
        checkAllPath = function(){
            private$checkFileExist(private$paramlist[["bedInput"]]);
            private$checkFileExist(private$paramlist[["qcbedInput"]]);
            private$checkFileCreatable(private$paramlist[["reportOutput"]]);
        }
    )


)


atacPeakQC<-function(atacProc, reportOutput=NULL,qcbedInput = c("DHS","blacklist","path/to/bed"), bedInput = NULL){
    atacproc<-PeakQC$new(atacProc, reportOutput=reportOutput,qcbedInput = qcbedInput,bedInput = bedInput,editable=FALSE)
    atacproc$process()
    return(atacproc)
}