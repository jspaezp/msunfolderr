<!-- README.md is generated from README.Rmd. Please edit that file -->
msunfolderr
===========

The goal of msunfolderr is to unfold mass spec raw files.

By that I Mean that there are tools designed to handle only MS1-MS2
data, so as a hacky solution one can generate a fake raw file containing
only 2 levels of ms data to use the tool.

Example
-------

This is a basic example which shows you how to solve a common problem:

``` r
require(msunfolderr)
#> Loading required package: msunfolderr

# Initially we get the information on all the ms scans from the file.
# since the backend of this is the proteowizard sorftware tools, it SHOULD
# work with any vendor format just as well
datafile <- system.file("extdata", "081218-50fmolMix_180813173507.mzML", package = "msunfolderr")
spectable <- get_spectrum_table(datafile,
                                outdir = './tmp')
#> [1] "[MSDataAnalyzerApplication] Analyzing file: C:/Users/Sebastian/Documents/R/win-library/3.5/msunfolderr/extdata\\081218-50fmolMix_180813173507.mzML"
#> [2] "[SpectrumTable] Writing file ./tmp\\081218-50fmolMix_180813173507.mzML.spectrum_table.tsv"                                                         
#> [3] ""
#> results file will be read from ./tmp\081218-50fmolMix_180813173507.mzML.spectrum_table.tsv
spectable
#>        index        id event analyzer msLevel      rt mzLow mzHigh
#>     1:     0     0.1.1     1 Orbitrap     ms1    0.19   363    899
#>     2:     1     0.1.2     3  IonTrap     ms3    0.36   381    432
#>     3:     2     0.1.3     4  IonTrap     ms3    0.64   356    365
#>     4:     3     0.1.4     5  IonTrap     ms3    0.93   241    606
#>     5:     4     0.1.5     6  IonTrap     ms3    1.21     0      0
#>    ---                                                            
#> 10267: 10266 0.1.10267     3  IonTrap     ms3 2698.17   534    762
#> 10268: 10267 0.1.10268     1 Orbitrap     ms1 2698.44   360    890
#> 10269: 10268 0.1.10269     3  IonTrap     ms3 2698.99   299    823
#> 10270: 10269 0.1.10270     1 Orbitrap     ms1 2699.26   360    874
#> 10271: 10270 0.1.10271     3  IonTrap     ms3 2699.82   221    543
#>        basePeakMZ basePeakInt         TIC charge precursorMZ thermo_monoMZ
#>     1:   371.1016   161247.69  1555835.88      0        0.00             0
#>     2:   404.1385       17.66       37.49      0      413.17             0
#>     3:   364.7277       16.49       19.51      0      397.75             0
#>     4:   364.2067       32.38      212.52      0      382.67             0
#>     5:     0.0000        0.00        0.00      0      399.17             0
#>    ---                                                                    
#> 10267:   534.2520       13.71       37.94      0      542.33             0
#> 10268:   379.2635   833050.38 17091244.00      0        0.00             0
#> 10269:   518.1636       25.43       57.64      0      542.33             0
#> 10270:   371.1010   802822.31 17194972.00      0        0.00             0
#> 10271:   542.9978       20.97       53.97      0      542.33             0
#>        filterStringMZ ionInjectionTime
#>     1:           0.00          50.0000
#>     2:         421.74         100.0000
#>     3:         429.73         100.0000
#>     4:         399.75         100.0000
#>     5:         421.74         100.0000
#>    ---                                
#> 10267:         827.48         100.0000
#> 10268:           0.00           7.6913
#> 10269:         827.48         100.0000
#> 10270:           0.00           7.6487
#> 10271:         827.48         100.0000
```

``` r
msfilters <- get_unique_filters(spectable)
msfilters # These are all the ms filters that are contained in the selected file
#>     precursorMZ msLevel filterStringMZ
#>  1:        0.00     ms1           0.00
#>  2:      413.17     ms3         421.74
#>  3:      397.75     ms3         429.73
#>  4:      382.67     ms3         399.75
#>  5:      399.17     ms3         421.74
#>  6:      429.73     ms2         429.73
#>  7:      487.26     ms2         487.26
#>  8:      421.74     ms2         421.74
#>  9:      798.49     ms2         798.49
#> 10:      385.17     ms3         416.73
#> 11:      416.73     ms2         416.73
#> 12:      644.82     ms2         644.82
#> 13:      375.69     ms2         375.69
#> 14:      750.38     ms2         750.38
#> 15:      683.83     ms2         683.83
#> 16:      455.25     ms3         789.49
#> 17:      636.33     ms3         750.38
#> 18:      547.30     ms2         547.30
#> 19:      669.84     ms2         669.84
#> 20:      683.85     ms2         683.85
#> 21:      699.34     ms2         699.34
#> 22:      726.84     ms2         726.84
#> 23:      542.33     ms3         827.48
#> 24:      622.85     ms2         622.85
#> 25:      414.24     ms2         414.24
#> 26:      827.48     ms2         827.48
#> 27:      636.87     ms2         636.87
#> 28:      776.93     ms2         776.93
#>     precursorMZ msLevel filterStringMZ
```

``` r
filtergroups <- get_filter_groups(msfilters, TRUE)
filtergroups # These would be the MS2-MS3 "pairs"
#> $`416.73`
#> [1] 385.17 416.73
#> 
#> $`421.74`
#> [1] 413.17 399.17 421.74
#> 
#> $`429.73`
#> [1] 397.75 429.73
#> 
#> $`750.38`
#> [1] 750.38 636.33
#> 
#> $`827.48`
#> [1] 542.33 827.48
```

``` r
purrr::map2(names(filtergroups), filtergroups, function(x,y){
    outdir <- glue::glue('./tmp{x}', x = x)
    subset_ms(datafile,
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
#> [[1]]
#> NULL
#> 
#> [[2]]
#> NULL
#> 
#> [[3]]
#> NULL
#> 
#> [[4]]
#> NULL
#> 
#> [[5]]
#> NULL
```

``` r
system2('ls','tmp*.*', stdout = TRUE)
#>  [1] "tmp416.73:"                                     
#>  [2] "081218-50fmolMix_180813173507.mzML"             
#>  [3] "081218-50fmolMix_180813173507.mzML_reduced.mzML"
#>  [4] ""                                               
#>  [5] "tmp421.74:"                                     
#>  [6] "081218-50fmolMix_180813173507.mzML"             
#>  [7] "081218-50fmolMix_180813173507.mzML_reduced.mzML"
#>  [8] ""                                               
#>  [9] "tmp429.73:"                                     
#> [10] "081218-50fmolMix_180813173507.mzML"             
#> [11] "081218-50fmolMix_180813173507.mzML_reduced.mzML"
#> [12] ""                                               
#> [13] "tmp750.38:"                                     
#> [14] "081218-50fmolMix_180813173507.mzML"             
#> [15] "081218-50fmolMix_180813173507.mzML_reduced.mzML"
#> [16] ""                                               
#> [17] "tmp827.48:"                                     
#> [18] "081218-50fmolMix_180813173507.mzML"             
#> [19] "081218-50fmolMix_180813173507.mzML_reduced.mzML"
```
