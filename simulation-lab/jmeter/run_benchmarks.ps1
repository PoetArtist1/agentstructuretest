# Script de Automatizacion de Benchmarking con Apache JMeter (Windows PowerShell)
# Para ejecutar: .\run_benchmarks.ps1

# Configuracion del ejecutable de JMeter
$JMETER_CMD = "jmeter"

# Archivo de pruebas JMX y directorio de salida
$JMX_FILE = "agentstructure_benchmark.jmx"
$OUTPUT_DIR = "..\resultados-benchmark"

# Crear directorio de salida si no existe
if (-not (Test-Path $OUTPUT_DIR)) {
    New-Item -ItemType Directory -Force -Path $OUTPUT_DIR | Out-Null
}

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "   AUTOMATIZACION DE PRUEBAS DE RENDIMIENTO - JMETER      " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "Asegurese de que el entorno Docker este corriendo: docker-compose up -d" -ForegroundColor Yellow
Write-Host "y de tener jmeter en el PATH del sistema o configurado en este script." -ForegroundColor Yellow
Write-Host ""
Write-Host "El test contiene 2 grupos secuenciales:" -ForegroundColor Cyan
Write-Host "  1. Benchmark de operaciones normales - queries que funcionan OK" -ForegroundColor Cyan
Write-Host "  2. Prueba de limite de payload - get_clientes con 25K registros" -ForegroundColor Cyan
Write-Host ""

# Funcion para ejecutar una prueba
function Ejecutar-Prueba {
    param(
        [int]$hilos,
        [int]$rampup,
        [int]$loops,
        [string]$archivoSalida
    )

    $csvPath = Join-Path $OUTPUT_DIR "$archivoSalida.csv"
    $reportDir = Join-Path $OUTPUT_DIR "$archivoSalida-report"

    # Limpiar archivos anteriores
    if (Test-Path $csvPath) { Remove-Item $csvPath }
    if (Test-Path $reportDir) { Remove-Item -Recurse -Force $reportDir }

    Write-Host ">> Iniciando prueba con $hilos hilos concurrentes - $loops ciclos, rampup $rampup s..." -ForegroundColor Cyan
    Write-Host "   Incluye benchmark normal + prueba de limite de payload" -ForegroundColor DarkGray
    Write-Host "   Esto puede tardar ~2 minutos por la prueba de payload..." -ForegroundColor DarkGray

    # Comando JMeter en modo no-GUI
    $jmeterArgs = @(
        "-n",
        "-t", $JMX_FILE,
        "-l", $csvPath,
        "-e",
        "-o", $reportDir,
        "-Jthreads=$hilos",
        "-Jrampup=$rampup",
        "-Jloops=$loops",
        "-Jjmeter.reportgenerator.overall_granularity=100"
    )

    Start-Process -FilePath $JMETER_CMD -ArgumentList $jmeterArgs -NoNewWindow -Wait

    if (Test-Path $csvPath) {
        Write-Host "[OK] Prueba completada con exito. Resultados en: $csvPath" -ForegroundColor Green
        Write-Host "[OK] Reporte HTML generado en: $reportDir\index.html" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Error al ejecutar JMeter. Verifique la consola o jmeter.log." -ForegroundColor Red
    }
    Write-Host "----------------------------------------------------------"
}

# Rafaga 1: 10 peticiones simultaneas
Ejecutar-Prueba -hilos 10 -rampup 1 -loops 10 -archivoSalida "resultados_10_hilos"

# Rafaga 2: 50 peticiones simultaneas
Ejecutar-Prueba -hilos 50 -rampup 5 -loops 10 -archivoSalida "resultados_50_hilos"

# Rafaga 3: 100 peticiones simultaneas
Ejecutar-Prueba -hilos 100 -rampup 10 -loops 10 -archivoSalida "resultados_100_hilos"

# Rafaga 4: 1000 peticiones simultaneas
Ejecutar-Prueba -hilos 1000 -rampup 100 -loops 10 -archivoSalida "resultados_1000_hilos"

# Rafaga 5: 2000 peticiones simultaneas
Ejecutar-Prueba -hilos 2000 -rampup 200 -loops 10 -archivoSalida "resultados_2000_hilos"

Write-Host "Proceso de Benchmarking Finalizado." -ForegroundColor Green
Write-Host "Los archivos CSV y reportes se encuentran en: $OUTPUT_DIR" -ForegroundColor Green
