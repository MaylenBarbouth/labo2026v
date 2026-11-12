# ==============================================================================
# 621_WorkFlow_01_junior_grupoB.R
# Experimento Colaborativo - Grupo B (Modalidad Analista Jr, futuro = 202107)
# Comparacion Ceteris Paribus: E0 (Hold-Out), E1 (5-Fold CV Cliente), E2 (WFV)
# y Analisis de Sensibilidad en 6 Meses: E3 (CV 6m) y E4 (WFV 6m)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. INICIALIZACION Y PARAMETROS GLOBALES
# ------------------------------------------------------------------------------
format(Sys.time(), "%a %b %d %X %Y")

rm(list = ls(all.names = TRUE))
gc(full = TRUE, verbose = FALSE)

require("data.table")
if (!require("R.utils")) install.packages("R.utils")
require("R.utils")
if (!require("lightgbm")) install.packages("lightgbm")
require("lightgbm")
if (!require("yaml")) install.packages("yaml")
require("yaml")

PARAM <- list()
PARAM$semilla_primigenia <- 131071
PARAM$experimento <- 91111
PARAM$dataset <- "analistajr_competencia_2026.csv.gz"

setwd("/content/buckets/b1/exp")
experimento_folder <- paste0("WF", PARAM$experimento)
dir.create(experimento_folder, showWarnings = FALSE)
setwd(paste0("/content/buckets/b1/exp/", experimento_folder))

# ------------------------------------------------------------------------------
# 2. PREPROCESAMIENTO DEL DATASET (IDENTICO AL BASELINE DE LA CATEDRA)
# ------------------------------------------------------------------------------
archivo_fe <- "/content/buckets/b1/exp/dataset_fe_grupoB.csv.gz"

