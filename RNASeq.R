#!/usr/bin/R

#need general.R

filterMostExprimedGenesBySample <-function(data, numberOfGenes=nrow(data),minFreqOfGene=1,maxFreqOfGene=ncol(data),threshold=min(data)){
	#Fonction de filtrage des counts, on prend les x g�nes les plus exprim�s pour chache �chantillon puis on effectue une jointure compl�te
	#puis on filtre selon la fr�quence du g�ne
	#data: dataframe des counts
	#numberOfGenes: cutoff sur les rank d'expression des g�nes, plus il est �lev� moins le filtre est stringeant
	#minFreqOfGene : nombre de fois minimum o� le g�ne revient dans la liste des x g�nes les plus exprim�s (o� le g�ne > threshold)
    #maxFreqOfGene : nombre de fois maximale o� le g�ne est exprim�
	#threshold: l'expression du g�ne doit �tre plus grande que ce param�tre pour que la fr�quence soit compt�e comme 1
	mostExprimedGenes<-list()
	for(i in 1:ncol(data)){
		col<- data[,i]
		names(col)<-rownames(data)
		col<-col[which(col>threshold)];
		mostExprimedGenes[[i]]<-names(sort(col,decreasing = T))[1:min(numberOfGenes,length(col))]
	}
	rm(col)

	freqTable<-summary(as.factor(unlist(mostExprimedGenes)),maxsum=nrow(data))
	mostExprimedgenesVector<-names(freqTable[which(freqTable>=minFreqOfGene & freqTable<=maxFreqOfGene)])
	return(data[mostExprimedgenesVector,])
}

vectSup0<-function(x){
	a<-x[which(x>0)]
	return(length(a))
}

nbGeneSup0<-function(data){
	nS<-ncol(data)
	i<-apply(data,1,vectSup0)
	return(length(i[which(i>0)]))
}

filterMostExprimedGenesBySampleThres <-function(data, numberOfGenes=3000,maxGenes=nrow(data)/2){
	#Fonction de filtrage des counts, on prend les x g�nes les plus exprim�s pour chache �chantillon puis on effectue une jointure compl�te
	#puis on filtre selon la fr�quence du g�ne
	#data: dataframe des counts
	#numberOfGenes: cutoff des g�nes, plus il est �lev� moins le filtre est stringeant
	#maxGenes : nombre maximal de g�ne que l'on veut en sortie
	mostExprimedGenes<-data.frame(matrix(ncol = ncol(data), nrow=numberOfGenes)) #cr�ation d'un dataframe vide
	for(i in 1:ncol(data)){
	col<- data[,i]
	names(col)<-rownames(data)
	mostExprimedGenes[,i]<-names(sort(col,decreasing = T,method="shell"))[1:numberOfGenes]
	}
	rm(col)
	colnames(mostExprimedGenes)<-colnames(data)
	freqTable<-sort(summary(as.factor(unlist(mostExprimedGenes)),maxsum=nrow(data)),decreasing=TRUE,method="shell")
	maxGenes<-min(maxGenes,length(freqTable))
	mostExprimedgenesVector<-names(freqTable[1:maxGenes])
	return(data[mostExprimedgenesVector,])
}

interceptDistThres<-function(data,threshold=nrow(data)/3){
	print("construction of database");
	nrows<-nrow(data);
	ncols<-ncol(data);
	listOfgenesBySample=matrix("",threshold,ncols);
	for(i in 1:ncols){
		col<-data[,i];
		names(col)<-1:nrows;
		#tri alp ?
		listOfgenesBySample[,i]<-names(sort(col,decreasing = T,method="shell"))[1:threshold];
	}
	print("construction of dist matrix");
	distMat<-matrix(0,ncols,ncols)
	rownames(distMat)<-colnames(data);
	colnames(distMat)<-rownames(distMat);
	c<-1;
	for(i in 2:ncols){
		for(j in 1:c){
			distMat[i,j]<-length(setdiff(listOfgenesBySample[,i],listOfgenesBySample[,j]));
		}
		c<-c+1;
	}
	distMat<-as.dist(distMat);
	return(distMat);
}

