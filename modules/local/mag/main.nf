process runNfCoreMag {
    input:
    path samplesheet


    output:
    path("results/Assembly/MEGAHIT/MEGAHIT-*.contigs.fa")    , emit: chromosome

    script:
    """
    nextflow run nf-core/mag \\
        -profile singularity \\
        --input $samplesheet \\
        --outdir results \\
        --skip_gtdbtk \\
        --skip_prodigal \\
        --skip_binning \\
        --skip_spades 

        
    gunzip results/Assembly/MEGAHIT/MEGAHIT-*.contigs.fa.gz
    """

}