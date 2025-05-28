process TAXONOMY_REPORT {

    input:
    path(reports, stageAs: "input_reports/*")
    path(filter_script)

    output:

    path "bin_tax_species.tsv", emit: taxonomy_sp_tsv
    path "bin_tax_genus.tsv", emit: taxonomy_g_tsv


    """
    T="\$(printf '\t')"

    for x in input_reports/*
    do
        name=\$(basename \$x .txt)
        #line=\$($moduleDir/filter_k2_report.sh --taxa S --per 50 --file \$x | sed -n '2p')
        line=\$(python ${filter_script} \$x S)
        echo "\$name\$T\$line" >> bin_tax_species.tsv

        #line=\$($moduleDir/filter_k2_report.sh --taxa G --per 50 --file \$x | sed -n '2p')
        line=\$(python ${filter_script} \$x G)
        echo "\$name\$T\$line" >> bin_tax_genus.tsv
    done

    """
}
