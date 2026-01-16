#!/bin/bash
# Ejecuta todos los scripts Python de prueba y genera heatmaps

echo "Ejecutando scripts Python de prueba..."
python3 python_api/test_kernel.py
python3 python_api/heatmap_visual.py

echo "Pruebas Python completadas. Revisar logs/ y heatmaps generados."
