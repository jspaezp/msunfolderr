
parse.spectrum.table <- function(filepath) {
    # rawfilename <- scan(filepath, nlines = 1, what = 'character')
    tablenames <- scan(filepath, nlines = 1, skip = 1,what = 'character')
    if (any(grepl("#", tablenames))) { tablenames <- tablenames[-1] }
    df <- data.table::fread(filepath, skip = 2)
    data.table::setnames(df, colnames(df), tablenames)
    return(df)
}


get.spectrumtable <- function(filepath, outdir = '.') {
    system2("msaccess",
            glue::glue("msaccess.exe -x 'spectrum_table delimiter=tab' ",
                       "-o '{outdir}' {filepath}"))
}


get_unique_filters <- function(filename) {
    filters <- unique(
        parse.spectrum.table(filename)[
            , c("precursorMZ", "msLevel", "filterStringMZ")])

    return(filters)
}

msfilters <- get_unique_filters('./inst/extdata/foo/081218-50fmolMix_180813173507.raw.spectrum_table.tsv')


splitfilters <- split(msfilters,as.factor(msfilters[[3]]))
splitfilters[lapply(splitfilters, function(x) dim(x)[[1]]) > 1]



# TODO vectorize thif function and make reducemslevel read in chunks
# TODO also benchmark that ...
reducemslevelheader <- function(line, minmslevel = 1, maxmslevel = 9, reduction = 1) {
    regex <- glue::glue("(?<=name=\"ms level\" value=\")[{a}-{b}]+",
                        a = minmslevel,
                        b = maxmslevel)

    num <- unlist(
        regmatches(
            line,
            regexec(
                regex,
                line,
                perl = TRUE)))
    if (length(num) == 1) {
        regmatches(
            line,
            regexec(regex,
                    line, perl = TRUE)) <- as.numeric(num) - reduction
    }
    return(line)
}



reducemslevels <- function(filepath, filepath.out, minmslevel = 1, maxmslevel = 9, reduction = 1) {
    con = file(filepath, "r")
    con2 = file(filepath.out, "wb")
    while (TRUE) {
        line <- readLines(con, n = 1)
        if (length(line) == 0) {
            break
        }
        line <- reducemslevelheader(line,  minmslevel = minmslevel,
                                    maxmslevel = maxmslevel, reduction = reduction)
        writeLines(line, con2)
    }
    close(con)
    close(con2)
}





test_reducemslevel <- function() {
    testline  <- "          <cvParam cvRef=\"MS\" accession=\"MS:1000511\" name=\"ms level\" value=\"2\"/>"
    expect <- "          <cvParam cvRef=\"MS\" accession=\"MS:1000511\" name=\"ms level\" value=\"1\"/>"
    stopifnot(reducemslevelheader(testline) == expect)
}
test_reducemslevel()



