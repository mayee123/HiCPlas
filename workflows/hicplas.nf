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
include { IMPUTECC } from '../modules/local/imputecc/main'
include { CHECKM_LINEAGEWF } from '../modules/nf-core/checkm/lineagewf/main'
include { KRAKEN2_MAIN } from '../modules/local/kraken2/kraken2/main'
include { TAXONOMY_REPORT } from '../modules/local/taxonomy_report/main'
include { BBDUK_SEQUENTIAL } from '../subworkflows/local/bbduk'
include { UNZIP } from '../modules/local/unzip/main'
include { BOWTIE2_REMOVAL_ALIGN } from '../modules/local/bowtie2/main'


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
    /*
    ch_hic=Channel.fromFilePairs(params.hic_read)
    .map {
            id, files ->
        def meta        = [:]
            meta.id     = id
        [meta, files]
    }
    ch_hic.view()
    human_ch=Channel.fromPath('/home/myee/scratch/HiCPlas/assets/data/')
    adapters_ch=Channel
    .fromPath('/home/myee/scratch/HiCPlas/adapters.fa')
    BBDUK_SEQUENTIAL(ch_hic,adapters_ch)
    if (params.host_removal) {
        BOWTIE2_REMOVAL_ALIGN(BBDUK_SEQUENTIAL.out.reads, human_ch)
        BOWTIE2_REMOVAL_ALIGN.out.reads.set{hic_trimmed}

    }
    else{
        BBDUK_SEQUENTIAL.out.reads.set{hic_trimmed}

    }
    
    
    
    
    runNfCoreMag(ch_samplesheet)
    if (params.hybrid) {
        UNZIP(runNfCoreMag.out.hybrid_chromosome)
       
    }
    else{
        UNZIP(runNfCoreMag.out.chromosome)
    }
    UNZIP.out.unzipped_fa
        .map {
            fasta ->
            def meta        = [:]
                meta.id     = "contig"
            [meta, fasta] }
        .set{ch_assem}
    
    
    BWA_INDEX(ch_assem)    
    BWA_MEM(hic_trimmed, BWA_INDEX.out.index)
    */
    ch_assem=Channel
    .fromPath('/home/myee/scratch/HiCPlas/B314-1_impute/unzip/MEGAHIT-B314-1.contigs.fa').map {
            fasta ->
            def meta        = [:]
                meta.id     = "contig"
            [meta, fasta] }
    ch_bam=Channel.fromPath('/home/myee/scratch/HiCPlas/B314-1_impute/bwa/MAP_SORTED.bam').map {
            fasta ->
            def meta        = [:]
                meta.id     = "contig"
            [meta, fasta] }
    ch_assem.view()
    ch_bam.view()
    METACC_NORM(ch_assem, ch_bam)
    //METACC_NORM(ch_assem, BWA_MEM.out.bam)
    

    if (params.enzyme) {
        if (params.imputecc){
            IMPUTECC(ch_assem, METACC_NORM.out.contig_info, METACC_NORM.out.matrix)
            ch_bin=IMPUTECC.out.results
        }
    }

    else{
        METACC_BIN(ch_assem, METACC_NORM.out.output_folder)
        ch_bin=METACC_BIN.out.results
    }
    


    ch_bin
        .flatten()
            .map {
                fasta ->
                def meta        = [:]
                    meta.id     = fasta.name.replaceFirst(/\.fa$/, '')
                [meta, fasta] }
    
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

    
    //ch_report=Channel.fromPath('/home/myee/scratch/HiCPlas/B314-2/kraken2/BIN*.kraken2.report.txt').collect()
    ch_report.view()
    filter_script = file("${projectDir}/modules/local/taxonomy_report/filter_kraken.py")
    TAXONOMY_REPORT(ch_report, filter_script)
    



}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
