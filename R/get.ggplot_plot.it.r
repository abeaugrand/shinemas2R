#' Function used in get.ggplot
#' @description
#' get ggplots: barplot, boxplots, interaction plots, radar, biplot
#' 
get.ggplot_plot.it = function(
	d, 
	titre = NULL, 
	ggplot.display, 
	x.axis, 
	in.col, 
	ggplot.type, 
	vec_variables, 
	equal.ylim = TRUE, 
	nb_parameters_per_plot_x.axis = NULL, 
	nb_parameters_per_plot_in.col = NULL,
	labels.on = NULL,
	hide.labels.parts = NULL,
	labels.size = 1
	) 
	# Lets'go ----------
	{

	# Reshape data in a list based on nb_parameters_per_plot arguments ----------
		reshape.data = function(d, x.axis, nb_parameters_per_plot_x.axis, in.col, nb_parameters_per_plot_in.col, vec_variables, labels.on = NULL, hide.labels.parts = NULL, labels.size = 1){
			
			if( !is.null(x.axis) ) { colnames(d)[which(colnames(d) == x.axis)] = "x.axis" }
			if( !is.null(in.col) ) { colnames(d)[which(colnames(d) == in.col)] = "in.col" }
			
			if( !is.null(labels.on) ){ 
				if(labels.on == "son") { d$labels = get.ggplot_hide.labels.part(d$son, hide.labels.parts) }
				if(labels.on == "father") { d$labels = get.ggplot_hide.labels.part(d$father, hide.labels.parts) }
			} else { d$labels = rep(NA, nrow(d))}
			
			if( !is.null(x.axis) & !is.null(in.col) ) { d_head = d[,c("labels", "x.axis", "in.col")];  }
			if( !is.null(x.axis) & is.null(in.col) ) { d_head = d[,c("labels", "x.axis")] }
			if( is.null(x.axis) & !is.null(in.col) ) { d_head = d[,c("labels", "in.col")] }
			
			d_var = as.data.frame(as.matrix(d[,vec_variables], ncol = length(vec_variables))) # If only one variable
			colnames(d_var) = vec_variables
			
			# get rid off rows with only NA
			tokeep = apply(d_var, 1, function(x){length(which(is.na(x))) != length(x)})
			
			t = length(which(!tokeep))
			if( t > 0 ) { warning(t, " rows have been deleted for variables ", paste(vec_variables, collapse = ", "), " because of only NA on the row for these variables.") }
			
			d_var = d_var[tokeep,]
			
			
			d_var = as.data.frame(as.matrix(d_var, ncol = length(vec_variables))) # If only one variable
			colnames(d_var) = vec_variables
			
			d_head = d_head[tokeep,]

			d = droplevels(cbind.data.frame(d_head, d_var))
			
			# split for x.axis
			if(!is.null(x.axis) & !is.null(nb_parameters_per_plot_x.axis)){
				ns = unique(d$x.axis)
				s = rep(c(1:length(ns)), each = nb_parameters_per_plot_x.axis)[1:length(ns)]
				names(s) = ns
				d$split_x.axis = s[d$x.axis]
			} else { d$split_x.axis = rep(1, nrow(d)) }
			
			# split for in.col
			if( !is.null(in.col) & !is.null(nb_parameters_per_plot_in.col) ) {
				ns = unique(d$in.col)
				s = rep(c(1:length(ns)), each = nb_parameters_per_plot_in.col)[1:length(ns)]
				names(s) = ns
				d$split_in.col = s[d$in.col]
			} else { d$split_in.col = rep(1, nrow(d)) }
			
			# rename back data
			if( !is.null(x.axis) ) { colnames(d)[which(colnames(d) == "x.axis")] = x.axis }
			if( !is.null(in.col) ) { colnames(d)[which(colnames(d) == "in.col")] = in.col }
			
			# Overall split
			d$split = paste(paste("x.axis", d$split_x.axis, sep = "-"), paste("in.col", d$split_in.col, sep = "-"), sep = "|")
			d = select(d, - split_x.axis, - split_in.col)
			d =  plyr:::splitter_d(d, .(split))
			
			return(d)
		}		
		
		
# Get ggplot on reshaped data ----------

	if( is.element(ggplot.display, c("boxplot", "barplot", "interaction")) ) {
				
		fun_p = function(variable, d, x.axis, nb_parameters_per_plot_x.axis, in.col, nb_parameters_per_plot_in.col, equal.ylim){ 
			
			d = reshape.data(d, x.axis = x.axis, nb_parameters_per_plot_x.axis = nb_parameters_per_plot_x.axis, in.col = in.col, nb_parameters_per_plot_in.col = nb_parameters_per_plot_in.col, vec_variables = variable)
			
			if(equal.ylim){ # Set ylim for all ggplots
				tmp = NULL
				for(i in 1:length(d)) { tmp = rbind.data.frame(tmp, d[[i]][,c(x.axis, variable)]) }
				
				if(is.numeric(tmp$variable[1])) { 
					if( length(grep("network", ggplot.type)) > 0 ) { ymin = 0; ymax = max(tapply(tmp[,variable], tmp[,x.axis], sum, na.rm = TRUE))
					}
					if( length(grep("data", ggplot.type)) > 0 ) { ymin = min(tmp[,variable], na.rm = TRUE); ymax = max(tmp[,variable], na.rm = TRUE) }	
				} else { ymin = ymax = NULL}
			}
			
			fun = function(d, variable, x.axis, in.col, ggplot.display, ggplot.type){
				
				if( !is.null(x.axis) ) { colnames(d)[which(colnames(d) == x.axis)] = "x.axis" }
				if( !is.null(in.col) ) { colnames(d)[which(colnames(d) == in.col)] = "in.col" }
				colnames(d)[which(colnames(d) == variable)] = "variable"
				
				if(ggplot.display == "boxplot") {
					p = ggplot(d, aes( x = x.axis, y = variable))
					if( is.null(in.col) ) { p = p + geom_boxplot(position="dodge") } else { p = p + geom_boxplot(aes(fill = in.col)) }
				}
				
				if(ggplot.display == "barplot") {		
					d$toto = paste(d$in.col, d$x.axis, sep = "azerty")
					
					if( length(grep("network", ggplot.type)) > 0 ) { 
						mm = ddply(d, "toto", summarise, mean = sum(variable, na.rm = TRUE))
						mm2 = ddply(d, "x.axis", summarise, mean = mean(variable, na.rm = TRUE))
					}
					
					if( length(grep("data", ggplot.type)) > 0 ) { 
						mm = ddply(d, "toto", summarise, mean = mean(variable, na.rm = TRUE), sd = sd(variable, na.rm = TRUE)) 
						mm2 = ddply(d, "x.axis", summarise, mean = mean(variable, na.rm = TRUE), sd = sd(variable, na.rm = TRUE))
					}
					
					mm$in.col = sapply(mm$toto, function(x){unlist(strsplit(x, "azerty"))[1]})
					mm$x.axis = sapply(mm$toto, function(x){unlist(strsplit(x, "azerty"))[2]})
					mm$x.axis = factor(mm$x.axis, levels = levels(d$x.axis))
					
					
					if(is.null(in.col)) {	
						p = ggplot(mm2, aes(x = x.axis, y = mean)) + geom_bar(stat = "identity") 
						if( length(grep("data", ggplot.type)) > 0 ) { 
							limits <- aes(ymax = mean + sd, ymin = mean - sd)
							p = p + geom_errorbar(limits, position = position_dodge(width=0.9), width=0.25)
						}
					} else {
						p = ggplot(mm, aes(x = x.axis, y = mean))
						
						if( length(grep("network", ggplot.type)) > 0 ) { p = p + geom_bar(aes(fill = in.col), stat = "identity") }
						if( length(grep("data", ggplot.type)) > 0 ) { 
							p = p + geom_bar(aes(fill = in.col), position = "dodge", stat = "identity") 
							limits <- aes(ymax = mean + sd, ymin = mean - sd, fill = factor(in.col))
							p = p + geom_errorbar(limits, position = position_dodge(width=0.9), width=0.25)
						}
					}
				}
				
				if(ggplot.display == "interaction") {										
					p = ggplot(d, aes(y = variable, x = factor(x.axis), colour = factor(in.col), group = factor(in.col)))
					p = p + stat_summary(fun.y = mean, geom = "point") + stat_summary(fun.y = mean, geom = "line")
				}
				
				attributes(p)$x.axis = x.axis; attributes(p)$in.col = in.col
				
				p = p + xlab("") + ylab(variable) + theme(axis.text.x = element_text(angle = 90, hjust = 1), legend.title = element_blank())	
				if(!is.null(ymin) & !is.null(ymax)) { p = p + ylim(ymin, ymax) }
				if(!is.null(titre)) { p = p + ggtitle(titre) }
				return(p)
			}
			
			p.out = lapply(d, fun, variable, x.axis, in.col, ggplot.display, ggplot.type )
			return(p.out)
		}

		p = lapply(vec_variables, fun_p, d = d, x.axis = x.axis, nb_parameters_per_plot_x.axis = nb_parameters_per_plot_x.axis, in.col = in.col, nb_parameters_per_plot_in.col = nb_parameters_per_plot_in.col, equal.ylim = equal.ylim)
		names(p) = vec_variables
	}
	
	
	if(ggplot.display == "radar") {

			d = reshape.data(d, x.axis = NULL, nb_parameters_per_plot_x.axis = NULL, in.col = in.col, nb_parameters_per_plot_in.col = nb_parameters_per_plot_in.col, vec_variables = vec_variables)
		
		fun = function(d, vec_variables, in.col){
			colnames(d)[which(colnames(d) == in.col)] = "in.col"
			
			d = droplevels(d[,c(vec_variables, "in.col")])
			tokeep = apply(d[,vec_variables], 1, function(x){ !is.na(sum(x)) })
			t = length(which(tokeep))
			if( t > 0 ) { warning(t, " rows have been deleted for variables ", paste(vec_variables, collapse = ", "), " because of at least one NA on the row for these variables.") }
			d = droplevels(d[tokeep,])
			
			m = NULL
			for(variable in vec_variables){
				value = tapply(d[,variable], d$in.col, mean)
				if( length(value) > 1 ) { # rescale all variables to lie between 0 and 1
					value1 = (value - min(value, na.rm = TRUE)) / (max(value, na.rm = TRUE) - min(value, na.rm = TRUE))
				} else { value1 = 1 }
				in.col = names(value)
				vn = cbind.data.frame(rep(variable, length(value)), value, value1, in.col)
				m = rbind.data.frame(m, vn)
			}
			colnames(m) = c("variable", "value", "value1", "in.col")
			m$in.col = factor(m$in.col)
			
			# Define a new coordinate system 
			coord_radar <- function(...) { 
				structure(coord_polar(...), class = c("radar", "polar", "coord")) 
			} 
			is.linear.radar <- function(coord) TRUE

			attributes(p)$x.axis = NULL; attributes(p)$in.col = in.col
			
			p = ggplot(m, aes(x = variable, y = value1, color = in.col)) + geom_path(aes(group = in.col)) + coord_radar()
			p = p  + xlab("measure") + ylab("relative value") + theme(legend.title = element_blank()) 

			return(p)
		}

		p = lapply(d, fun, vec_variables = vec_variables, in.col = in.col)
	}

	if(ggplot.display == "biplot") {
		
		d = reshape.data(d, x.axis = NULL, nb_parameters_per_plot_x.axis = NULL, in.col = in.col, nb_parameters_per_plot_in.col = nb_parameters_per_plot_in.col, vec_variables = vec_variables, labels.on = labels.on, hide.labels.parts = hide.labels.parts, labels.size = labels.size)

		fun = function(pair_var, d, in.col){
			funb = function(d, pair_var, in.col){
				colnames(d)[which(colnames(d) == in.col)] = "in.col"
				var = unlist(strsplit(pair_var, " -azerty- "))
				var1 = var[1]; colnames(d)[which(colnames(d) == var1)] = "var1"
				var2 = var[2]; colnames(d)[which(colnames(d) == var2)] = "var2"
				p = ggplot(d, aes(x = var1, y = var2, label = labels)) 
				p = p + stat_smooth(method = "lm", se = FALSE)
				p = p + geom_text(aes(colour = factor(in.col)), size = labels.size)
				p = p  + xlab(var1) + ylab(var2) + ggtitle(titre) + theme(axis.text.x = element_text(angle=90, hjust=1), legend.title = element_blank()) 
				attributes(p)$x.axis = NULL; attributes(p)$in.col = in.col
				return(p)
			}
			p = lapply(d, funb, pair_var, in.col)
			return(p)
		}
		
		pair_var = apply(combn(vec_variables, 2), 2, function(x){paste(x, collapse = " -azerty- ")})
		p = lapply(pair_var, fun, d, in.col)
		names(p) = sub(" -azerty- ", " - ", pair_var)
	}
		
	return(p)
}

