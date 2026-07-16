#!/bin/bash
# Script de Automatización de Benchmarking con Apache JMeter (Linux/macOS)
# Para ejecutar: chmod +x run_benchmarks.sh && ./run_benchmarks.sh

JMETER_CMD="jmeter"
JMX_FILE="agentstructure_benchmark.jmx"
OUTPUT_DIR="../resultados-benchmark"

mkdir -p "$OUTPUT_DIR"

echo -e "\e[32m==========================================================\e[0m"
echo -e "\e[32m   AUTOMATIZACIÓN DE PRUEBAS DE RENDIMIENTO - JMETER      \e[0m"
echo -e "\e[32m==========================================================\e[0m"
echo -e "\e[33mAsegúrese de que el entorno Docker esté corriendo (docker-compose up -d)\e[0m"
echo -e "\e[33my de tener 'jmeter' en el PATH del sistema o configurado en este script.\e[0m"
echo ""

ejecutar_prueba() {
    local hilos=$1
    local rampup=$2
    local loops=$3
    local archivo_salida=$4

    local csv_path="$OUTPUT_DIR/$archivo_salida.csv"
    local report_dir="$OUTPUT_DIR/$archivo_salida-report"

    rm -f "$csv_path"
    rm -rf "$report_dir"

    echo -e "\e[36m>> Iniciando prueba con $hilos hilos concurrentes ($loops ciclos, rampup ${rampup}s)...\e[0m"

    $JMETER_CMD -n -t "$JMX_FILE" -l "$csv_path" -e -o "$report_dir" \
        -Jthreads="$hilos" -Jrampup="$rampup" -Jloops="$loops"

    if [ -f "$csv_path" ]; then
        echo -e "\e[32m✓ Prueba completada con éxito. Resultados en: $csv_path\e[0m"
        echo -e "\e[32m✓ Reporte HTML generado en: $report_dir/index.html\e[0m"
    else
        echo -e "\e[31m✗ Error al ejecutar JMeter. Verifique la consola o jmeter.log.\e[0m"
    fi
    echo "----------------------------------------------------------"
}

# Ráfaga 1: 10 peticiones simultáneas
ejecutar_prueba 10 1 10 "resultados_10_hilos"

# Ráfaga 2: 50 peticiones simultáneas
ejecutar_prueba 50 5 10 "resultados_50_hilos"

# Ráfaga 3: 100 peticiones simultáneas
ejecutar_prueba 100 10 10 "resultados_100_hilos"

echo -e "\e[32mProceso de Benchmarking Finalizado.\e[0m"
echo -e "\e[32mLos archivos CSV y reportes interactivos HTML se encuentran en: $OUTPUT_DIR\e[0m"
