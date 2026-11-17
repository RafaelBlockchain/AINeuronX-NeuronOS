import os
import glob
import siliconcompiler

def main():
    # 1. Apuntar al módulo Top de 8x8
    chip = siliconcompiler.Chip('AINeuronX_N200_8x8_TOP')

    # 2. Cargar el PDK libre de 45 nm (Nangate 45nm)
    chip.load_target('freepdk45_demo')

    # 3. Buscar todos los archivos .sv y .SV dentro de src/ excluyendo testbenches
    sv_files = []
    for ext in ('*.sv', '*.SV'):
        sv_files.extend(glob.glob(f'src/**/{ext}', recursive=True))

    for f in sorted(set(sv_files)):
        filename = os.path.basename(f).upper()
        if '_TB' not in filename and 'TB_' not in filename:
            # Forzar filetype='systemverilog' activa Surelog para soportar 'int', 'always_ff' y '0
            chip.input(f, filetype='systemverilog')

    # 4. Cargar restricciones de 250 MHz
    chip.input('constraints.sdc')

    # 5. Parámetros de optimización
    chip.set('option', 'quiet', False)
    chip.set('constraint', 'density', 0.65)

    # 6. Ejecutar todo el flujo RTL -> GDSII
    chip.run()

    # 7. Imprimir tabla resumen de Área, Potencia y Timing (WNS)
    chip.summary()

if __name__ == '__main__':
    main()
    
