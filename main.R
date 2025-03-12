# Load OSF Library (to download data from Open Science Framework)
library(osfr)

# Load Dplyr and DuckDB (to manipulate data)
library(dplyr)
library(duckdb)

# Address from OSF project
OSF_PROJECT <- "https://osf.io/9gbh3/"

################### The steps below can be skipped ###################

# Access OSF Project
estban_project <- osfr::osf_retrieve_node(OSF_PROJECT)

# List files/folders
files <- osfr::osf_ls_files(estban_project)

# Download full data
files |>
  dplyr::filter(name == "Full ESTBAN") |> # Filter only interest folder
  osfr::osf_download(path = "download/")

# Decompress data
utils::unzip(
  "download/Full ESTBAN/estban_agencias_geolocalizadas.zip",
  exdir = "data/"
)

# Create connection with DuckDB
conn <- duckdb::dbConnect(
  duckdb::duckdb(),
)

PATH_PARQUET_FILES <- "data/estban_agencias_geolocalizadas/*.parquet"

# Read parquet files
DBI::dbExecute(
  conn,
  paste0(
    "COPY (SELECT
      cod_mun_ibge,
      data_base,
      mes,
      ano,
      CONCAT(mes, '-', ano) AS mes_ano,
      SUM(\"111\") AS caixa,
      SUM(\"112\") AS depositos,
      SUM(\"130\") AS derivativos,
      SUM(\"160\") AS operacoes_de_credito,
      SUM(\"161\") AS emprestimos,
      SUM(\"162\") AS fin_ru_agri_cust_inv,
      SUM(\"163\") AS fin_ru_pecu_cust_inv,
      SUM(\"164\") AS fin_ru_agri_comercia,
      SUM(\"165\") AS fin_ru_pecu_comercia,
      SUM(\"167_168\") AS fin_agroindustriais,
      SUM(\"169\") AS fin_imobiliarios,
      SUM(\"171\") AS outras_operacoes_credito,
      SUM(\"172\") AS outros_creditos,
      SUM(\"173\") AS creditos_em_liquidacao,
      SUM(\"174\") AS provisao_operacoes_credito,
      SUM(\"176\") AS operacoes_especiais,
      SUM(\"399\") AS total_ativo,
      SUM(\"401_402_404_411_412_413_414_415_416_417_418_419\") AS depositos_a_vista,
      SUM(\"420\") AS depositos_a_prazo,
      SUM(CASE WHEN cnpj = '00000000' THEN 1 ELSE 0 END) as agencias_bb,
      SUM(CASE WHEN cnpj = '00360305' THEN 1 ELSE 0 END) as agencias_caixa,
      SUM(CASE WHEN cnpj IN ('00360305', '00000000') THEN 0 ELSE 1 END) as outras_agencias,
      COUNT(DISTINCT cnpj_agencia) as total_agencias
    FROM
      parquet_scan('", PATH_PARQUET_FILES, "') 
    WHERE cod_mun_ibge IS NOT NULL
    GROUP BY cod_mun_ibge, data_base, mes, ano)
    TO 'data/aggregated_by_municipalities.parquet' (FORMAT PARQUET)
    "
  )
)

# Close connection
DBI::dbDisconnect(conn)

################### The above steps can be skipped ###################

################# Download Aggregated Data directly ##################
estban_project <- osfr::osf_retrieve_node(OSF_PROJECT)

# List files/folders
files <- osfr::osf_ls_files(estban_project)

# Download aggregated data
files |>
  dplyr::filter(name == "Aggregated Data") |> # Filter only interest folder
  osfr::osf_download(path = "download/")

# Create connection with DuckDB
conn <- duckdb::dbConnect(
  duckdb::duckdb(),
)

path_downloaded_data <- "download/Aggregated Data/aggregated_by_municipalities.parquet"

# Load data into a tibble/dataframe
data <- DBI::dbGetQuery(
  conn,
  paste0("SELECT * FROM parquet_scan('", path_downloaded_data, "')")
) |> tibble::as_tibble()

# Close connection
DBI::dbDisconnect(conn)

head(data)
