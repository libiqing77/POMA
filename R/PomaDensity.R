
#' Distribution Plot
#'
#' @description PomaDensity() generates a density plot of not normalized and normalized MS data. This plot can help in the comparison between pre and post normalized data and in the "validation" of the normalization process.
#'
#' @param data A MSnSet object. First `pData` column must be the subject group/type.
#' @param group Groupping factor for the plot. Options are "samples" and "features". Option "samples" (default) will create a density plot for each group and option "features" will create a density plot of each variable.
#' @param feature_name A vector with the name/s of feature/s to plot. If it's NULL (default) a density plot of all variables will be created.
#'
#' @export
#'
#' @return A ggplot2 object.
#' @author Pol Castellano-Escuder
#'
#' @import ggplot2
#' @importFrom tibble rownames_to_column
#' @importFrom dplyr select group_by filter rename
#' @importFrom magrittr %>%
#' @importFrom reshape2 melt
#' @importFrom crayon red
#' @importFrom clisymbols symbol
#' @importFrom Biobase pData exprs featureNames
#' 
#' @examples 
#' data("st000284")
#' 
#' # samples
#' PomaDensity(st000284)
#' 
#' # features
#' PomaDensity(st000284, group = "features")
#' 
#' # concrete features
#' PomaDensity(st000284, group = "features", 
#'             feature_name = c("ornithine", "orotate"))
PomaDensity <- function(data,
                        group = "samples",
                        feature_name = NULL){

  if (missing(data)) {
    stop(crayon::red(clisymbols::symbol$cross, "data argument is empty!"))
  }
  if(!is(data[1], "MSnSet")){
    stop(paste0(crayon::red(clisymbols::symbol$cross, "data is not a MSnSet object."), 
                " \nSee POMA::PomaMSnSetClass or MSnbase::MSnSet"))
  }
  if (!(group %in% c("samples", "features"))) {
    stop(crayon::red(clisymbols::symbol$cross, "Incorrect value for group argument!"))
  }
  if (missing(group)) {
    warning("group argument is empty! samples will be used")
  }
  if (!is.null(feature_name)) {
    if(!isTRUE(all(feature_name %in% Biobase::featureNames(data)))){
      stop(crayon::red(clisymbols::symbol$cross, "At least one feature name not found..."))
    }
  }

  e <- t(Biobase::exprs(data))
  target <- Biobase::pData(data) %>%
    rownames_to_column("ID") %>%
    rename(Group = 2) %>%
    select(ID, Group)
  
  data <- cbind(target, e)
  
  if(group == "samples"){

    if (is.null(feature_name)){
      
      data %>%
        reshape2::melt() %>%
        group_by(ID) %>%
        ggplot(aes(value, fill = Group)) +
        geom_density(alpha = 0.4) +
        xlab("Value") +
        ylab("Density") +
        theme_bw()
      
    } else {
      
      data %>%
        reshape2::melt() %>%
        group_by(ID) %>%
        filter(variable %in% feature_name) %>%
        ggplot(aes(value, fill = Group)) +
        geom_density(alpha = 0.4) +
        xlab("Value") +
        ylab("Density") +
        theme_bw()
      
    }

  } else {

    if (is.null(feature_name)){

      data %>%
        dplyr::select(-ID) %>%
        reshape2::melt() %>%
        group_by(Group) %>%
        ggplot(aes(value, fill = variable)) +
        geom_density(alpha = 0.4) +
        theme_bw() +
        xlab("Value") +
        ylab("Density") +
        theme(legend.position = "none")

    } else {
      
      data %>%
        dplyr::select(-ID) %>%
        reshape2::melt() %>%
        group_by(Group) %>%
        filter(variable %in% feature_name) %>%
        ggplot(aes(value, fill = variable)) + 
        geom_density(alpha = 0.4) +
        theme_bw() +
        xlab("Value") +
        ylab("Density")
      
      # data %>%
      #   dplyr::select(-ID) %>%
      #   reshape2::melt() %>%
      #   group_by(Group) %>%
      #   filter(variable %in% feature_name) %>%
      #   ggplot(aes(value, fill = interaction(variable, Group))) + 
      #   geom_density(alpha = 0.4) +
      #   theme_bw() +
      #   xlab("Value") +
      #   ylab("Density")

    }
  }
}

