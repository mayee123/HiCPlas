process METACC_NORM {
    input:
    tuple val(meta), path(contigs)
    tuple val(meta), path(bam)

    output:
    path("metacc/contig_info.csv")          , emit: contig_info
    path("metacc/MetaCC.log")               , emit: log
    path("metacc/*.npz")                    , emit: matrix
    path("metacc/*normalized_contact.gz")   , emit: contact
    path("metacc")                         , emit: output_folder

    

    script:
    def enzyme_arg = params.enzyme ? "-e ${params.enzyme}" : ''
    """
    python /MetaCC/MetaCC.py norm ${enzyme_arg} --min-len 750 $contigs $bam metacc/ 
    """
}