SECTION INST                    ; inst code gets own section

ORG (RF_ORG+RF_INST_OFFSET)     ; located where it can be
                                ; safely abandoned and 
                                ; overwritten after inst
