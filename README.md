## Dicionário das Variáveis Agregadas

| **Variável**                     | **Código Original** | **Tipo**   | **Descrição**                                                                 |
|----------------------------------|---------------------|------------|-------------------------------------------------------------------------------|
| **cod_mun_ibge**                 | -                   | STRING     | Código do município (IBGE).                                                  |
| **data_base**                    | -                   | DATE       | Data de referência dos dados (base mensal). Formato `AAAA-MM-01`.             |
| **mes**                          | -                   | STRING     | Mês de referência dos dados.                                                 |
| **ano**                          | -                   | STRING     | Ano de referência dos dados.                                                 |
| **mes_ano**                      | -                   | STRING     | Período no formato `MM-AAAA` (concatenação de mês e ano).                    |
| **caixa**                        | 111                 | FLOAT      | Valor total em **caixa**.                                                    |
| **depositos**                    | 112                 | FLOAT      | Valor total em **depósitos bancários**.                                       |
| **derivativos**                  | 130                 | FLOAT      | Valor total em **títulos e valores mobiliários e instrumentos financeiros derivativos**. |
| **operacoes_de_credito**         | 160                 | FLOAT      | Valor total das **operações de crédito**.                                     |
| **emprestimos**                  | 161                 | FLOAT      | Valor total de **empréstimos e títulos descontados**.                        |
| **fin_ru_agri_cust_inv**         | 163                 | FLOAT      | Valor total de **financiamentos rurais à agricultura (custeio/investimento)**.|
| **fin_ru_pecu_cust_inv**         | 164                 | FLOAT      | Valor total de **financiamentos rurais à pecuária (custeio/investimento)**.  |
| **fin_ru_agri_comercia**         | 165                 | FLOAT      | Valor total de **financiamentos rurais à agricultura (comercialização)**.    |
| **fin_ru_pecu_comercia**         | 166                 | FLOAT      | Valor total de **financiamentos rurais à pecuária (comercialização)**.       |
| **fin_agroindustriais**          | 167_168             | FLOAT      | Valor total de **financiamentos agroindustriais** e **rendas a apropriar**.  |
| **fin_imobiliarios**             | 169                 | FLOAT      | Valor total de **financiamentos imobiliários**.                               |
| **outras_operacoes_credito**     | 171                 | FLOAT      | Valor total de **outras operações de crédito**.                               |
| **outros_creditos**              | 172                 | FLOAT      | Valor total de **outros créditos**.                                           |
| **creditos_em_liquidacao**       | 173                 | FLOAT      | Valor total de **créditos em liquidação**.                                    |
| **provisao_operacoes_credito**   | 174                 | FLOAT      | Valor total da **provisão para operações de crédito**.                        |
| **operacoes_especiais**          | 176                 | FLOAT      | Valor total das **operações especiais**.                                      |
| **total_ativo**                  | 399                 | FLOAT      | Valor total do **ativo**.                                                    |
| **depositos_a_vista**            | 401_402_404_411_412_413_414_415_416_417_418_419 | FLOAT | Valor total dos **depósitos à vista** (governos e setor privado). |
| **depositos_a_prazo**            | 420                 | FLOAT      | Valor total dos **depósitos a prazo**.                                        |

---

## Requisitos

Para executar este projeto, você precisará das seguintes ferramentas e pacotes:

- **R** (versão 4.0 ou superior)
- **Pacotes R**:
  - `renv`: Para lidar com versão de pacotes.
  - `osfr`: Para interagir com o Open Science Framework (OSF) e fazer o download dos dados.
  - `dplyr`: Para manipulação de dados.
  - `duckdb`: Para leitura e processamento eficiente de arquivos Parquet.
  - `tibble`: Para trabalhar com tibbles (uma versão moderna de data frames).

Instale os pacotes necessários com o seguinte comando:

```R
install.packages("renv")
renv::restore()
```
ou instale manualmente:

