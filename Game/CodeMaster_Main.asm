;. The iNes header
.db "NES"
.db $1a
.db $02 ;. Number of PRG-ROM banks
.db $01 ;. Number of CHR-ROM banks

;. ROM control bytes: Horizontal mirroring, no SRAM
;. or trainer, Mapper #0
.db $00, $00

;. Filler
.db $00,$00,$00,$00,$00,$00,$00,$00

;. PRG-ROM
.include "src/CodeMaster_PRG.asm"

;. CHR-ROM
.incbin "src/CHR/CodeMaster_CHR.chr"