# ==============================================================================
# 04_hibridacion_triple_final.R
# Hibridacion de Semillerios (Seccion 23.2) y Calibracion Log-Odds (Seccion 25.2)
# Combina los 3 Semillerios (WF9102 + WF9103 + WF9104 = 200 modelos LightGBM)
# Genera exactamente el archivo final entregado en Kaggle: KA_HIB_TRIPLE_1950.csv
# ==============================================================================

rm(list = ls(all.names = TRUE))
gc(full = TRUE, verbose = FALSE)

require("data.table")

# 1. Lectura de las predicciones de los 3 semillerios
# (Busca primero en las carpetas de ejecucion de la VM; si no, en la subcarpeta local del repo)
ruta_p2 <- ifelse(file.exists("/content/buckets/b1/exp/WF9102/prediccion.txt"),
                  "/content/buckets/b1/exp/WF9102/prediccion.txt",
                  "./predicciones_semillerios/WF9102_prediccion.txt")

ruta_p3 <- ifelse(file.exists("/content/buckets/b1/exp/WF9103/prediccion.txt"),
                  "/content/buckets/b1/exp/WF9103/prediccion.txt",
                  "./predicciones_semillerios/WF9103_prediccion.txt")

ruta_p4 <- ifelse(file.exists("/content/buckets/b1/exp/WF9104/prediccion.txt"),
                  "/content/buckets/b1/exp/WF9104/prediccion.txt",
                  "./predicciones_semillerios/WF9104_prediccion.txt")

p2 <- fread(ruta_p2)[, list(numero_de_cliente, prob2 = prob)]
p3 <- fread(ruta_p3)[, list(numero_de_cliente, prob3 = prob)]
p4 <- fread(ruta_p4)[, list(numero_de_cliente, prob4 = prob)]

hib <- merge(p2, p3, by = "numero_de_cliente")
hib <- merge(hib, p4, by = "numero_de_cliente")

# 2. Estandarizacion en escala Log-Odds (Seccion 25.2: Calibracion en Gradient Boosting)
# Corrige las diferencias de learning_rate y num_iterations entre las 3 corridas
logit <- function(p) log(p / (1 - p))

hib[, z2 := as.numeric(scale(logit(prob2)))]
hib[, z3 := as.numeric(scale(logit(prob3)))]
hib[, z4 := as.numeric(scale(logit(prob4)))]

# 3. Hibridacion ponderada de los 3 semillerios (200 semillas en total):
# - 40% WF9102 (50 semillas, hojas macro min_data_in_leaf=2416, ventana 6m)
# - 25% WF9103 (50 semillas, hojas micro min_data_in_leaf=99, rankings rk0 + ventana 3m/6m)
# - 35% WF9104 (100 semillas, BO al 100% sin undersampling, medias moviles avg3/6)
hib[, score_234 := 0.40 * z2 + 0.25 * z3 + 0.35 * z4]

setorder(hib, -score_234)

# 4. Generacion del envio definitivo en el centro de la meseta (1950 estimulos)
envios_final <- 1950L
hib[, Predicted := 0L]
hib[1:envios_final, Predicted := 1L]

dir.create("/content/buckets/b1/exp/HIBRIDACION", showWarnings = FALSE, recursive = TRUE)
archivo_salida <- "/content/buckets/b1/exp/HIBRIDACION/KA_HIB_TRIPLE_1950.csv"

fwrite(hib[, list(numero_de_cliente, Predicted)], file = archivo_salida, sep = ",")
fwrite(hib[, list(numero_de_cliente, Predicted)], file = "./KA_HIB_TRIPLE_1950.csv", sep = ",")

cat("Archivo final generado exitosamente:", archivo_salida, "\n")
cat("Total de estimulos enviados:", sum(hib$Predicted), "\n")