if (!file.exists(archivo_fe)) {
  cat("Ejecutando preprocesamiento y Feature Engineering desde el dataset original...\n")
  dataset <- fread(paste0("/content/datasets/", PARAM$dataset))
  
  # 2.1 Catastrophe Analysis (Metodo MachineLearning: asigna NA a meses rotos)
  AsignarNA_campomeses <- function(pcampo, pmeses) {
    if (pcampo %in% colnames(dataset)) {
      dataset[foto_mes %in% pmeses, paste0(pcampo) := NA]
    }
  }
  
  Corregir_atributo <- function(pcampo, pmeses, pmetodo) {
    if (!(pcampo %in% colnames(dataset))) return(1)
    if (pmetodo == "MachineLearning") AsignarNA_campomeses(pcampo, pmeses)
    return(0)
  }
  
  Corregir_Rotas <- function(dataset, pmetodo) {
    gc(verbose = FALSE)
    Corregir_atributo("active_quarter", c(202006), pmetodo)
    Corregir_atributo("internet", c(202006), pmetodo)
    Corregir_atributo("mrentabilidad", c(201905, 201910, 202006), pmetodo)
    Corregir_atributo("mrentabilidad_annual", c(201905, 201910, 202006), pmetodo)
    Corregir_atributo("mcomisiones", c(201905, 201910, 202006), pmetodo)
    Corregir_atributo("mactivos_margen", c(201905, 201910, 202006), pmetodo)
    Corregir_atributo("mpasivos_margen", c(201905, 201910, 202006), pmetodo)
    Corregir_atributo("mcuentas_saldo", c(202006), pmetodo)
    Corregir_atributo("ctarjeta_debito_transacciones", c(202006), pmetodo)
    Corregir_atributo("mautoservicio", c(202006), pmetodo)
    Corregir_atributo("ctarjeta_visa_transacciones", c(202006), pmetodo)
    Corregir_atributo("mtarjeta_visa_consumo", c(202006), pmetodo)
    Corregir_atributo("ctarjeta_master_transacciones", c(202006), pmetodo)
    Corregir_atributo("mtarjeta_master_consumo", c(202006), pmetodo)
    Corregir_atributo("ctarjeta_visa_debitos_automaticos", c(201904), pmetodo)
    Corregir_atributo("mttarjeta_visa_debitos_automaticos", c(201904), pmetodo)
    Corregir_atributo("ccajeros_propios_descuentos", c(201910, 202002, 202006, 202009, 202010, 202102), pmetodo)
    Corregir_atributo("mcajeros_propios_descuentos", c(201910, 202002, 202006, 202009, 202010, 202102), pmetodo)
    Corregir_atributo("ctarjeta_visa_descuentos", c(201910, 202002, 202006, 202009, 202010, 202102), pmetodo)
    Corregir_atributo("mtarjeta_visa_descuentos", c(201910, 202002, 202006, 202009, 202010, 202102), pmetodo)
    Corregir_atributo("ctarjeta_master_descuentos", c(201910, 202002, 202006, 202009, 202010, 202102), pmetodo)
    Corregir_atributo("mtarjeta_master_descuentos", c(201910, 202002, 202006, 202009, 202010, 202102), pmetodo)
    Corregir_atributo("ccomisiones_otras", c(201905, 201910, 202006), pmetodo)
    Corregir_atributo("mcomisiones_otras", c(201905, 201910, 202006), pmetodo)
    Corregir_atributo("cextraccion_autoservicio", c(202006), pmetodo)
    Corregir_atributo("mextraccion_autoservicio", c(202006), pmetodo)
    Corregir_atributo("ccheques_depositados", c(202006), pmetodo)
    Corregir_atributo("mcheques_depositados", c(202006), pmetodo)
    Corregir_atributo("ccheques_emitidos", c(202006), pmetodo)
    Corregir_atributo("mcheques_emitidos", c(202006), pmetodo)
    Corregir_atributo("ccheques_depositados_rechazados", c(202006), pmetodo)
    Corregir_atributo("mcheques_depositados_rechazados", c(202006), pmetodo)
    Corregir_atributo("ccheques_emitidos_rechazados", c(202006), pmetodo)
    Corregir_atributo("mcheques_emitidos_rechazados", c(202006), pmetodo)
    Corregir_atributo("tcallcenter", c(202006), pmetodo)
    Corregir_atributo("ccallcenter_transacciones", c(202006), pmetodo)
    Corregir_atributo("thomebanking", c(202006), pmetodo)
    Corregir_atributo("chomebanking_transacciones", c(201910, 202006), pmetodo)
    Corregir_atributo("ccajas_transacciones", c(202006), pmetodo)
    Corregir_atributo("ccajas_consultas", c(202006), pmetodo)
    Corregir_atributo("ccajas_depositos", c(202006, 202105), pmetodo)
    Corregir_atributo("ccajas_extracciones", c(202006), pmetodo)
    Corregir_atributo("ccajas_otras", c(202006), pmetodo)
    Corregir_atributo("catm_trx", c(202006), pmetodo)
    Corregir_atributo("matm", c(202006), pmetodo)
    Corregir_atributo("catm_trx_other", c(202006), pmetodo)
    Corregir_atributo("matm_other", c(202006), pmetodo)
  }
  
  setorder(dataset, numero_de_cliente, foto_mes)
  PARAM$CA$metodo <- "MachineLearning"
  Corregir_Rotas(dataset, PARAM$CA$metodo)
  
  # 2.2 Data Drifting (Deflacion por IPC)
  vfoto_mes <- c(
    201901, 201902, 201903, 201904, 201905, 201906,
    201907, 201908, 201909, 201910, 201911, 201912,
    202001, 202002, 202003, 202004, 202005, 202006,
    202007, 202008, 202009, 202010, 202011, 202012,
    202101, 202102, 202103, 202104, 202105, 202106,
    202107, 202108, 202109
  )
  vIPC <- c(
    1.9903030878, 1.9174403544, 1.8296186587, 1.7728862972, 1.7212488323, 1.6776304408,
    1.6431248196, 1.5814483345, 1.4947526791, 1.4484037589, 1.3913580777, 1.3404220402,
    1.3154288912, 1.2921698342, 1.2472681797, 1.2300475145, 1.2118694724, 1.1881073259,
    1.1693969743, 1.1375456949, 1.1065619600, 1.0681100000, 1.0370000000, 1.0000000000,
    0.9680542110, 0.9344152616, 0.8882274350, 0.8532444140, 0.8251880213, 0.8003763543,
    0.7763107219, 0.7566381305, 0.7289384687
  )
  tb_indices <- data.table(foto_mes = vfoto_mes, IPC = vIPC)
  campos_monetarios <- colnames(dataset)[colnames(dataset) %like% "^(m|Visa_m|Master_m|vm_m)"]
  
  dataset[tb_indices, on = "foto_mes", (campos_monetarios) := .SD * i.IPC, .SDcols = campos_monetarios]
  
  # 2.3 Feature Engineering Intra-Mes (Base Catedra Junior)
  dataset[, kmes := foto_mes %% 100]
  dataset[, mpayroll_sobre_edad := mpayroll / cliente_edad]
  
  # 2.4 Feature Engineering Historico (Lags 1 y 2 + Deltas 1 y 2)
  cols_lagueables <- copy(setdiff(colnames(dataset), c("numero_de_cliente", "foto_mes", "clase_ternaria")))
  dataset[, paste0(cols_lagueables, "_lag1") := shift(.SD, 1, NA, "lag"), by = numero_de_cliente, .SDcols = cols_lagueables]
  dataset[, paste0(cols_lagueables, "_lag2") := shift(.SD, 2, NA, "lag"), by = numero_de_cliente, .SDcols = cols_lagueables]
  for (vcol in cols_lagueables) {
    dataset[, paste0(vcol, "_delta1") := get(vcol) - get(paste0(vcol, "_lag1"))]
    dataset[, paste0(vcol, "_delta2") := get(vcol) - get(paste0(vcol, "_lag2"))]
  }
  
  fwrite(dataset, file = archivo_fe)
  cat("Dataset preprocesado guardado en:", archivo_fe, "\n")
} else {
  cat("Cargando dataset preprocesado desde el disco...\n")
  dataset <- fread(archivo_fe)
}

