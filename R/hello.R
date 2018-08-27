
parse.spectrum.table <- function(filepath) {
    # rawfilename <- scan(filepath, nlines = 1, what = 'character')
    tablenames <- scan(filepath, nlines = 1, skip = 1,what = 'character')
    if (any(grepl("#", tablenames))) { tablenames <- tablenames[-1] }
    df <- data.table::fread(filepath, skip = 2)
    data.table::setnames(df, colnames(df), tablenames)
    return(df)
}


get_spectrum_table <- function(filepath, outdir = '.') {
    results <- system2("msaccess",
            glue::glue("--verbose ",
                       "-x \"spectrum_table delimiter=tab\" ",
                       "-o {outdir} {filepath}"), wait = TRUE, stdout = TRUE)
    print(results)

    resultsfile <- grep(pattern = "SpectrumTable", results, value = TRUE)
    resultsfile <- gsub(".* Writing file (.*.tsv)", "\\1", resultsfile)

    #return(resultsfile)
    df <- data.table::fread(resultsfile)
    return(df)
}


get_unique_filters <- function (x, ...) {
    UseMethod("get_unique_filters", x)
}

get_unique_filters.data.frame <- function(x, ...) {
    unique(x[,c("precursorMZ", "msLevel", "filterStringMZ")])
}

get_unique_filters.character <- function(x) {
    stopifnot(file.exists(x))

    df <- parse.spectrum.table(x)
    filters <- get_unique_filters.data.frame(df)

    return(filters)
}



get_filter_groups <- function(x, ...) {
    UseMethod("get_filter_groups", x)
}


get_filter_groups.data.frame <- function(x, simplify = FALSE,...) {
    splitfilters <- split(x,as.factor(x[['filterStringMZ']]))
    is_grouped <- lapply(splitfilters, function(splitfilters) dim(splitfilters)[[1]]) > 1
    grouped_filters <- splitfilters[is_grouped]
    ungrouped_filters <- splitfilters[!is_grouped]

    if (simplify) {
        grouped_filters <- lapply(grouped_filters, function(x){x[["precursorMZ"]]})
    }

    return(grouped_filters)
}


get_filter_groups.character <- function(x, ...) {
    stopifnot(file.exists(x))

    df <- parse.spectrum.table(x)
    filter_groups <- get_filter_groups.data.frame(df, ...)

    return(filter_groups)
}



subset_ms <- function(filepath, precursors, outdir) {
    system2(
        'msconvert',
        glue::glue(
            " --verbose ",
            "--outdir {outdir} {filepath} ",
            " --filter \"mzPrecursors [{paste(precursors, collapse = ',')}]\" ",
            precursors = precursors,
            filepath = filepath,
            outdir = outdir))
}



reducemslevels <- function(filepath, filepath.out,
                           minmslevel = 1, maxmslevel = 9,
                           reduction = 1, dry = FALSE) {
    con = file(filepath, "r")
    con2 = file(filepath.out, "wb")

    regex <- glue::glue("^(.*name=\"ms level\" value=\")([{a}-{b}])(\"\\/>$)",
                        a = minmslevel,
                        b = maxmslevel)
    testregex <- "(name=\"ms level\" value=\")([0-9])(\"\\/>$)"
    while (TRUE) {
        line <- readLines(con, n = 1)
        if (length(line) == 0) {
            break
        }

        matchdata <- grepl(testregex, line, perl = TRUE)
        if (matchdata) {
            num <- gsub(regex, "\\2", line, perl = TRUE)
            line <- gsub(regex,
                         paste0("\\1",
                                newmslevel = as.numeric(num)-1,
                                "\\3"),
                         line, perl = TRUE)
        }
        if (dry) {
            print(line)
        } else {
            writeLines(line, con2)
        }
    }
    close(con)
    close(con2)
}


spectable <- get_spectrum_table('./inst/extdata/081218-50fmolMix_180813173507.mzML', outdir = 'tmp2')
msfilters <- get_unique_filters(spectable)
filtergroups <- get_filter_groups(msfilters, TRUE)


purrr::map2(names(filtergroups), filtergroups, function(x,y){
    outdir <- glue::glue('./tmp{x}', x = x)
    subset_ms('./inst/extdata/081218-50fmolMix_180813173507.mzML',
              y,
              outdir)

    mzmlfiles <- dir(outdir, pattern = '.mzML', full.names = TRUE)
    for (file in mzmlfiles) {
        reducemslevels(file,
                       filepath.out = glue::glue(file, '_reduced.mzML'),
                       minmslevel = 1,
                       maxmslevel = 3,
                       reduction = 1)

    }
})

