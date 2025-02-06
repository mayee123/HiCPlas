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
include { MOBSUITE_RECON } from '../modules/nf-core/mobsuite/recon/main'
include { runNfCoreMag } from '../modules/local/mag/main'
include { BWA_INDEX } from '../modules/nf-core/bwa/index/main'
include { BWA_MEM } from '../modules/nf-core/bwa/mem/main'
include { METACC_NORM } from '../modules/local/metacc/norm/main'
include { METACC_BIN } from '../modules/local/metacc/bin/main'
include { CHECKM_LINEAGEWF } from '../modules/nf-core/checkm/lineagewf/main'
include { KRAKEN2_MAIN } from '../modules/local/kraken2/kraken2/main'
include { TAXONOMY_REPORT } from '../modules/local/taxonomy_report/main'

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
    
    runNfCoreMag(ch_samplesheet)
    

    runNfCoreMag.out.chromosome
        .map {
            fasta ->
            def meta        = [:]
                meta.id     = "testing"
            [meta, fasta] }
        .set{ch_assem}
    
    BWA_INDEX(ch_assem)
    BWA_INDEX.out.index.view()

    
    Channel.fromPath(params.hic_read_1)
        .map {
            fasta ->
            def meta        = [:]
                meta.id     = "testing"
            [meta, fasta] }
        .set{ch_hic1}

    Channel.fromPath(params.hic_read_2)
        .map {
            fasta ->
            def meta        = [:]
                meta.id     = "testing"
            [meta, fasta] }
        .set{ch_hic2}
        
    ch_hic=Channel.fromFilePairs("/home/myee/projects/def-sponsor00/myee/thesis/hic/data/SAMN18524913/HI-C/SRR14292245_{1,2}.fastq.gz")
        .map {
             id, files ->
            def meta        = [:]
                meta.id     = id
            [meta, files]
        }
    ch_hic.view()
    BWA_MEM(ch_hic, BWA_INDEX.out.index)

  
    
    //Channel.fromPath("/home/myee/projects/def-sponsor00/myee/thesis/hic/sim/brinkman/art_Mega_no_err_SORTED.bam")
    //   .map {
    //            fasta ->
    //            def meta        = [:]
    //                meta.id     = "testing"
    //            [meta, fasta] }
    //        .set{ch_bam}
    
    //Channel.fromPath("/home/myee/projects/def-sponsor00/myee/thesis/hic/sim/brinkman/MAG_art_megahit/Assembly/MEGAHIT/MEGAHIT-metagenome.contigs.fa")
    
    //    .map {
    //            fasta ->
    //            def meta        = [:]
    //                meta.id     = "testing"
    //            [meta, fasta] }
    //        .set{ch_contigs}
    METACC_NORM(ch_assem, BWA_MEM.out.bam)

    
    //ch_thing=Channel
    //.fromPath('/home/myee/projects/def-sponsor00/myee/thesis/hic_pipeline/bin_my/nf-core-hicplas/test/*.fa')
    //.collect()
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
   // ch_thing
   //     .flatten()
   //         .map {
   //             fasta ->
   //             def meta        = [:]
   //                 meta.id     = fasta.name.replaceFirst(/\.fa$/, '')
   //             [meta, fasta] }
   //         .set{ch_bin}
    MOBSUITE_RECON(ch_bin)
    
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
    .fromPath('/home/myee/object_database/kraken2')
        .collect()
    
    KRAKEN2_MAIN(MOBSUITE_RECON.out.chromosome, db_ch)
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
