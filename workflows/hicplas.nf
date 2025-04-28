/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FASTQC                 } from '../modules/nf-core/fastqc/main'
include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap       } from 'plugin/nf-validation'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_hicplas_pipeline'
include { MOBSUITE_RECON } from '../modules/local/mobsuite/recon/main'
include { runNfCoreMag } from '../modules/local/mag/main'
include { BWA_INDEX } from '../modules/nf-core/bwa/index/main'
include { BWA_MEM } from '../modules/nf-core/bwa/mem/main'
include { METACC_NORM } from '../modules/local/metacc/norm/main'
include { METACC_BIN } from '../modules/local/metacc/bin/main'
include { CHECKM_LINEAGEWF } from '../modules/nf-core/checkm/lineagewf/main'
include { KRAKEN2_MAIN } from '../modules/local/kraken2/kraken2/main'
include { TAXONOMY_REPORT } from '../modules/local/taxonomy_report/main'
include { BBDUK_SEQUENTIAL } from '../subworkflows/local/bbduk'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/



workflow HICPLAS {
//take short reads, run qc, assemembly
    
    take:
    ch_samplesheet // channel: samplesheet read in from --input

    main:
    ch_hic=Channel.fromFilePairs(params.hic_read)
        .map {
             id, files ->
            def meta        = [:]
                meta.id     = id
            [meta, files]
        }
    ch_hic.view()
    adapters_ch=Channel
    .fromPath('/home/myee/scratch/HiCPlas/adapters.fa')
    BBDUK_SEQUENTIAL(ch_hic,adapters_ch)
    runNfCoreMag(ch_samplesheet)
    if (params.hybrid) {
        runNfCoreMag.out.hybrid_chromosome
            .map {
                fasta ->
                def meta        = [:]
                    meta.id     = "contig"
                [meta, fasta] }
            .set{ch_assem}
    }
    else{
        runNfCoreMag.out.chromosome
            .map {
                fasta ->
                def meta        = [:]
                    meta.id     = "contig"
                [meta, fasta] }
            .set{ch_assem}
    }
    BWA_INDEX(ch_assem)    
    BWA_MEM(BBDUK_SEQUENTIAL.out.reads, BWA_INDEX.out.index)
    METACC_NORM(ch_assem, BWA_MEM.out.bam)


    METACC_BIN(ch_assem, METACC_NORM.out.output_folder)


    METACC_BIN.out.results
        .flatten()
            .map {
                fasta ->
                def meta        = [:]
                    meta.id     = fasta.name.replaceFirst(/\.fa$/, '')
                [meta, fasta] }
            .set{ch_bin}
    
    ch_bin.view()

    MOBSUITE_RECON(ch_bin)
    
    ch_chrom=MOBSUITE_RECON.out.chromosome
    MOBSUITE_RECON.out.chromosome
        .map {
            id, fasta -> 
            def meta        = [:]
                meta.id     = "checkm"
            [meta, fasta]
        }
            .groupTuple()
                .set{ch_test}  
    CHECKM_LINEAGEWF(ch_test, ".fasta", [])

    db_ch=Channel
    .fromPath('/home/myee/scratch/HiCPlas/database')
        .collect()
    KRAKEN2_MAIN(ch_chrom, db_ch)





    KRAKEN2_MAIN.out.report
        .map {
            id, report ->
            report
        }
            .collect()
                .set{ch_report}
                
    ch_report.view()
    TAXONOMY_REPORT(ch_report)
    



}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