interceptDistanceLevenstein<-function(data){
	print("construction of database");
	nrows<-nrow(data);
	ncols<-ncol(data);
	listOfgenesBySample=matrix("",nrows,ncols);
	for(i in 1:ncols){
		col<-data[,i];
		names(col)<-1:nrows;
		listOfgenesBySample[,i]<-names(sort(col,decreasing = T,method="shell"));
	}
	print("construction of dist matrix");
	distMat<-matrix(0,ncols,ncols)
	rownames(distMat)<-colnames(data);
	colnames(distMat)<-rownames(distMat);
	c<-1;
	for(i in 2:ncols){
		for(j in 1:c){
			distMat[i,j]<-LevenshteinDist(listOfgenesBySample[,i],listOfgenesBySample[,j]);
		}
		c<-c+1;
	}
	distMat<-as.dist(distMat);
	return(distMat);
}

compareVectReplace<-function(data,verbose=FALSE){
	#return a dist matrix
	#@param data : dataframe or matrx (rows = genes, cols = samples)
	# tri alph
	print("construction of database");
	nrows<-nrow(data);
	ncols<-ncol(data);
	listOfgenesBySample=matrix(0,nrows,ncols);
	for(i in 1:ncols){
		col<-data[,i];
		names(col)<-1:nrows;
		listOfgenesBySample[,i]<-as.integer(names(sort(col,decreasing = T,method="shell")));
	}
	print("construction of dist matrix");
	distMat<-matrix(0,ncols,ncols)
	rownames(distMat)<-colnames(data);
	colnames(distMat)<-rownames(distMat);
	tot<-length(as.dist(distMat))
	c<-1;
	out<-0;
	comptT<-0
	for(i in 2:ncols){
		for(j in 1:c){
			distMat[i,j]<-.Call("orderDist",as.integer(listOfgenesBySample[,i]),as.integer(listOfgenesBySample[,j]))
			comptT<-comptT+1;
		}
		if(verbose) print(paste0(comptT,"/",tot));
		c<-c+1;
	}
	distMat<-as.dist(distMat);
	return(distMat);
}

genesRankVSExpr<-function(data, numberOfGenes=nrow(data)){
	#Stats par g�nes
	nsamples<-ncol(data)
	mostExprimedGenes<-data.frame(matrix(ncol = nsamples, nrow=numberOfGenes));
	for(i in 1:nsamples){
		col<- data[,i];
		names(col)<-rownames(data);
		mostExprimedGenes[,i]<-names(sort(col,decreasing = T))[1:numberOfGenes];
	}
	colnames(mostExprimedGenes)<-colnames(data);
	ranks<-data.frame(matrix(ncol = nsamples, nrow=numberOfGenes));
	rownames(ranks)<-mostExprimedGenes[,1]
	colnames(ranks)<-colnames(data);
	for(i in 1:nsamples){
		col<-1:numberOfGenes;
		names(col)<-mostExprimedGenes[,i];
		ranks[,i]<-col[rownames(ranks)]
	}
	meanRank<-apply(ranks,1,mean)
	sdRank<-apply(ranks,1,sd)
	minRank<-apply(ranks,1,min)
	maxRank<-apply(ranks,1,max)
	data<-data[names(meanRank),]
	sdExpr<-apply(data,1,mean)
	minExpr<-apply(data,1,sd)
	maxExpr<-apply(data,1,max)
	meanExpr<-apply(data,1,min)
	res<-data.frame(meanRank = meanRank,SDRank=sdRank, minRank=minRank, maxRank=maxRank, 
		meanExpr = meanExpr,sdExpr=sdExpr,maxExpr=maxExpr,minExpr=minExpr) ;
	res<-res[order(res$meanRank),]
	return(res);
}