# ==============================================================================
# 3. MOTOR EXPERIMENTAL DEFINITIVO (10 SEMILLAS PAREADAS): E0, E1 y E2
# Grilla Informada (48 comb.) + Guardian Dinamico de Bordes + Test de Wilcoxon
# ==============================================================================
dir_resultados <- "/content/buckets/b1/exp/WF_Experimentos_GrupoB"
dir.create(dir_resultados, showWarnings = FALSE, recursive = TRUE)
setwd(dir_resultados)

archivo_log <- "progreso_ejecucion.log"
log_info <- function(...) {
  msg <- paste0("[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] ", paste(..., collapse = " "), "\n")
  cat(msg)
  flush.console()
  cat(msg, file = archivo_log, append = TRUE)
}

PARAM$trainingstrategy$positivos <- c("BAJA+1", "BAJA+2")
dataset[, clase01 := ifelse(clase_ternaria %in% PARAM$trainingstrategy$positivos, 1, 0)]

campos_buenos <- copy(setdiff(
  colnames(dataset),
  c("clase_ternaria", "clase01", "azar", "fold_train", "fold_final_train")
))

PARAM$trainingstrategy$final_train <- c(
  201901, 201902, 201903, 201904, 201905, 201906,
  201907, 201908, 201909, 201910, 201911, 201912,
  202001, 202002, 202003, 202004, 202005, 202006,
  202007, 202008, 202009, 202010, 202011, 202012,
  202101, 202102, 202103, 202104, 202105
)
PARAM$trainingstrategy$future <- c(202107)

# Vector de 10 semillas pareadas para el bloque principal (E0, E1, E2)
VECTOR_SEMILLAS <- c(
  131071, 415517, 314159, 104729, 999961, 163741, 195401, 751643, 959473, 983327
)
SEMILLAS_A_CORRER <- VECTOR_SEMILLAS
EXPERIMENTOS_A_CORRER <- c("E0", "E1", "E2")

# Diseno de grillas (Base Catedra para E0 | Optima Acotada para E1 y E2)
n_train_min <- nrow(dataset[foto_mes >= 201901 & foto_mes <= 202011])
TOPE_MATEMATICO <- min(524288L, n_train_min)

tb_grilla_e0 <- CJ(
  num_leaves = c(64, 128, 256, 384, 512),
  min_data_in_leaf = c(64, 256, 512, 1024, 2048),
  feature_fraction = c(0.5, 0.8)
)

tb_grilla_optima <- CJ(
  num_leaves = c(16, 32, 64, 128, 256),
  min_data_in_leaf = c(256, 512, 1024, 2048, 4096),
  feature_fraction = c(0.5, 0.8)
)[(num_leaves * min_data_in_leaf) <= TOPE_MATEMATICO]

