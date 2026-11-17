; Startup code for SDCC programs on the CPC: sets up initialised data, its own stack and calls main().
; The stack (STACK bytes, after the data) is the program's own: the firmware's at &BF00-&BFFF has
; only ~200 bytes left when main starts, and C code with a few local buffers goes below &BF00 into
; the firmware's RAM (seen 2026-11-17: fujinet-network-cpc's test failed depending on where its
; data was). It has to stay between &4000 and &BFFF (firmware routines run with the lower ROM on
; and would read their return addresses from ROM), so the data cannot go below &4000.
;   MEMORY &3FFF:LOAD"NAME":CALL &4000   main returns to BASIC
;   RUN"NAME"               works too, but RUN resets the firmware and the CPC restarts at the end

        .module crt0
        .globl  _main
        .globl  l__INITIALIZER, s__INITIALIZER, s__INITIALIZED     ; set by the linker
        .globl  l__DATA, s__DATA

        .area   _HEADER (ABS)
        .org    0x4000
        jp      init

        ; the order of the areas = their order in memory
        .area   _HOME
        .area   _CODE
        .area   _INITIALIZER
        .area   _GSINIT
        .area   _GSFINAL
        .area   _DATA
        .area   _INITIALIZED
        .area   _BSEG
        .area   _BSS
        .area   _HEAP
        .area   _STACK

        .area   _CODE
init:
        ld      (crt0_sp), sp       ; the caller's stack: main returns to BASIC on it
        ld      sp, #crt0_stack_top
        call    gsinit
        call    _main
        ld      sp, (crt0_sp)
        ret

        .area   _GSINIT
gsinit::
        ld      bc, #l__DATA        ; global variables without an initial value start as 0 (C);
        ld      a, b                ; the binary does not contain them, and RAM is not cleared -
        or      a, c                ; below &4000 (--data-loc) it holds what BASIC left there
        jr      z, gsinit_init
        ld      hl, #s__DATA
        ld      (hl), #0
        dec     bc
        ld      a, b
        or      a, c
        jr      z, gsinit_init
        ld      d, h
        ld      e, l
        inc     de
        ldir
gsinit_init:
        ld      bc, #l__INITIALIZER ; copy the initial values of global variables
        ld      a, b
        or      a, c
        jr      z, gsinit_next
        ld      de, #s__INITIALIZED
        ld      hl, #s__INITIALIZER
        ldir
gsinit_next:

        .area   _GSFINAL
        ret

STACK = 1024
        .area   _STACK              ; last: not cleared by gsinit
crt0_sp:
        .ds     2
        .ds     STACK
crt0_stack_top:
