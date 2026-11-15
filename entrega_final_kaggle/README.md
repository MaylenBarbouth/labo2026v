# Entrega Final Competencia Kaggle - Modalidad Analista Junior (Edición 2026)

**Autora:** Maylén Barbouth  
**Archivo seleccionado manualmente en Kaggle (`Select 1/1`):** `KA_HIB_TRIPLE_1950.csv` (Corte: **1.950 envíos** | Public Score: **94.205**)

---

## 1. Resumen Ejecutivo de la Solución y Modificaciones Sustantivas

Partiendo de la arquitectura del workflow Senior de la cátedra (`z739_final_senior.ipynb`), se desarrolló un pipeline adaptado específicamente a la estructura de **55 columnas de la modalidad Analista Junior** (`analistajr_competencia_2026.csv.gz`), incorporando mejoras metodológicas basadas en el Libro de la Asignatura y en la evidencia de los Experimentos Colaborativos:

1. **Preprocesamiento y Limpieza de Variables Rotas:**
   * Reparación longitudinal en *Catastrophe Analysis* mediante interpolación temporal y ajuste monetario por índice de precios (`drift_deflacion`).
   * Exclusión explícita de identificadores y marcas temporales crudas (`numero_de_cliente` y `foto_mes`) del conjunto de variables predictoras (`campos_buenos`), conservando únicamente la estacionalidad cíclica (`kmes`), y desactivación de `AgregaVarRandomForest()` tras auditar que introducía particiones rígidas dependientes de `foto_mes`.

2. **Feature Engineering Intra-Mes:**
   * **Consolidación interna de tarjetas y actividad:** Tenencia activa (`vm_ctarjetas_activas`), volumen y monto transaccional unificado (`vm_ctrx_banco`, `vm_mconsumo_banco`), ticket medio (`vmr_ticket_medio_banco`) y ratios de utilización sobre límite y pago mínimo.
   * **Liquidez, endeudamiento y fricción:** Liquidez inmediata (`m_liquidez_cuentas`), ratio de ahorro sobre liquidez (`r_caja_ahorro_liquidez`), deuda consolidada (`m_deuda_total`), flujo de ingresos (`m_flujo_ingresos`), presión de deuda sobre saldo e ingresos (`r_deuda_sobre_saldo`, `r_deuda_sobre_ingresos`), rentabilidad/comisiones por producto y peso del mantenimiento sobre saldo (`r_mantenimiento_sobre_saldo`).
   * **Separadores de inactividad y precursores de baja:** Índice compuesto de inactividad (`score_inactividad`), operaciones totales del mes (`c_operaciones_mes`), giro en descubierto sin acuerdo previo (`r_descubierto_sin_acuerdo`, `m_descubierto_utilizado`), banderas de cierre administrativo de plásticos (`flag_tarjeta_en_cierre`) y antigüedad mínima de tarjetas (`vm_fechaalta_min`).

3. **Feature Engineering Histórico en C++ (`Rcpp`) y Reducción por Canaritos Asesinos:**
   * Lags y variaciones de orden 1 y 2 (`_lag1`, `_lag2`, `_delta1`, `_delta2`) combinados con regresión por cuadrados mínimos en C++ (`TendenciaYmuchomas`) sobre ventanas de **6 meses (`ventana = 6`)** y **3 meses (`ventana = 3`)**, incorporando pendientes (`_tend`), ratios sobre el promedio histórico propio del cliente (`_ratioavg`, inmunes a la inflación y al efecto aguinaldo) y medias móviles (`_avg`, Sección 17.8).
   * Selección de atributos mediante `CanaritosAsesinos` paralelizada (`feature_fraction = 0.5`, validación en `202107`), protegiendo las variables del mes actual para evitar la pérdida de predictores base.

4. **Optimización Bayesiana con *Early Stopping* e Hibridación de Semilleríos (Secciones 23.1, 23.2 y 25.2):**
   * Sustitución de la búsqueda a ciegas de `num_iterations` por detención temprana automática (`early_stopping_rounds = 200` con tope `2048`), optimizando simultáneamente estructura y regularización (`num_leaves`, `learning_rate`, `feature_fraction`, `min_data_in_leaf`, `min_sum_hessian_in_leaf`, `bagging_fraction`, `lambda_l1` y `lambda_l2`).
   * Implementación de una **Hibridación de 3 Semilleríos independientes (200 modelos LightGBM en total)** calibrados en escala *Log-Odds* estandarizada (`scale(logit(prob))`, Sección 25.2) para combinar tres resoluciones complementarias de árbol:
     * **`WF9102` (50 semillas, peso 40%):** Semilla primigenia `131071`. Árboles de resolución macro (`min_data_in_leaf = 2416`, `num_leaves = 102`) con ventana histórica de 6 meses (`_tend6`, `_ratioavg6`). `AUC` validación = `0.93664`.
     * **`WF9103` (50 semillas, peso 25%):** Semilla primigenia `415517`. Árboles de resolución micro (`min_data_in_leaf = 99`, `num_leaves = 77`) con rankings intra-mes cero-fijo (`_rk0`) y doble ventana de 3 y 6 meses. `AUC` validación = `0.93778`.
     * **`WF9104` (100 semillas, peso 35%):** Semilla primigenia `604001`. Optimización Bayesiana entrenada con el **100% de los datos (`training_pct = 1.0`)** y 80 iteraciones, incorporando medias móviles (`_avg3`, `_avg6`) y regularización por Hessiano (`min_data_in_leaf = 262`, `num_leaves = 345`, `589` árboles). `AUC` validación = `0.93871`.

---

## 2. Instrucciones de Reproducción Exacta

Para reproducir la solución completa desde el dataset original (`analistajr_competencia_2026.csv.gz`):

1. Ejecutar en orden los 3 notebooks de los semilleríos (cada uno crea su directorio `/content/buckets/b1/exp/WF910X/` y exporta su tabla de probabilidades promediadas `prediccion.txt`):
   * `01_WF9102.ipynb`
   * `02_WF9103.ipynb`
   * `03_WF9104.ipynb`
2. Ejecutar el script integrador **`04_hibridacion_triple_final.R`**, el cual lee los tres archivos `prediccion.txt`, aplica la estandarización *z-logit*, calcula el score híbrido (`0.40 * z2 + 0.25 * z3 + 0.35 * z4`) y genera el archivo final **`KA_HIB_TRIPLE_1950.csv`**.
   *(Nota: En la subcarpeta `predicciones_semillerios/` se incluyen los tres archivos `prediccion.txt` generados por los notebooks para permitir verificar la ejecución de `04_hibridacion_triple_final.R` en menos de 5 segundos).*
