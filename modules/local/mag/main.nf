process runNfCoreMag {
    input:
    path samplesheet


    output:
    path("results/Assembly/MEGAHIT/MEGAHIT-*.contigs.fa")    , emit: chromosome
    path("results/Assembly/MEGAHIT/MEGAHIT-*.log")
    path("results/Assembly/MEGAHIT/QC/*/QUAST/*")
    path("results/Assembly/SPAdesHybrid/SPAdesHybrid-*.scaffolds.fa") , emit: hybrid_chromosome , optional: true
    path("results/Assembly/SPAdesHybrid/SPAdesHybrid-*.spades.log") , optional: true
    path("results/Assembly/SPAdesHybrid/QC/*/QUAST/*"), optional: true
    path("results/QC_shortreads/*")
    path("results/QC_longreads/*") , optional: true
    path("results/multiqc/*")

    script:
    """
    nextflow run nf-core/mag \\
        -profile singularity \\
        --input $samplesheet \\
        --outdir results \\
        --skip_gtdbtk \\
        --skip_prodigal \\
        --skip_binning \\
        --skip_spades \\
        -c ${workflow.projectDir}/custom_mag.config

        
    gunzip results/Assembly/MEGAHIT/MEGAHIT-*.contigs.fa.gz
    if [ -f "results/Assembly/SPAdesHybrid/SPAdesHybrid-*.scaffolds.fa.gz" ]; then
        gunzip results/Assembly/SPAdesHybrid/SPAdesHybrid-*.scaffolds.fa.gz

    fi
    """
}