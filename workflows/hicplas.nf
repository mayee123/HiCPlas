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
include { QC3C} from '../modules/local/qc3c/main'
include { FASTQC as FASTQC_RAW                   } from '../modules/nf-core/fastqc/main'
include { FASTQC as FASTQC_TRIMMED               } from '../modules/nf-core/fastqc/main'

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
    FASTQC_RAW(ch_hic)



    ch_adapters = Channel.fromPath("${projectDir}/bin/adapters.fa", checkIfExists: true)
    if (!params.skip_hic_trim){
        BBDUK_SEQUENTIAL(ch_hic,ch_adapters)
        ch_hic = BBDUK_SEQUENTIAL.out.reads
        FASTQC_TRIMMED(ch_hic)
    }
    


    if (params.host_removal) {
        if (params.host_fasta_bowtie2index){
            ch_host_fasta = Channel.fromPath("${params.host_fasta_bowtie2index}", checkIfExists: true).first() ?: false
            BOWTIE2_REMOVAL_ALIGN(ch_hic, human_ch)
            BOWTIE2_REMOVAL_ALIGN.out.reads.set{hic_trimmed}
        }

    }
    else{
        ch_hic.set{hic_trimmed}

    }
    
    
    if (!params.skip_assembly){
        runNfCoreMag(ch_samplesheet)
        if (params.hybrid) {
            UNZIP(runNfCoreMag.out.hybrid_chromosome)
        
        }
        else{
            UNZIP(runNfCoreMag.out.chromosome)
        }
        ch_assem=UNZIP.out.unzipped_fa
            
    }
    else{
        ch_assem=Channel.fromPath(params.assembled_contigs)
    }
    ch_assem.map {
                fasta ->
                def meta        = [:]
                    meta.id     = "contig"
                [meta, fasta] }
            .set{ch_contigs}

    
    
    BWA_INDEX(ch_contigs)    
    BWA_MEM(ch_hic, BWA_INDEX.out.index)
    //BWA_MEM(hic_trimmed, BWA_INDEX.out.index)
    if (!params.skip_qc3c) {
        if (params.enzyme){
            QC3C(ch_contigs, BWA_MEM.out.bam)
        }
    }
    METACC_NORM(ch_contigs, BWA_MEM.out.bam)
    
    
    
    if (params.imputecc) {
        if (params.enzyme){
            IMPUTECC(ch_contigs, METACC_NORM.out.contig_info, METACC_NORM.out.matrix)
            ch_bin=IMPUTECC.out.results
        }
    }

    else{
        METACC_BIN(ch_contigs, METACC_NORM.out.output_folder)
        ch_bin=METACC_BIN.out.results
    }
    



    ch_bin
        .flatten()
            .map {
                fasta ->
                def meta        = [:]
                    meta.id     = fasta.getBaseName()
                [meta, fasta] }
                .set{ch_bin_files}
            
           

    ch_bin_files.view()
    MOBSUITE_RECON(ch_bin_files)
    
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
    
    if (!params.skip_kraken){
        db_ch=Channel.fromPath(params.kraken_db)
            .collect()
    KRAKEN2_MAIN(ch_chrom, db_ch)
    KRAKEN2_MAIN.out.report
        .map {
            id, report ->
            report
        }
            .collect()
                .set{ch_report}


    filter_script = file("${projectDir}/modules/local/taxonomy_report/filter_kraken.py")
    TAXONOMY_REPORT(ch_report, filter_script)
    }
    

    



    
    



}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
