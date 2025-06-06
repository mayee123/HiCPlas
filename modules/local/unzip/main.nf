process UNZIP {

    input:
    path input_file

    output:
    path "*.fa", emit: unzipped_fa

    script:
    """
    filename=\$(basename "$input_file" .gz)
    gunzip -c "$input_file" > "\$filename"
    """
}