        SECTION rwdata

_rf_origin EXPORT
_rf_origin RMB    2

        ENDSECTION

        SECTION code

program_end IMPORT

_rf_init_origin EXPORT
_rf_init_origin
        LEAX   program_end,PCR
        STX    _rf_origin,PCR
        RTS

        ENDSECTION
