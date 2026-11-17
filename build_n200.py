import glob
from siliconcompiler import ASIC, Design
from siliconcompiler.targets import freepdk45_demo

def find_file(pattern):
    matches = glob.glob(f'src/**/{pattern}', recursive=True)
    if not matches:
        raise FileNotFoundError(f'No se encontró el archivo requerido: {pattern}')
    return matches[0]

def main():
    # 1. Configurar el diseño y los archivos exactos del N200 8x8
    design = Design('AINeuronX_N200_8x8_TOP')
    design.set_topmodule('AINeuronX_N200_8x8_TOP', fileset='rtl')

    required_modules = [
        'AINeuronX_N200_8x8_TOP.sv',
        'AINeuronX_ARRAY_32x32_NOC.sv',
        'AINeuronX_TILE_XY.sv',
        'AINeuronX_N200_CORE.SV',
        'AINeuronX_NOC_ROUTER_XY.sv',
    ]

    for mod in required_modules:
        filepath = find_file(mod)
        design.add_file(filepath, fileset='rtl', filetype='systemverilog')

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
    
