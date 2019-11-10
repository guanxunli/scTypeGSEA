#' Runs preranked gene set enrichment analysis.
#'
#' The function do gene set enrichment analysis(GSEA) for each cluster with its gene ranks. It will return cell type for each cluster.
#'
#' @importFrom fgsea fgseaMultilevel
#' @param cluster_list A ranked gene list for each cluster.
#' @param db The cell type data base to use. It should be 'PanglaoDB_list' for 'PanglaoDB' data base and 'GSEA_list' for 'GSEA' data base.
#' @param otherdb A path to the new data base that hope to be used, which is list of cell types with their marker genes. The file must be 'rds' format.
#' @param minSize Minimal size of a gene set to test. All pathways below the threshold are excluded.
#' @param maxSize Maximal size of a gene set to test. All pathways above the threshold are excluded.
#'
#' @return Cell type for each cluster, and its NSF and padj.
#' @export
#' @examples
#' pbmc_example <- doClustering(pbmc_test, nfeatures = 100, npcs = 10,
#'                               dims = 1:10, k.param = 5, resolution = 0.75)
#' cluster_list <- getFC(pbmc_example, min.pct = 0.25, test.use = 'MAST')
#' cluster_celltype <- doGSEA(cluster_list = cluster_list, minSize = 5)
doGSEA <- function(cluster_list, db = "PanglaoDB_list", otherdb = NULL, minSize = 15, maxSize = 500) {

  # number of cluster
  ncluster <- length(cluster_list)
  cluster_celltype <- matrix(NA, nrow = ncluster, ncol = 3)
  rownames(cluster_celltype) <- names(cluster_list)
  colnames(cluster_celltype) <- c("cell type", "NES", "padj")

  # decide the database to use
  if (is.null(otherdb)) {
    if (db ==  "PanglaoDB_list") {
      pathways <- PanglaoDB_list
    } else{
      pathways <- GSEA_list
    }
  } else{
    pathways <- readRDS(otherdb)
  }

  # Do fgsea to each cluster
  for (i in 1:ncluster) {
    cat(paste0("Do GSEA for cluster"), i - 1, "\n")

    Ranks <- cluster_list[[i]]
    set.seed(1234)
    options(warn=-1)
    fgseaRes <- fgsea::fgseaMultilevel(pathways = pathways, stats = Ranks, minSize = minSize, maxSize = maxSize)
    fgseaRes <- fgseaRes[fgseaRes$padj < 0.05 & fgseaRes$NES > 0,, drop=FALSE]

    ## decide the cell type
    if (nrow(fgseaRes) == 0){
      cluster_celltype[i, 1] <- "unidentified"
    } else{
      index <- order( -fgseaRes[, "padj"], fgseaRes[, "NES"], decreasing = TRUE)
      fgseaRes <- fgseaRes[index, ]
      cluster_celltype[i, 1] <- fgseaRes$pathway[1]
      cluster_celltype[i, 2] <- fgseaRes$NES[1]
      cluster_celltype[i, 3] <- fgseaRes$padj[1]
    }
  }
  return(cluster_celltype)
}