```R
install.packages(c("osfr", "dplyr", "duckdb", "tibble"))
```

---

## **Estrutura do Projeto**

O projeto é dividido em duas partes principais:

1. **Download e Processamento dos Dados Brutos**:
   - Faz o download dos dados brutos do OSF.
   - Descompacta os arquivos.
   - Realiza a agregação dos dados por município e salva o resultado em um arquivo Parquet.

2. **Download dos Dados Agregados**:
   - Caso você não queira processar os dados brutos, é possível fazer o download diretamente dos dados já agregados.

---

## **Passo a Passo**

### **1. Download e Processamento dos Dados Brutos**

#### **1.1. Carregar Bibliotecas**
As bibliotecas necessárias são carregadas no início do script:

```R
library(osfr)  # Para interagir com o OSF
library(dplyr) # Para manipulação de dados
library(duckdb) # Para processamento eficiente de dados
```

#### **1.2. Acessar o Projeto no OSF**
O projeto no OSF é acessado usando o endereço do projeto:

```R
OSF_PROJECT <- "https://osf.io/9gbh3/"
estban_project <- osfr::osf_retrieve_node(OSF_PROJECT)
```

#### **1.3. Listar e Baixar os Arquivos**
Os arquivos do projeto são listados, e a pasta `Full ESTBAN` é baixada:

```R
files <- osfr::osf_ls_files(estban_project)
files |>
  dplyr::filter(name == "Full ESTBAN") |>
  osfr::osf_download(path = "download/")
```

OBS: Talvez seja necessário criar as pastas `data` e `download`, manualmente.

#### **1.4. Descompactar os Dados**
O arquivo ZIP baixado é descompactado na pasta `data/`:

```R
utils::unzip(
  "download/Full ESTBAN/estban_agencias_geolocalizadas.zip",
  exdir = "data/"
)
```

#### **1.5. Processar os Dados com DuckDB**
Os arquivos Parquet são lidos e agregados por município, mês e ano. O resultado é salvo em um novo arquivo Parquet:

```R
conn <- duckdb::dbConnect(duckdb::duckdb())
PATH_PARQUET_FILES <- "data/estban_agencias_geolocalizadas/*.parquet"

DBI::dbExecute(
  conn,
  paste0(
    "COPY (SELECT ...) TO 'data/aggregated_by_municipalities.parquet' (FORMAT PARQUET)"
  )
)
```

---

### **2. Download dos Dados Agregados**

Caso você não queira processar os dados brutos, é possível fazer o download diretamente dos dados já agregados:

#### **2.1. Baixar os Dados Agregados**
A pasta `Aggregated Data` é baixada do OSF:

```R
files |>
  dplyr::filter(name == "Aggregated Data") |>
  osfr::osf_download(path = "download/")
```

#### **2.2. Ler os Dados Agregados**
Os dados agregados são lidos e carregados em um tibble:

```R
path_downloaded_data <- "download/Aggregated Data/aggregated_by_municipalities.parquet"
data <- DBI::dbGetQuery(
  conn,
  paste0("SELECT * FROM parquet_scan('", path_downloaded_data, "')")
) |> tibble::as_tibble()
```

#### **2.3. Fechar a Conexão**
A conexão com o DuckDB é encerrada:

```R
DBI::dbDisconnect(conn)
```

---

## **Estrutura de Pastas**

O projeto organiza os dados nas seguintes pastas:

- **`download/`**: Armazena os arquivos baixados do OSF.
- **`data/`**: Contém os arquivos descompactados e processados.
- **`data/aggregated_by_municipalities.parquet`**: Arquivo Parquet com os dados agregados por município (caso faça o procedimento desde os dados brutos).

---

Link do projeto na Open Science Framework (OSF): https://osf.io/9gbh3/

Flávio Hugo Pangracio Silva | [GitHub](https://github.com/flaviohugo14) | [LinkedIn](https://linkedin.com/in/flaviopangracio)

---
