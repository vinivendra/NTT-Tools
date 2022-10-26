# NTT-Tools

Tools for extracting and modding the NTT engine.

- **TSSFileListCSVReader**: used to read, process and filter a CSV list of files exported from [ProcessMonitor](https://learn.microsoft.com/en-us/sysinternals/downloads/procmon) (ProcMon). Useful for knowing what files are read when loading a particular level or location in the game.
- **TSSMaterialVisualizer**: used to turn NTT's `.MATERIAL` files into SVG files for better visualization and understanding of the shader graph.
- **TSSNormalMapConverter**: used to convert NTT's _derivative maps_ (the yellow-ish normal maps) into conventional (purple-ish) _normal maps_ that can be used with tools like blender.
- **TSSNXGTexturesExporter**: used to export the DDS files contained in an `.NXG_TEXTURE`.

