import os
import glob
from siliconcompiler import ASIC, Design
from siliconcompiler.targets import freepdk45_demo

def main():
    # 1. Configurar el diseño y los archivos fuente
    design = Design('AINeuronX_N200_8x8_TOP')
    design.set_topmodule('AINeuronX_N200_8x8_TOP', fileset='rtl')

    # Buscar todos los archivos .sv y .SV dentro de src/ excluyendo testbenches
    sv_files = []
    for ext in ('*.sv', '*.SV'):
        sv_files.extend(glob.glob(f'src/**/{ext}', recursive=True))

    for f in sorted(set(sv_files)):
        filename = os.path.basename(f).upper()
        if '_TB' not in filename and 'TB_' not in filename:
            design.add_file(f, fileset='rtl', filetype='systemverilog')

    # Cargar restricciones de tiempo (250 MHz)
    design.add_file('constraints.sdc', fileset='sdc')

    # 2. Crear el proyecto ASIC y aplicar el objetivo FreePDK45 (Nangate 45nm)
    project = ASIC(design)
    project.add_fileset(['rtl', 'sdc'])
    freepdk45_demo(project)

    # 3. Parámetros de ejecución y densidad
    project.option.set_quiet(False)
    project.constraint.area.set_density(65)

    # 4. Ejecutar todo el flujo RTL -> GDSII
    project.run()

    # 5. Imprimir resumen de métricas (Área, Potencia, WNS)
    project.summary()

if __name__ == '__main__':
    main()
    