# Funciones auxiliares de evaluacion y Guardian Dinamico de Bordes
Verificar_Bordes <- function(mejor_hp, grilla, tope_iter = 2048) {
  alertas <- c()
  if (mejor_hp$num_leaves %in% range(grilla$num_leaves)) {
    alertas <- c(alertas, paste0("num_leaves=", mejor_hp$num_leaves))
  }
  if (mejor_hp$min_data_in_leaf %in% range(grilla$min_data_in_leaf)) {
    alertas <- c(alertas, paste0("min_data_in_leaf=", mejor_hp$min_data_in_leaf))
  }
  if (mejor_hp$num_iterations >= (tope_iter * 0.95)) {
    alertas <- c(alertas, paste0("num_iterations=", mejor_hp$num_iterations))
  }
  if (length(alertas) > 0) return(paste(alertas, collapse = " | "))
  return("OK")
}

Generar_Expansion_Borde <- function(mejor_hp, grilla_actual, tope_mat) {
  nuevos_L <- unique(grilla_actual$num_leaves)
  nuevos_M <- unique(grilla_actual$min_data_in_leaf)
  min_L <- min(nuevos_L); max_L <- max(nuevos_L)
  min_M <- min(nuevos_M); max_M <- max(nuevos_M)
  
  if (mejor_hp$num_leaves == min_L && min_L > 8) {
    nuevos_L <- sort(unique(c(nuevos_L, as.integer(min_L / 2))))
  }
  if (mejor_hp$num_leaves == max_L && max_L < 512) {
    sig_L <- ifelse(max_L == 256, 384L, 512L)
    nuevos_L <- sort(unique(c(nuevos_L, sig_L)))
  }
  if (mejor_hp$min_data_in_leaf == min_M && min_M > 64) {
    nuevos_M <- sort(unique(c(nuevos_M, as.integer(min_M / 2))))
  }
  if (mejor_hp$min_data_in_leaf == max_M && max_M < 16384) {
    nuevos_M <- sort(unique(c(nuevos_M, as.integer(max_M * 2))))
  }
  
  tb_candidata <- CJ(
    num_leaves = nuevos_L,
    min_data_in_leaf = nuevos_M,
    feature_fraction = c(0.5, 0.8)
  )[(num_leaves * min_data_in_leaf) <= tope_mat]
  
  tb_nuevas_filas <- tb_candidata[!grilla_actual, on = c("num_leaves", "min_data_in_leaf", "feature_fraction")]
  return(tb_nuevas_filas)
}

Estimar_AUC_HoldOut <- function(x, dtrain_actual, dval_actual, param_fijos_actual) {
  param_completo <- modifyList(param_fijos_actual, x)
  modelo_train <- lgb.train(
    data = dtrain_actual, valids = list(valid = dval_actual),
    eval = "auc", param = param_completo, verbose = -100
  )
  AUC <- modelo_train$record_evals$valid$auc$eval[[modelo_train$best_iter]]
  niter <- modelo_train$best_iter
  rm(modelo_train); gc(full = TRUE, verbose = FALSE)
  return(list(AUC, niter))
}

Estimar_AUC_CV <- function(x, dcv_actual, folds_actual, param_fijos_actual) {
  param_completo <- modifyList(param_fijos_actual, x)
  modelo_cv <- lgb.cv(
    data = dcv_actual, folds = folds_actual,
    eval = "auc", param = param_completo, verbose = -100
  )
  AUC <- modelo_cv$record_evals$valid$auc$eval[[modelo_cv$best_iter]]
  niter <- modelo_cv$best_iter
  rm(modelo_cv); gc(full = TRUE, verbose = FALSE)
  return(list(AUC, niter))
}

