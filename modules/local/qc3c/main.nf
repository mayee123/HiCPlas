process QC3C {

    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'docker://cerebis/qc3c'
        : 'cerebis/qc3c'}"
    input:
    tuple val(meta), path(contigs)
    tuple val(meta), path(bam)

    output:
    path("output/*.log")  , emit: log
    path("output/*.html")  , emit: html
    path("output/*.json")  , emit: json
    

    script:
    """
    qc3C bam --enzyme $params.enzyme --fasta $contigs --bam $bam --output-path output
    """
}