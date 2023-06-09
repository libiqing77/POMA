
#' Volcano Plot
#'
#' @description PomaVolcano() generates a volcano plot from the PomaUnivariate(method = "ttest") result. The data can't have negative values.
#'
#' @param data A MSnSet object. First `pData` column must be the subject group/type. Only for two group data!
#' @param pval Select a pvalue type to generate the volcano plot. Options are: "raw" and "adjusted".
#' @param pval_cutoff Numeric. Define the pvalue cutoff (horizontal line).
#' @param adjust Multiple comparisons correction method for t test result. Options are: "fdr", "holm", "hochberg", "hommel", "bonferroni", "BH" and "BY".
#' @param log2FC Numeric. Define the log2 fold change cutoff (vertical lines).
#' @param xlim Numeric. Define the limits for x axis.
#' @param labels Logical that indicates if selected labels will be plotted or not. Defaul is FALSE.
#' @param paired Logical that indicates if the data is paired or not.
#' @param var_equal Logical that indicates if the data variance is equal or not.
#' @param interactive Logical that indicates if an interactive plot will be plotted or not. Defaul is FALSE.
#' @param plot_title Logical that indicates if title will be plotted or not. Defaul is TRUE.
#' 
#' @export
#'
#' @return A ggplot2 object.
#' @author Pol Castellano-Escuder
#'
#' @import ggplot2
#' @importFrom ggrepel geom_label_repel
#' @importFrom dplyr mutate
#' @importFrom crayon red
#' @importFrom clisymbols symbol
#' @importFrom plotly ggplotly
#' @importFrom Biobase varLabels pData exprs featureNames
#' 
#' @examples 
#' data("st000336")
#' 
#' st000336 %>% 
#'   PomaImpute() %>%
#'   PomaVolcano()
PomaVolcano <- function(data,
                        pval = "raw",
                        pval_cutoff = 0.05,
                        adjust = "fdr",
                        log2FC = 0.6,
                        xlim = 2,
                        labels = FALSE,
                        paired = FALSE,
                        var_equal = FALSE,
                        interactive = FALSE,
                        plot_title = TRUE){

  if (missing(data)) {
    stop(crayon::red(clisymbols::symbol$cross, "data argument is empty!"))
  }
  if(!is(data[1], "MSnSet")){
    stop(paste0(crayon::red(clisymbols::symbol$cross, "data is not a MSnSet object."), 
                " \nSee POMA::PomaMSnSetClass or MSnbase::MSnSet"))
  }
  if (length(table(Biobase::pData(data)[1])) > 2) {
    stop(crayon::red(clisymbols::symbol$cross, "Your data have more than two groups!"))
  }
  if (missing(pval)) {
    warning("pval argument is empty! Raw p-value will be used")
  }
  if (!(pval %in% c("raw", "adjusted"))) {
    stop(crayon::red(clisymbols::symbol$cross, "Incorrect value for pval argument!"))
  }
  if (!(adjust %in% c("fdr", "holm", "hochberg", "hommel", "bonferroni", "BH", "BY"))) {
    stop(crayon::red(clisymbols::symbol$cross, "Incorrect value for adjust argument!"))
  }
  if (missing(adjust)) {
    warning("adjust argument is empty! FDR will be used")
  }

  df <- POMA::PomaUnivariate(data, method = "ttest", adjust = adjust, paired = paired, var_equal = var_equal)

  names <- featureNames(data)

  if(pval == "raw"){
    df <- data.frame(pvalue = df$pvalue, FC = log2(df$Fold_Change_Ratio), names = names)
  }
  else{
    df <- data.frame(pvalue = df$pvalueAdj, FC = log2(df$Fold_Change_Ratio), names = names)
  }

  df <- mutate(df, threshold = as.factor(ifelse(df$pvalue >= pval_cutoff,
                                                yes = "none",
                                                no = ifelse(df$FC < log2FC,
                                                            yes = ifelse(df$FC < -log2FC,
                                                                         yes = "Down-regulated",
                                                                         no = "none"),
                                                            no = "Up-regulated"))))

  volcanoP <- ggplot(data = df, aes(x = FC, y = -log10(pvalue), colour = threshold, label = names)) +
    geom_point(size=1.75) +
    xlim(c(-(xlim), xlim)) +
    xlab("log2 Fold Change") +
    ylab("-log10 p-value") +
    scale_y_continuous(trans = "log1p")+
    {if(plot_title)ggtitle(paste0("Comparisson: ", names(table(pData(data)[,1]))[2], "/", names(table(pData(data)[,1]))[1]))} +
    geom_vline(xintercept = -log2FC, colour = "black", linetype = "dashed") +
    geom_vline(xintercept = log2FC, colour = "black", linetype = "dashed") +
    geom_hline(yintercept = -log10(pval_cutoff), colour = "black", linetype = "dashed") +
    {if(labels)ggrepel::geom_label_repel(data = df[df$pvalue < pval_cutoff & (df$FC > log2FC | df$FC < -log2FC),],
                                         aes(x = FC, y = -log10(pvalue), label = names), show.legend = FALSE)} +
    theme(legend.position = "none") +
    labs(color = "") +
    theme_bw() +
    scale_color_manual(values = c("Down-regulated" = "#E64B35", "Up-regulated" = "#3182bd", "none" = "#636363"))

  if(interactive){
    volcanoP <- plotly::ggplotly(volcanoP)
  }

  return(volcanoP)

  }