examineRNAseqSamples<-function(x, uncenter= FALSE){
	#Donne diff�rentes stat par �chantillon 
	if(uncenter){
		x<-x-min(x)
		zero<-0
	}else{
		zero<-min(x)
	}
	mean<-apply(x,2,mean)
	sd<-apply(x,2,sd)
	count<-colSums(x)
	CV<-apply(x,2,cv)
	noGenEx<-rep(0,ncol(x))
	for(i in 1:ncol(x)) noGenEx[i]<-length(which(x[,i]>zero))

	return(data.frame(mean=mean, sd=sd, count=count,CV=CV,noGenEx=noGenEx))
}

retrieveSexHumanEmbryoKmeans<-function(d,patternLen=3){
	#return a matrix of count of "male" and "female" predicted cells in each embryo (Kmeans method)
	maleGene<-c("DDX3Y","EIF1AY","TTTY15","RPS4Y1")
	k<-kmeans(t(d[maleGene,]),2)
	mORf<-rowSums(k$centers)
	if(mORf[1]<mORf[2]){
		mf<-c("F","M")
	}else{
		mf<-c("M","F")
	}
	count<-as.factor(mf[k$cluster])
	names(count)<-substr(colnames(d),1,patternLen)
	embryos<-as.factor(unique(substr(colnames(d),1,patternLen)))
	res<-list()
	res$count<-data.frame(matrix(ncol=2,nrow=length(embryos)))
	colnames(res$count)<-c("Male","Female")
	rownames(res$count)<-embryos
	
	for(embryo in embryos){
		res$count[embryo,1]<-length(which(count[which(names(count)==embryo)]=="M"))
		res$count[embryo,2]<-length(which(count[which(names(count)==embryo)]=="F"))
	}
	res$freq<-res$count/rowSums(res$count)
	return(res)
}

retrieveSexHumanEmbryoACP<-function(d,patternLen=3){
	#return a freq matrix of "male" and "female" predicted cells in each embryo (ACP method)
	maleGene<-c("DDX3Y","EIF1AY","TTTY15","RPS4Y1")
	z<-colSums(d[maleGene,])
	#voir ici pour renvoyer tout m�le ou tout femelle
	#normer acp sans r�duire ? et prendre seuil
	
	a<-ACP(t(d[maleGene,]))
	M<-as.factor(substr(names(a$x[which(a$x[,1]>0),1]),1,patternLen)) #s�lection du nom de l'embryon seul, pas des cellules (substr)
	F<-as.factor(substr(names(a$x[which(a$x[,1]<0),1]),1,patternLen))
	embryos<-as.factor(unique(substr(colnames(d),1,patternLen)))
	res<-list()
	res$count<-data.frame(matrix(ncol=2,nrow=length(embryos)))
	colnames(res$count)<-c("Male","Female")
	rownames(res$count)<-embryos
	
	for(embryo in embryos){
		res$count[embryo,1]<-length(which(M==embryo))
		res$count[embryo,2]<-length(which(F==embryo))
	}
	res$freq<-res$count/rowSums(res$count)
	return(res)
}

