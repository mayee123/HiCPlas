process runNfCoreMag {
    input:
    path samplesheet


    output:
    path("results/Assembly/MEGAHIT/MEGAHIT-*.contigs.fa.gz")    , emit: chromosome
    path("results/Assembly/MEGAHIT/MEGAHIT-*.log")
    path("results/Assembly/MEGAHIT/QC/*/QUAST/*")
    path("results/Assembly/SPAdesHybrid/SPAdesHybrid-*.scaffolds.fa.gz") , emit: hybrid_chromosome , optional: true
    path("results/Assembly/SPAdesHybrid/SPAdesHybrid-*.spades.log") , optional: true
    path("results/Assembly/SPAdesHybrid/QC/*/QUAST/*"), optional: true
    path("results/QC_shortreads/*")
    path("results/QC_longreads/*") , optional: true
    path("results/multiqc/*")

    script:
    def host_args = params.host_removal ? 
        "--host_fasta ${params.host_fasta} --host_fasta_bowtie2index ${params.host_fasta_bowtie2index}" : 
        ""
    """
    nextflow run nf-core/mag \\
        -profile singularity \\
        --input $samplesheet \\
        --outdir results \\
        --skip_gtdbtk \\
        --skip_prodigal \\
        --skip_binning \\
        --skip_spades \\
        ${host_args} \\
        --host_fasta ${workflow.projectDir}/assets/data/GRCh38.primary_assembly.genome.fa \\
        --host_fasta_bowtie2index ${workflow.projectDir}/assets/data/ \\
        -c ${workflow.projectDir}/conf/custom_mag.config
    """
}
