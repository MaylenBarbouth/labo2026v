# Experimento Colaborativo - Grupo B (Modalidad Analista Junior)
## Estrategias de Validación: Hold-Out vs. Cross-Validation vs. Walk-Forward Validation

**Autora:** Maylén Barbouth  
**Modalidad:** Analista Junior (`analistajr_competencia_2026.csv.gz` - 55 columnas)  
**Período de evaluación (Grupo B):** `future = 202107` (con clase ternaria conocida para curva completa de ganancia suavizada)

---

### 1. Hipótesis y Diseño Experimental (Ceteris Paribus)

Se evalúa el impacto del esquema de validación durante el *Hyperparameter Tuning* (Grid Search sobre LightGBM optimizando `AUC` con `early_stopping_rounds = 200`) manteniendo estrictamente constantes el preprocesamiento (`Catastrophe Analysis = MachineLearning`, `Data Drifting = deflacion`), el *Feature Engineering* (`kmes`, `mpayroll_sobre_edad`, `lag1`, `lag2`, `delta1`, `delta2`) y el conjunto de entrenamiento final (`final_train = 201901..202105`), comparando en forma pareada sobre **10 semillas**:

* **`E0` (Baseline Hold-Out de la Cátedra):** Entrenamiento en `201901..202103` y validación en un único mes fijo (`202105`, dejando `202104` como mes puente).
* **`E1` (5-Fold Cross-Validation Agrupado por Cliente en Historia Completa):** Validación cruzada de 5 pliegues sobre `201901..202105` asignando todas las observaciones de un mismo `numero_de_cliente` al mismo pliegue para evitar fuga de información intra-cliente (*data leakage* por lags).
* **`E2` (Walk-Forward Validation Expansivo de 5 Pasos):** Promedio de 5 ventanas temporales expansivas (`Val = 202101, 202102, 202103, 202104, 202105`), respetando en cada corte un mes puente entre entrenamiento y validación.
* **`E3` y `E4` (Análisis de Sensibilidad en Régimen Reciente de 6 Meses):** Réplica de 5-Fold CV (`E3`) y Walk-Forward móvil (`E4`) restringiendo el entrenamiento exclusivamente a una ventana de 6 meses recientes (`202012..202105`).

---

### 2. Control Matemático de Grilla y Guardián Dinámico de Bordes

1. **Restricción de factibilidad estructural:** Se filtran las combinaciones redundantes donde `num_leaves * min_data_in_leaf > N_train_min`, evitando evaluar configuraciones truncadas por el tamaño muestral.
2. **Detección y Ampliación Dinámica de Bordes (`Generar_Expansion_Borde`):** Si para alguna semilla el hiperparámetro ganador (`num_leaves` o `min_data_in_leaf`) cae en el extremo inferior o superior de la grilla, el algoritmo expande automáticamente la frontera agregando un escalón centinela adicional y reevalúa hasta garantizar un óptimo interior (`alerta_borde == "OK"`).

---

### 3. Estructura de Archivos y Reproducción

* **`621_WorkFlow_01_junior_grupoB.R`**: Script principal autocontenido y reproducible. Ejecuta el preprocesamiento, el motor experimental de 10 semillas para `E0`, `E1`, `E2` (y la extensión de 6 meses `E3`, `E4`), genera las curvas de ganancia suavizada (media móvil centrada de ventana 400 en `202107`) y ejecuta los tests de los rangos con signo de **Wilcoxon pareados**.
* **`resumen_consolidado_10semillas.txt`**: Tabla maestra con los hiperparámetros óptimos, `AUC` de validación, ganancia máxima suavizada, envíos óptimos y auditoría de bordes para cada semilla y experimento.