plotExpr<-function(expr,conditions=data.frame(samples=as.factor(colnames(expr)),row.names = colnames(expr)),
legendName="gene",errorBar="se", ciRate=0.95, type="points", negValue=FALSE,  scale="continuous",breaks = waiver() ){
  require(grid)
  require(ggplot2)
  #expr: dataframe (ex : gene in rows, sample in columns)
  #consitions: dataframe factor, with expr columns in row (usually samples), and differents annotations in columns
  #errorBar: what represent the bars around each point: se : standard error mean, ci: confidance interval (distribution must follow a normal law)
  #ciRate: confidance interval rate if errorBar = ci, 0.95 = CI 95%
  #needs general.R (for se and multiplot function)
  
  if(!errorBar%in%c("se","ci")) stop("errorBar must be 'ci' or 'se'")
  if(!type%in%c("points","hist")) stop("type must be 'points' or 'hist'")
  if(!scale%in%c("continuous","log")) stop("scale must be 'continuous' or 'log'")
  
  numPlots = ncol(conditions)
  cols<-floor(sqrt(numPlots))
  layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                   ncol = cols, nrow = ceiling(numPlots/cols))
  grid.newpage()
  pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))
  
  ciFactor<-1
  if(errorBar=="ci"){
    ciFactor<-qnorm(ciRate+(1-ciRate)/2)
  }
  
  for(condIndex in 1:ncol(conditions)){
    conditionName<-colnames(conditions)[condIndex]
    cond<-unlist(conditions[,condIndex])
    names(cond)<-rownames(conditions)
    if(!is.factor(cond)) stop("You must give a factor dataframe/matrix") #Qualitatif
    tabGraph<-data.frame(matrix(nrow = length(levels(cond))*nrow(expr),ncol=5))
    colnames(tabGraph)<-c("cond","means","errBarMin","errBarMax",legendName)
    tabGraph$cond<-rep(levels(cond),nrow(expr))
    tabGraph[,legendName]<-rep(rownames(expr),each=length(levels(cond)))
	
    for(lvl in levels(cond)){
      for(exprIndex in 1:nrow(expr)){
        values<-unlist(expr[exprIndex,which(colnames(expr)%in%names(cond[which(cond==lvl)]))])
        nameExpr<-rownames(expr)[exprIndex]
        tabGraph[which(tabGraph$cond==lvl & tabGraph[,legendName] == nameExpr),"means"]<-mean(values)
        tabGraph[which(tabGraph$cond==lvl & tabGraph[,legendName] == nameExpr),"errBarMin"]<-  se(values)*ciFactor
		tabGraph[which(tabGraph$cond==lvl & tabGraph[,legendName] == nameExpr),"errBarMax"]<-  se(values)*ciFactor
      }
    }
	
	tabGraph$cond<-factor(tabGraph$cond,levels=levels(cond))
	tabGraph[,legendName]<-factor(tabGraph[,legendName],levels=rownames(expr))
	
	if(!negValue){
		tabGraph$errBarMin[which(tabGraph$means-tabGraph$errBarMin<0)]<-tabGraph$means[which(tabGraph$means-tabGraph$errBarMin<0)]
	}
	
	if(type=="points"){
		graph<-ggplot(tabGraph, aes(x=cond, y=means, group=tabGraph[,legendName], colour= tabGraph[,legendName])) +
			geom_line() +
			geom_errorbar(width=.1, aes(ymin=means-errBarMin, ymax=means+errBarMax)) +
			geom_point(size=3)+
			xlab(colnames(conditions)[condIndex])+
			scale_colour_hue(name=legendName)
	}
	if(type=="hist"){
		graph<-ggplot(tabGraph, aes(x=tabGraph[,legendName], y=means, group=cond, fill= cond)) +
			geom_bar(stat = "identity",position = "dodge") +
			geom_errorbar(width=.1, aes(ymin=means-errBarMin, ymax=means+errBarMax), position=position_dodge(.9)) +
			xlab(colnames(conditions)[condIndex])+
			scale_colour_hue(name=legendName)
	}
    
    if(scale=="log"){
		graph<-graph+scale_y_log10(breaks=breaks)
	}else{
		graph<-graph+scale_y_continuous(breaks=breaks)
	}
    matchidx <- as.data.frame(which(layout == condIndex, arr.ind = TRUE))
    print(graph, vp = viewport(layout.pos.row = matchidx$row,
                                    layout.pos.col = matchidx$col))
    
  }
}

#Utile pour les packages qui demandes des fonctions comme argument
colMap <- function(x) {
  .col <- rep(rev(heat.colors(length(unique(x)))), time = table(x))
  return(.col[match(1:length(x), order(x))])
}
selectGene<- function(x){
  return(x==1)
}

###

UMI2UPM<-function(data){ #Normalisation UPM
	data.UPM <- sweep(data, 2, colSums(data),`/`)
	data.UPM <-data.UPM * 1000000
	return(data.UPM)
}
