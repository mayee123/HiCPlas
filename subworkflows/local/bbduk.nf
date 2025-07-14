include { BBMAP_BBDUK_adapter } from '../../modules/local/bbmap/bbduk/'
include { BBMAP_BBDUK_quality } from '../../modules/local/bbmap/bbduk/'
include { BBMAP_BBDUK_length } from '../../modules/local/bbmap/bbduk/'
include { BBMAP_CLUMPIFY} from '../../modules/local/bbmap/bbduk/'


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
    BBMAP_CLUMPIFY (
        BBMAP_BBDUK_length.out.reads
    )


    emit:
    reads    = BBMAP_CLUMPIFY.out.reads
    
}