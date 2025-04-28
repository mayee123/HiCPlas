include { BBMAP_BBDUK_adapter } from '../../modules/local/bbmap/bbduk/'
include { BBMAP_BBDUK_quality } from '../../modules/local/bbmap/bbduk/'
include { BBMAP_BBDUK_length } from '../../modules/local/bbmap/bbduk/'
include { CLEANUP } from '../../modules/local/cleanup/main'

workflow BBDUK_SEQUENTIAL {
    take:
    reads // channel: [ val(meta), [ reads ] ]
    adapter

    main:
    BBMAP_BBDUK_adapter ( 
        reads,
        adapter
    )

    BBMAP_BBDUK_quality ( 
        BBMAP_BBDUK_adapter.out.reads
    )
    BBMAP_BBDUK_length ( 
        BBMAP_BBDUK_quality.out.reads
    )
    quality_reads=BBMAP_BBDUK_quality.out.reads.map{meta, reads -> reads}
    adapter_reads=BBMAP_BBDUK_adapter.out.reads.map{meta, reads -> reads}
    intermediate_files = adapter_reads.mix(quality_reads)
    intermediate_files.view()
    CLEANUP(intermediate_files)


    emit:
    reads    = BBMAP_BBDUK_length.out.reads
    
}