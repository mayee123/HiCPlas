process BOWTIE2_REMOVAL_ALIGN {
    tag "$meta.id"

    conda "bioconda::bowtie2=2.4.2"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bowtie2:2.4.2--py38h1c8e9b9_1' :
        'biocontainers/bowtie2:2.4.2--py38h1c8e9b9_1' }"

    input:
    tuple val(meta), path(reads)
    path index_files

    output:
    tuple val(meta), path("*.unmapped*.fastq.gz") , emit: reads
    tuple val(meta), path("*.bowtie2.log")        , emit: log
    path "versions.yml"                           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    
    """
    INDEX=\$(find -L ./ -name "*.rev.1.bt2" | sed "s/\\.rev.1.bt2\$//")
    [ -z "\$INDEX" ] && INDEX=\$(find -L ./ -name "*.rev.1.bt2l" | sed "s/\\.rev.1.bt2l\$//")
    [ -z "\$INDEX" ] && echo "Bowtie2 index files not found" 1>&2 && exit 1
    echo "hi"
    bowtie2 -p ${task.cpus} \
            -x \$INDEX \
            -1 "${reads[0]}" -2 "${reads[1]}" \
            $args \
            --un-conc-gz ${prefix}.unmapped_%.fastq.gz \
            1> /dev/null \
            2> ${prefix}.bowtie2.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bowtie2: \$(echo \$(bowtie2 --version 2>&1) | sed 's/^.*bowtie2-align-s version //; s/ .*\$//')
    END_VERSIONS
    """ 
}