Evaluar_Subgrilla <- function(tb_a_evaluar, exp_id, semilla_actual, param_fijos) {
  if (nrow(tb_a_evaluar) == 0) return(tb_a_evaluar)
  tb_res <- copy(tb_a_evaluar)
  
  if (exp_id == "E0") {
    meses_train <- PARAM$trainingstrategy$final_train[1:27] # 201901 a 202103
    mes_val <- c(202105)
    dtrain <- lgb.Dataset(data = data.matrix(dataset[foto_mes %in% meses_train, campos_buenos, with = FALSE]),
                          label = dataset[foto_mes %in% meses_train, clase01], free_raw_data = TRUE)
    dvalidate <- lgb.Dataset(data = data.matrix(dataset[foto_mes %in% mes_val, campos_buenos, with = FALSE]),
                             label = dataset[foto_mes %in% mes_val, clase01], free_raw_data = TRUE)
    tb_res[, c("AUC", "num_iterations") := Estimar_AUC_HoldOut(.SD, dtrain, dvalidate, param_fijos), by = 1:nrow(tb_res)]
    rm(dtrain, dvalidate); gc(full = TRUE, verbose = FALSE)
  }
  
  if (exp_id == "E1") {
    meses_cv <- PARAM$trainingstrategy$final_train
    idx_cv <- which(dataset$foto_mes %in% meses_cv)
    set.seed(semilla_actual, kind = "L'Ecuyer-CMRG")
    clientes_unicos <- unique(dataset$numero_de_cliente[idx_cv])
    asignacion_folds <- sample(rep(1:5, length.out = length(clientes_unicos)))
    fold_por_fila <- asignacion_folds[match(dataset$numero_de_cliente[idx_cv], clientes_unicos)]
    lista_folds <- split(seq_along(idx_cv), fold_por_fila)
    dcv <- lgb.Dataset(data = data.matrix(dataset[idx_cv, campos_buenos, with = FALSE]),
                       label = dataset$clase01[idx_cv], free_raw_data = TRUE)
    tb_res[, c("AUC", "num_iterations") := Estimar_AUC_CV(.SD, dcv, lista_folds, param_fijos), by = 1:nrow(tb_res)]
    rm(dcv, lista_folds, fold_por_fila, clientes_unicos, idx_cv); gc(full = TRUE, verbose = FALSE)
  }
  
  if (exp_id == "E2") {
    todos_meses <- PARAM$trainingstrategy$final_train
    meses_val_wfv <- c(202101, 202102, 202103, 202104, 202105)
    archivo_e0 <- paste0("tb_grid_E0_sem_", semilla_actual, ".txt")
    if (file.exists(archivo_e0)) {
      tb_e0 <- fread(archivo_e0)
      tb_res[tb_e0, on = c("num_leaves", "min_data_in_leaf", "feature_fraction"),
             c("AUC_p5", "niter_p5") := list(i.AUC, i.num_iterations)]
    }
    for (p in seq_along(meses_val_wfv)) {
      val_m <- meses_val_wfv[p]
      col_auc <- paste0("AUC_p", p); col_nit <- paste0("niter_p", p)
      idx_pend <- if (col_auc %in% colnames(tb_res)) which(is.na(tb_res[[col_auc]])) else seq_len(nrow(tb_res))
      if (length(idx_pend) == 0) next
      pos_val <- match(val_m, todos_meses)
      train_m <- todos_meses[1:(pos_val - 2)]
      dtrain <- lgb.Dataset(data = data.matrix(dataset[foto_mes %in% train_m, campos_buenos, with = FALSE]),
                            label = dataset[foto_mes %in% train_m, clase01], free_raw_data = TRUE)
      dvalidate <- lgb.Dataset(data = data.matrix(dataset[foto_mes == val_m, campos_buenos, with = FALSE]),
                               label = dataset[foto_mes == val_m, clase01], free_raw_data = TRUE)
      tb_res[idx_pend, c(col_auc, col_nit) := Estimar_AUC_HoldOut(
        .SD[, .(num_leaves, min_data_in_leaf, feature_fraction)], dtrain, dvalidate, param_fijos
      ), by = seq_along(idx_pend)]
      rm(dtrain, dvalidate); gc(full = TRUE, verbose = FALSE)
    }
    tb_res[, AUC := (AUC_p1 + AUC_p2 + AUC_p3 + AUC_p4 + AUC_p5) / 5]
    tb_res[, num_iterations := as.integer(round((niter_p1 + niter_p2 + niter_p3 + niter_p4 + niter_p5) / 5))]
  }
  return(tb_res)
}

# Bucle de ejecucion para E0, E1 y E2 (10 semillas)
archivo_resumen <- "resumen_maestro_experimentos.txt"

