process TAXONOMY_REPORT {

    input:
    path(reports, stageAs: "input_reports/*")
    

    output:

    path "bin_tax.tsv", emit: taxonomy_tsv



    """
    T="\$(printf '\t')"

    for x in input_reports/*
    do
        name=\$(basename \$x .txt)
        line=\$($moduleDir/filter_k2_report.sh --taxa S --per 50 --file \$x | sed -n '2p')
        echo "\$name\$T\$line" >> bin_tax.tsv
    done

    """
}
