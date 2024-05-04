# MnemoSyne-X
Virtual Memory system for MSX.

```mermaid
flowchart
    direction BT
    subgraph MnemoSyne-S Pack
        direction BT

        subgraph MnemoSyne-S_Core
        direction BT

           subgraph Core_Headers
                MS-X_RM_H.S["mnemosyne-x_rammapper_h.s"]:::asmHeader
                MS-X_C_H.S["mnemosyne-x_config.s"]:::cfgHeader
                MS-X_G_H.S["mnemosyne-x_general_h.s"]:::asmHeader
                MS-X_H.S["mnemosyne-x_h.s"]:::asmHeader
                MS-X_I_H.S["mnemosyne-x_internal_h.s"]:::asmHeader
                MS-X_D_H.S["mnemosyne-x_dirty_h.s"]:::asmDirtyHeader
            end

            MS-X.S["mnemosyne-x.s"]:::asmSource
            MS-X_SP.S["mnemosyne-x_standardpersistence"]:::asmSource
            MS-X_RM.S["mnemosyne-x_rammapper.s"]:::asmSource
            MS-X_D.S["mnemosyne-x_dirty.s"]:::asmDirtySource

            MS-X_G_H.S --> MS-X_C_H.S
            MS-X_H.S --> MS-X_G_H.S
            MS-X_I_H.S --> MS-X_G_H.S
            MS-X_I_H.S --> MS-X_RM_H.S

            MS-X_RM.S ~~~ MS-X_H.S
            MS-X.S --> MS-X_I_H.S
            MS-X_SP.S --> MS-X_I_H.S
            
            MS-X_D.S ~~~ Core_Headers

        end

        subgraph Misc
            PRINTDEC.H["printdec_h.s"]:::miscHeader
            PRINTINTERFACE.S["printinterface.s"]:::miscHeader
        end

        subgraph MnemoSyne-X_MDO
            subgraph MDO_Headers
                MSXBIOS.S["msxbios.s"]:::mdoHeader
                MDO-TARGETCONFIG.TXT["targetconfig.txt"]:::cfgHeader
                MDO-TARGETCONFIG.S["targetconfig.s"]:::mdoHeader
                MDO-APPLICATIONSETTINGS.TXT["applicationsettings.txt"]:::cfgHeader
                MDO-APPLICATIONSETTINGS.S["applicationsettings.s"]:::mdoHeader

                MDO-TARGETCONFIG.TXT ~~~ MSXBIOS.S
                MDO-TARGETCONFIG.S -.-o MDO-TARGETCONFIG.TXT
                MDO-APPLICATIONSETTINGS.TXT ~~~ MSXBIOS.S
                MDO-APPLICATIONSETTINGS.S -.-o MDO-APPLICATIONSETTINGS.TXT
            end

            MDO-CRT0["msxdosovlcrt0.s"]:::mdoSource
            MDO-MSXDOSOVL.S["msxdosovl.s"]:::mdoSource

            MDO-CRT0 ~~~ MDO-MSXDOSOVL.S
        end
        
        MnemoSyne-X_MDO ~~~ Misc

        MS-X_I_H.S --> |"All"| Misc
        MS-X_I_H.S --> MSXBIOS.S

        MDO-CRT0  --> |All| MDO_Headers
        MDO-MSXDOSOVL.S  --> |All| MDO_Headers
        MDO-MSXDOSOVL.S  --> PRINTINTERFACE.S

    end

    classDef cfgHeader fill:#f66
    classDef asmSource fill:#f96
    classDef asmHeader fill:#fda
    classDef asmDirtySource fill:#88f
    classDef asmDirtyHeader fill:#aaf
    classDef cSource fill:#f32
    classDef cHeader fill:#f23
    classDef mdoSource fill:#aaa
    classDef mdoHeader fill:#aaa
    
```