for (semilla_actual in SEMILLAS_A_CORRER) {
  PARAM$lgbm$param_fijos <- list(
    objective = "binary", metric = "auc", first_metric_only = TRUE, boost_from_average = TRUE,
    feature_pre_filter = FALSE, verbosity = -100, force_row_wise = TRUE, seed = semilla_actual,
    max_bin = 31, learning_rate = 0.03, feature_fraction = 0.5, num_iterations = 2048,
    early_stopping_rounds = 200, num_leaves = 64, min_data_in_leaf = 128
  )
  
  for (exp_id in EXPERIMENTOS_A_CORRER) {
    archivo_grid_exp <- paste0("tb_grid_", exp_id, "_sem_", semilla_actual, ".txt")
    archivo_pred_exp <- paste0("prediccion_", exp_id, "_sem_", semilla_actual, ".txt")
    if (file.exists(archivo_pred_exp)) next
    
    grilla_objetivo <- if (exp_id == "E0") copy(tb_grilla_e0) else copy(tb_grilla_optima)
    tb_acumulada <- Evaluar_Subgrilla(grilla_objetivo, exp_id, semilla_actual, PARAM$lgbm$param_fijos)
    setorder(tb_acumulada, -AUC)
    fwrite(tb_acumulada, file = archivo_grid_exp, sep = "\t")
    
    mejores_hp <- as.list(tb_acumulada[1, .(num_leaves, min_data_in_leaf, feature_fraction, num_iterations)])
    estado_borde <- Verificar_Bordes(mejores_hp, tb_acumulada, PARAM$lgbm$param_fijos$num_iterations)
    
    # Guardian Dinamico de Bordes
    ronda_guardian <- 1
    while (exp_id %in% c("E1", "E2") && estado_borde != "OK" && ronda_guardian <= 2) {
      tb_exp_borde <- Generar_Expansion_Borde(mejores_hp, tb_acumulada, TOPE_MATEMATICO)
      if (nrow(tb_exp_borde) == 0) break
      tb_borde_eval <- Evaluar_Subgrilla(tb_exp_borde, exp_id, semilla_actual, PARAM$lgbm$param_fijos)
      tb_acumulada <- rbindlist(list(tb_acumulada, tb_borde_eval), use.names = TRUE, fill = TRUE)
      setorder(tb_acumulada, -AUC)
      fwrite(tb_acumulada, file = archivo_grid_exp, sep = "\t")
      mejores_hp <- as.list(tb_acumulada[1, .(num_leaves, min_data_in_leaf, feature_fraction, num_iterations)])
      estado_borde <- Verificar_Bordes(mejores_hp, tb_acumulada, PARAM$lgbm$param_fijos$num_iterations)
      ronda_guardian <- ronda_guardian + 1
    }
    
    # Entrenamiento Final (201901..202105) y Scoring en Future (202107)
    dfinal_train <- lgb.Dataset(
      data = data.matrix(dataset[foto_mes %in% PARAM$trainingstrategy$final_train, campos_buenos, with = FALSE]),
      label = dataset[foto_mes %in% PARAM$trainingstrategy$final_train, clase01], free_raw_data = TRUE
    )
    fijos <- copy(PARAM$lgbm$param_fijos)
    fijos$num_iterations <- NULL; fijos$early_stopping_rounds <- NULL
    param_final <- c(fijos, mejores_hp)
    final_model <- lgb.train(data = dfinal_train, param = param_final, verbose = -100)
    
    dfuture <- dataset[foto_mes %in% PARAM$trainingstrategy$future]
    prediccion <- predict(final_model, data.matrix(dfuture[, campos_buenos, with = FALSE]))
    tb_prediccion <- dfuture[, list(numero_de_cliente, clase_ternaria, prob = prediccion)]
    fwrite(tb_prediccion, file = archivo_pred_exp, sep = "\t")
    
    tb_prediccion[, ganancia := ifelse(clase_ternaria == "BAJA+2", 0.975, -0.025)]
    setorder(tb_prediccion, -prob)
    tb_prediccion[, gan_suavizada := frollmean(cumsum(ganancia), n = 400, align = "center", na.rm = TRUE, has.nf = TRUE)]
    
    fila_resumen <- data.table(
      experimento = exp_id, semilla = semilla_actual, AUC_validacion = tb_acumulada[1, AUC],
      num_leaves = mejores_hp$num_leaves, min_data_in_leaf = mejores_hp$min_data_in_leaf,
      feature_fraction = mejores_hp$feature_fraction, num_iterations = mejores_hp$num_iterations,
      ganancia_suavizada_max = max(tb_prediccion$gan_suavizada, na.rm = TRUE),
      envios = which.max(tb_prediccion$gan_suavizada), alerta_borde = estado_borde,
      fecha_hora = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    )
    fwrite(fila_resumen, file = archivo_resumen, sep = "\t", append = file.exists(archivo_resumen))
    rm(dfinal_train, final_model, dfuture, tb_prediccion, prediccion, tb_acumulada)
    gc(full = TRUE, verbose = FALSE)
  }
}

