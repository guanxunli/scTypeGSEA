#' Title Assign cell type for single cell data.
#'
#' This is the main function of scTypeGSEA, which can do quality control, data pre-process, cluster, get full changes, do GSEA and label the cell in one step.
#'
#' @param obj A seurat object or a count gene expression
#' @param min.cells Include features detected in at least this many cells. Will subset the counts matrix as well. To reintroduce excluded features, create a new object with a lower cutoff.
#' @param min.features Include cells where at least this many features are detected.
#' @param percent.mt The highest percentage of reads that map to the mitochondrial genome.
#' @param oversd Remove cells whose library size is greater than mean + oversd * sd. Default is null, which doesn't remove cells.
#' @param normalization.method Method for normalization. Include 'LogNormalize', 'CLR' and 'RC'.
#' @param scale.factor Sets the scale factor for cell-level normalization.
#' @param selection.method How to choose top variable features. Include 'vst', 'mean.var.plot' and 'dispersion'.
#' @param nfeatures Number of features to select as top variable features.
#' @param npcs Total Number of PCs to compute and store (50 by default).
#' @param dims Dimensions of reduction to use as input. (For cluster.)
#' @param k.param Defines k for the k-nearest neighbor algorithm. (For cluster.)
#' @param resolution Value of the resolution parameter, use a value above (below) 1.0 if you want to obtain a larger (smaller) number of communities. (For cluster.)
#' @param doit If the object contains the cluster, whether do the cluster with parameters. (Default is FALSE)
#' @param doprocess Whether do data process (Normalization, Scale data, Find HVG and PCA) with new parameters.
#' @param min.pct only test genes that are detected in a minimum fraction of min.pct cells in either of the two populations. Meant to speed up the function by not testing genes that are very infrequently expressed.
#' @param logfc.threshold Limit testing to genes which show, on average, at least X-fold difference (log-scale) between the two groups of cells. Increasing logfc.threshold speeds up the function, but can miss weaker signals.
#' @param test.use Denotes which test to use. Available options are 'wilcox', 'bimod', 'roc', 'negbinom', 'poisson', 'LR', 'MAST' and 'DESeq2'.
#' @param db The cell type data base to use. It should be 'PanglaoDB_list' for 'PanglaoDB' data base and 'GSEA_list' for 'GSEA' data base.
#' @param otherdb A path to the new data base that hope to be used, which is list of cell types with their marker genes. The file must be 'rds' format.
#' @param minSize Minimal size of a gene set to test. All pathways below the threshold are excluded.
#' @param maxSize Maximal size of a gene set to test. All pathways above the threshold are excluded.
#'
#' @return A list contains two entries. The first is a Seurat object with cell type for each cell and the second is a cell matrix.
#' @export
#'
#' @examples
#' pbmc_res <- assignCellType(obj = pbmc_small, min.cells = 1, min.features = 10, nfeatures = 100,
#'                            npcs = 10, dims = 1:10, k.param = 5, resolution = 0.75,
#'                            min.pct = 0.25, test.use = "MAST", minSize = 5)
assignCellType <- function(obj, min.cells = 3, min.features = 200, percent.mt = 5, oversd = NULL,
                           normalization.method = "LogNormalize", scale.factor = 10000, selection.method = "vst", nfeatures = 2000,
                           npcs = 50, dims = 1:50, k.param = 20, resolution = 0.5, doit = "FALSE", doprocess = "FALSE",
                           min.pct = 0.1, test.use = "wilcox", logfc.threshold = 0.25,
                           db = "PanglaoDB_list", otherdb = NULL, minSize = 15, maxSize = 500){
  # quality control
  obj <- scqc(obj, min.cells = min.cells, min.features = min.features, percent.mt = percent.mt, oversd = oversd)

  # data-process and clustering
  obj <- doClustering(obj, normalization.method = normalization.method, scale.factor = scale.factor, selection.method = selection.method, nfeatures = nfeatures,
                      npcs = npcs, dims = dims, k.param = k.param, resolution = resolution, doit = doit, doprocess = doprocess)

  # get full changes
  cluster_list <- getFC(obj, min.pct = min.pct, test.use = test.use, logfc.threshold = logfc.threshold)

  # Do GSEA
  cluster_celltype <- doGSEA(cluster_list = cluster_list, db = db, otherdb = otherdb, minSize = minSize, maxSize = maxSize)

  # label the seurat object
  return(labelSeurat(obj, cluster_celltype))
}