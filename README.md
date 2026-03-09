Description

This repository contains the code developed for the Master's Thesis:

"Impact of APOE gene polymorphisms on the clinical progression of Huntington’s disease"

The project analyses whole genome sequencing data to explore the relationship between genetic variants and disease progression using statistical analysis and machine learning approaches.

The workflow includes:

Genomic data preprocessing

Variant filtering

Genome-wide association analysis

Feature selection using explainable AI methods

Machine learning model evaluation

The objective is to identify genomic variants associated with differences in disease progression and evaluate their predictive relevance.

Data

The analysis is based on Whole Genome Sequencing (WGS) data.

Due to privacy and ethical restrictions, the genomic datasets used in this study are not included in this repository.

The repository only contains:

Scripts

Analysis notebooks

Configuration files

Documentation required to reproduce the analysis pipeline.

Methods

The analysis pipeline includes several stages:

1. Data preprocessing

Genomic variant data is processed and formatted for downstream analysis.

Steps include:

Quality filtering

Conversion to PLINK-compatible formats

Preparation of genotype matrices

2. Variant analysis

Genetic variants are analysed at the level of:

Single Nucleotide Polymorphisms (SNPs)

The aim is to identify variants potentially associated with clinical progression.

3. Feature selection

Feature importance is evaluated using:

SHapley Additive exPlanations (SHAP)

SHAP values allow interpreting the contribution of each genetic feature to the model predictions.

4. Model evaluation

Models are evaluated using standard classification metrics, including:

AUC-ROC (Area Under the Receiver Operating Characteristic Curve)

This metric measures the ability of the model to distinguish between classes.

Requirements

Typical dependencies include:

Python 3

numpy

pandas

scikit-learn

shap

matplotlib

seaborn

PLINK

Example workflow:

Prepare genotype data

Run preprocessing scripts

Execute variant analysis

Perform feature selection

Train and evaluate models

Author

Master's Thesis developed by:

Daniel de Lara Pérez

Master's Degree in Bioinformatics / Computational Biology
VIU

Year: 2026

License

This repository is intended for academic and research purposes.
