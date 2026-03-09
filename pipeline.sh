#!/bin/bash

set -e
set -o pipefail

# --- VARIABLES ---
RUN_ID=$1
SAMPLE=$2
PLATFORM=$3
LIBRARY_ID=$4
PLATFORM_UNIT=$5
REF=$6
R1=$7
R2=$8
THREADS=$9


echo "Sample: $SAMPLE"
echo "Referencia: $REF"
echo "Reads: $R1 $R2"
echo "Threads: $THREADS"

# --- 1. PREPARACIÓN DE CARPETAS ---
echo "--- Creando estructura de directorios ---"
mkdir -p results/reports/fastqc_raw
mkdir -p results/reports/fastqc_trimmed
mkdir -p results/reports/fastp
mkdir -p results/reports/multiqc
mkdir -p results/alignment
mkdir -p results/vcf
mkdir -p results/plink/logs
mkdir -p results/plink/chromosomes
mkdir -p results/reports/qualimap

# --- 2. QC INICIAL ---
echo "--- Paso 1: QC inicial con FastQC ---"
fastqc $R1 $R2 -o results/reports/fastqc_raw/

# --- 3. PRE-PROCESAMIENTO Y TRIMMING (fastp) ---
echo "--- Paso 2: Limpieza de lecturas con fastp ---"

fastp \
  -i $R1 -I $R2 \
  -o results/alignment/trimmed_fw.fastq \
  -O results/alignment/trimmed_rv.fastq \
  --detect_adapter_for_pe \
  -q 20 -u 30 \
  -h results/reports/fastp/fastp_report.html \
  -j results/reports/fastp/fastp_report.json

# --- 4. QC POST-TRIMMING ---
echo "--- Paso 3: QC después del trimming ---"

fastqc \
results/alignment/trimmed_fw.fastq \
results/alignment/trimmed_rv.fastq \
-o results/reports/fastqc_trimmed/

# --- 5. MULTIQC ---
echo "--- Paso 4: Generando reporte MultiQC ---"

multiqc results/reports/ -o results/reports/multiqc/

# --- 6. ALINEAMIENTO ---
echo "--- Paso 5: Alineamiento con BWA y ordenado ---"

bwa mem -t $THREADS \
-R "@RG\tID:${RUN_ID}\tSM:${SAMPLE}\tPL:${PLATFORM}\tLB:${LIBRARY_ID}\tPU:${PLATFORM_UNIT}" \
$REF \
results/alignment/trimmed_fw.fastq \
results/alignment/trimmed_rv.fastq | \
samtools sort -@ $THREADS -o results/alignment/sorted.bam

# --- 7. MARCADO DE DUPLICADOS ---
echo "--- Paso 6: Marcado de duplicados ---"

picard MarkDuplicates \
I=results/alignment/sorted.bam \
O=results/alignment/alineamiento_marcado.bam \
M=results/alignment/metrics.txt \
REMOVE_DUPLICATES=false

samtools index results/alignment/alineamiento_marcado.bam

# eliminar BAM intermedio
rm results/alignment/sorted.bam

# --- 7b. QC DEL MAPEO---
echo "--- Paso 7b: QC del alineamiento con Qualimap ---"

qualimap bamqc \
-bam results/alignment/alineamiento_marcado.bam \
-outdir results/reports/qualimap \
-nt $THREADS

# --- 8. VARIANT CALLING ---
echo "--- Paso 7: Llamada de variantes ---"

bcftools mpileup -Ou -f $REF results/alignment/alineamiento_marcado.bam | \
bcftools call -mv -Ov -o results/vcf/variantes_raw.vcf

# --- 9. FILTRADO DE VARIANTES ---
echo "--- Paso 8: Filtrado de variantes ---"

bcftools filter \
-e 'QUAL<30 || DP<10' \
results/vcf/variantes_raw.vcf \
-o results/vcf/variantes_filtradas.vcf

# --- 10. COMPRESIÓN E INDEXADO ---
echo "--- Paso 9: Compresión e indexado del VCF ---"

bgzip -c results/vcf/variantes_filtradas.vcf > results/vcf/variantes_filtradas.vcf.gz
tabix -p vcf results/vcf/variantes_filtradas.vcf.gz

# --- 11. CONVERSIÓN A PLINK ---
echo "--- Paso 10: Conversión a PLINK ---"

for chr in {1..22} X Y MT; do
  plink \
    --vcf results/vcf/variantes_filtradas.vcf.gz \
    --chr $chr \
    --make-bed \
    --out results/plink/chromosomes/plink_chr${chr} \
    --allow-extra-chr \
    --double-id \
    --silent
done

# --- 12. LIMPIEZA FINAL ---
mv results/plink/*.log results/plink/*.nosex results/plink/logs/ 2>/dev/null
sed -i 's/0 -9/1 2/g' results/plink/*.fam


echo "PIPELINE COMPLETADO!"
