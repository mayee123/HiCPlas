process METACC_BIN {

    input:
    tuple val(meta), path(contigs)
    path(output_folder)

    output:
    path("metacc/BIN/*.fa")  , emit: results

    

    script:
    """
    
    python /MetaCC/MetaCC.py bin --cover $contigs $output_folder
    """
}