# ==============================================================================
# 4. EXTENSION EXPERIMENTAL: E3 (CV 6 MESES) Y E4 (WFV 6 MESES) - 10 SEMILLAS
# ==============================================================================
todos_meses <- PARAM$trainingstrategy$final_train
n_train_6m <- nrow(dataset[foto_mes >= 202006 & foto_mes <= 202011])

tb_grilla_6m <- CJ(
  num_leaves = c(8, 16, 32, 64, 128, 256, 384, 512),
  min_data_in_leaf = c(32, 64, 256, 512, 1024, 2048, 4096, 8192),
  feature_fraction = c(0.5, 0.8)
)[(num_leaves * min_data_in_leaf) <= n_train_6m]

VECTOR_SEMILLAS_6M <- c(102191, 200177, 410551, 500741, 600881, 700999, 801107, 901213, 104729, 350377)

for (semilla_actual in VECTOR_SEMILLAS_6M) {
  PARAM$lgbm$param_fijos$seed <- semilla_actual
  for (exp_id in c("E3", "E4")) {
    archivo_grid <- paste0("tb_grid_", exp_id, "_sem_", semilla_actual, ".txt")
    archivo_pred <- paste0("prediccion_", exp_id, "_sem_", semilla_actual, ".txt")
    if (file.exists(archivo_pred)) next
    
    tb_nueva <- copy(tb_grilla_6m)
    if (exp_id == "E3") {
      meses_cv_6m <- c(202012, 202101, 202102, 202103, 202104, 202105)
      idx_cv <- which(dataset$foto_mes %in% meses_cv_6m)
      set.seed(semilla_actual, kind = "L'Ecuyer-CMRG")
      clientes_unicos <- unique(dataset$numero_de_cliente[idx_cv])
      asignacion_folds <- sample(rep(1:5, length.out = length(clientes_unicos)))
      fold_por_fila <- asignacion_folds[match(dataset$numero_de_cliente[idx_cv], clientes_unicos)]
      lista_folds <- split(seq_along(idx_cv), fold_por_fila)
      dcv <- lgb.Dataset(data = data.matrix(dataset[idx_cv, campos_buenos, with = FALSE]), label = dataset$clase01[idx_cv], free_raw_data = TRUE)
      tb_nueva[, c("AUC", "num_iterations") := Estimar_AUC_CV(.SD, dcv, lista_folds, PARAM$lgbm$param_fijos), by = 1:nrow(tb_nueva)]
      rm(dcv, lista_folds, fold_por_fila, clientes_unicos, idx_cv); gc(full = TRUE, verbose = FALSE)
    }
    if (exp_id == "E4") {
      meses_val_wfv <- c(202101, 202102, 202103, 202104, 202105)
      for (p in seq_along(meses_val_wfv)) {
        val_m <- meses_val_wfv[p]; pos_val <- match(val_m, todos_meses)
        train_m <- todos_meses[(pos_val - 7):(pos_val - 2)]
        dtrain <- lgb.Dataset(data = data.matrix(dataset[foto_mes %in% train_m, campos_buenos, with = FALSE]), label = dataset[foto_mes %in% train_m, clase01], free_raw_data = TRUE)
        dvalidate <- lgb.Dataset(data = data.matrix(dataset[foto_mes == val_m, campos_buenos, with = FALSE]), label = dataset[foto_mes == val_m, clase01], free_raw_data = TRUE)
        tb_nueva[, c(paste0("AUC_p", p), paste0("niter_p", p)) := Estimar_AUC_HoldOut(.SD, dtrain, dvalidate, PARAM$lgbm$param_fijos), by = 1:nrow(tb_nueva)]
        rm(dtrain, dvalidate); gc(full = TRUE, verbose = FALSE)
      }
      tb_nueva[, AUC := (AUC_p1 + AUC_p2 + AUC_p3 + AUC_p4 + AUC_p5) / 5]
      tb_nueva[, num_iterations := as.integer(round((niter_p1 + niter_p2 + niter_p3 + niter_p4 + niter_p5) / 5))]
    }
    setorder(tb_nueva, -AUC); fwrite(tb_nueva, file = archivo_grid, sep = "\t")
    mejores_hp <- as.list(tb_nueva[1, .(num_leaves, min_data_in_leaf, feature_fraction, num_iterations)])
    estado_borde <- Verificar_Bordes(mejores_hp, tb_grilla_6m, PARAM$lgbm$param_fijos$num_iterations)
    
    final_train_6m <- c(202012, 202101, 202102, 202103, 202104, 202105)
    dfinal_train <- lgb.Dataset(data = data.matrix(dataset[foto_mes %in% final_train_6m, campos_buenos, with = FALSE]), label = dataset[foto_mes %in% final_train_6m, clase01], free_raw_data = TRUE)
    fijos <- copy(PARAM$lgbm$param_fijos); fijos$num_iterations <- NULL; fijos$early_stopping_rounds <- NULL
    final_model <- lgb.train(data = dfinal_train, param = c(fijos, mejores_hp), verbose = -100)
    
    dfuture <- dataset[foto_mes %in% PARAM$trainingstrategy$future]
    prediccion <- predict(final_model, data.matrix(dfuture[, campos_buenos, with = FALSE]))
    tb_prediccion <- dfuture[, list(numero_de_cliente, clase_ternaria, prob = prediccion)]
    fwrite(tb_prediccion, file = archivo_pred, sep = "\t")
    tb_prediccion[, ganancia := ifelse(clase_ternaria == "BAJA+2", 0.975, -0.025)]
    setorder(tb_prediccion, -prob)
    tb_prediccion[, gan_suavizada := frollmean(cumsum(ganancia), n = 400, align = "center", na.rm = TRUE, has.nf = TRUE)]
    
    fila_resumen <- data.table(
      experimento = exp_id, semilla = semilla_actual, AUC_validacion = tb_nueva[1, AUC],
      num_leaves = mejores_hp$num_leaves, min_data_in_leaf = mejores_hp$min_data_in_leaf,
      feature_fraction = mejores_hp$feature_fraction, num_iterations = mejores_hp$num_iterations,
      ganancia_suavizada_max = max(tb_prediccion$gan_suavizada, na.rm = TRUE),
      envios = which.max(tb_prediccion$gan_suavizada), alerta_borde = estado_borde,
      fecha_hora = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    )
    fwrite(fila_resumen, file = archivo_resumen, sep = "\t", append = TRUE)
    rm(dfinal_train, final_model, dfuture, tb_prediccion, prediccion); gc(full = TRUE, verbose = FALSE)
  }
}

# ==============================================================================
# 5. RESUMEN ESTADISTICO Y TESTS DE WILCOXON PAREADOS
# ==============================================================================
if (file.exists(archivo_resumen)) {
  resumen <- fread(archivo_resumen)
  resumen[, exp_limpio := sub("_exp$", "", experimento)]
  setorder(resumen, semilla, exp_limpio, fecha_hora)
  resumen_consolidado <- unique(resumen, by = c("semilla", "exp_limpio"), fromLast = TRUE)
  fwrite(resumen_consolidado, file = "resumen_consolidado_10semillas.txt", sep = "\t")
  
  print(resumen_consolidado[, .(
    N = .N,
    Media_Ganancia = mean(ganancia_suavizada_max),
    Mediana_Ganancia = median(ganancia_suavizada_max),
    SD_Ganancia = sd(ganancia_suavizada_max),
    Bordes_OK = sum(alerta_borde == "OK")
  ), by = exp_limpio])
}
