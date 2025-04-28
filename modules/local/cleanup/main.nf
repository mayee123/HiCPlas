process CLEANUP {
    input:
    path file_to_delete

    script:
    """
    rm -f $file_to_delete
    """
}