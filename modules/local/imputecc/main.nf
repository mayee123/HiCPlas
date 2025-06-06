process IMPUTECC {
    debug true  // This will show all output

    input:
    tuple val(meta), path(contigs)
    path contig_info
    path contact_matrix

    output:
    path("ImputeCC/FINAL_BIN/*.fa")  , emit: results
    path("ImputeCC/ImputeCC.log"), emit: log


    

    script:
    """
    python  ${projectDir}/bin/ImputeCC/ImputeCC.py pipeline $contigs $contig_info $contact_matrix ImputeCC
    """
}