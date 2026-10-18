---
title: "Indicadores de desigualdade de gênero"
subtitle: "PNAD Contínua · 2022 · RJ"
params:
  ano: 2022
  visita: 5
  ufs: ["RJ"]
  gerar_base: false
  url_base: ""
  url_desenho: ""
code-tools: true
code-links:
  - text: "Baixar o relatório (.qmd)"
    icon: download
    href: downloads/relatorio.qmd
---

::: {.callout-note}
## Como usar este relatório
Com `gerar_base: false` (padrão), a base do curso é lida do Zenodo com o `readr`, e o relatório roda em poucos segundos. Os blocos que geram a base a partir dos microdados do IBGE aparecem no relatório, mas só são executados com `gerar_base: true`.
:::

## 1. Enquadramento

*Texto a desenvolver:* indicadores de desigualdade de gênero, o CMIG e o ODS 5. A PNAD Contínua registra o sexo em duas categorias: os indicadores comparam mulheres e homens.

## 2. Conhecendo a PNAD Contínua

*Texto a desenvolver:* desenho amostral, arquivo anual da 5ª visita, questionário, dicionário e domínios de estimação.

::: {.callout-important}
## Por que a 5ª visita

Cada domicílio da PNAD Contínua é entrevistado cinco vezes, uma por trimestre. As perguntas básicas sobre as pessoas, a educação e o trabalho se repetem em todas as entrevistas. Já os temas complementares são investigados só em uma visita específica.

O relatório usa o arquivo anual da **5ª visita** por um motivo: é nela que o IBGE investiga as **outras formas de trabalho**, o módulo que traz os cuidados de pessoas e os afazeres domésticos. Sem esse módulo, não há como medir o trabalho não remunerado, que é uma das dimensões centrais da desigualdade de gênero.

A escolha tem duas consequências:

- **Uma única base cobre todos os indicadores do curso**, do mercado de trabalho aos afazeres, para as mesmas pessoas.
- **Os resultados de trabalho e de educação podem diferir um pouco** das divulgações trimestrais e do módulo anual de educação, que usam outros arquivos da pesquisa.

**Em 2020 e 2021, o módulo não foi investigado.** Por causa da pandemia de COVID-19, o IBGE suspendeu a investigação das outras formas de trabalho nesses dois anos e a retomou em 2022. O arquivo da 5ª visita de 2020 e de 2021 existe, mas sem as perguntas sobre cuidados e afazeres. Por isso, este relatório não pode ser gerado para esses dois anos: a checagem de variáveis do bloco 3 interrompe a execução e informa quais variáveis faltam.

Ao trocar o ano do relatório, vale sempre conferir no dicionário daquele ano se o módulo está na 5ª visita.
:::

## 3. O projeto e os dados

### Parâmetros

O ano, a visita e as UFs vêm do cabeçalho do relatório.

Nem todo ano pode ser usado. O módulo de cuidados e afazeres domésticos é investigado na 5ª visita desde 2016, e não foi a campo em 2020 e 2021. A lista `anos_disponiveis` reúne os anos em que os microdados da 5ª visita foram publicados com o módulo. O bloco abaixo confere os parâmetros antes de qualquer cálculo e interrompe o relatório, com uma mensagem clara, se o ano ou a visita não servirem. Quando o IBGE publicar um novo ano, basta acrescentá-lo à lista.


::: {.cell}

```{.r .cell-code}
ano    <- params$ano
visita <- params$visita
ufs    <- params$ufs

# O módulo de outras formas de trabalho só existe na 5ª visita
if (visita != 5) {
  stop(
    'Este relatório usa a 5ª visita, a única com o módulo de cuidados e ',
    'afazeres domésticos. Visita informada: ', visita, '.',
    call. = FALSE
  )
}

# Anos com a 5ª visita publicada e com o módulo de cuidados e afazeres.
# Ficam de fora 2020 e 2021, quando o módulo não foi investigado (pandemia).
anos_disponiveis <- c(2016, 2017, 2018, 2019, 2022, 2023, 2024)

if (!ano %in% anos_disponiveis) {
  stop(
    'O ano ', ano, ' não pode ser usado. Anos disponíveis: ',
    paste(anos_disponiveis, collapse = ', '), '.',
    call. = FALSE
  )
}

pasta_dados <- 'dados'

arquivo_base <- file.path(
  pasta_dados, sprintf('pnadc_%d_visita%d.csv.gz', ano, visita)
)

arquivo_replicas <- file.path(
  pasta_dados, sprintf('pnadc_%d_visita%d_replicas.csv.gz', ano, visita)
)

arquivo_desenho <- file.path(
  pasta_dados, sprintf('pnadc_%d_visita%d_desenho.rds', ano, visita)
)
```
:::


### Pacotes

O relatório usa os pacotes abaixo. O `pacman` carrega todos de uma vez e instala automaticamente os que estiverem faltando.

| Pacote | Para que serve no relatório |
|---|---|
| `pacman` | Gerencia os pacotes: carrega a lista inteira com `p_load()` e instala o que não estiver instalado |
| `readr` | Lê e grava os arquivos `.csv.gz` da base, com os tipos de coluna definidos, direto do disco ou de um endereço na internet |
| `dplyr` | Manipula a base: seleciona variáveis, filtra, cria e recodifica colunas, agrupa e resume |
| `tidyr` | Reorganiza tabelas, por exemplo passando resultados de formato longo para largo na hora de montar tabelas |
| `stringr` | Trata textos, como rótulos de categorias e nomes de variáveis |
| `ggplot2` | Constrói os gráficos, camada por camada, a partir de uma tabela de resultados |
| `plotly` | Transforma um gráfico do `ggplot2` em gráfico interativo com `ggplotly()`: passar o mouse mostra os valores, e dá para ampliar e esconder séries |
| `survey` | Implementa a análise de amostras complexas: desenho amostral, pós-estratificação, testes (`svyttest`, `svychisq`) e regressão (`svyglm`) |
| `srvyr` | Traz a sintaxe do `dplyr` para o `survey`: `group_by()` e `summarise()` com `survey_mean()`, `survey_prop()` e `survey_ratio()`, que devolvem estimativa, intervalo de confiança e CV |
| `PNADcIBGE` | Baixa e lê os microdados da PNAD Contínua direto do IBGE. Usado só na geração da base (`gerar_base: true`) |


::: {.cell}

```{.r .cell-code}
# Repositório do CRAN para instalar pacotes caso necessário
options(repos = c(CRAN = 'https://cloud.r-project.org'))

if(!require(pacman)) {
  install.packages('pacman')
}
```

::: {.cell-output .cell-output-stderr}

```
Carregando pacotes exigidos: pacman
```


:::

::: {.cell-output .cell-output-stderr}

```
Warning: pacote 'pacman' foi compilado no R versão 4.4.3
```


:::

```{.r .cell-code}
pacman::p_load(
  dplyr, tidyr, stringr, ggplot2, plotly, readr, survey, srvyr, PNADcIBGE
)
```
:::


### Seleção de variáveis

As variáveis estão agrupadas por tema. Os mesmos grupos são usados adiante, por exemplo `vars_desenho` na criação do desenho amostral.

| Grupo | Variável | Descrição | Categorias ou valores |
|---|---|---|---|
| Chave | `Ano` | Ano de referência | |
| Chave | `Trimestre` | Trimestre de referência | 1 a 4 |
| Chave | `UPA` | Unidade Primária de Amostragem | UF (2 dígitos) + número sequencial (6) + dígito verificador (1) |
| Chave | `V1008` | Número de seleção do domicílio | 01 a 14 |
| Chave | `V1014` | Painel (grupo de amostra) | 01 a 99 |
| Chave | `V2003` | Número de ordem da pessoa no domicílio | 01 a 30 |
| Localização | `UF` | Unidade da Federação | Código IBGE da UF (33 = Rio de Janeiro) |
| Localização | `V1022` | Situação do domicílio | 1 Urbana; 2 Rural |
| Localização | `V1023` | Tipo de área. Junto com a `UF`, identifica a capital e a região metropolitana de cada UF | 1 Capital; 2 Resto da RM; 3 Resto da RIDE; 4 Resto da UF |
| Desenho | `Estrato` | Estrato de seleção da amostra | As 2 primeiras posições são o código da UF |
| Desenho | `ID_DOMICILIO` | Identificação do domicílio, a unidade do 2º estágio da amostra. Criada pelo `PNADcIBGE` na leitura | `UPA` + `V1008` + `V1014` |
| Desenho | `V1031` | Peso da 5ª visita **sem** calibração pela projeção de população | Com correção de não entrevista |
| Desenho | `V1032` | Peso da 5ª visita **com** calibração pela projeção de população | Com correção de não entrevista |
| Desenho | `posest` | Domínios de projeção geográficos | UF (2) + tipo de área `V1023` (1) |
| Desenho | `V1030` | Projeção da população por domínio geográfico | Total populacional de cada `posest` |
| Desenho | `posest_sxi` | Domínios de projeção por sexo e idade | Sexo (1) + grupo de idade (2) |
| Desenho | `V1034` | Projeção da população por sexo e idade | Total populacional de cada `posest_sxi` |
| Pessoa | `V2005` | Condição no domicílio | 01 Responsável; 02–03 Cônjuge; 04–06 Filho(a) ou enteado(a); 07–16 Outros parentes e não parentes |
| Pessoa | `V2007` | Sexo | 1 Homem; 2 Mulher |
| Pessoa | `V2009` | Idade na data de referência | 0 a 130 anos |
| Pessoa | `V2010` | Cor ou raça | 1 Branca; 2 Preta; 3 Amarela; 4 Parda; 5 Indígena; 9 Ignorado |
| Educação | `V3002` | Frequenta escola? | 1 Sim; 2 Não |
| Educação | `VD3004` | Nível de instrução mais elevado alcançado (5 anos ou mais) | 1 Sem instrução; 2 Fundamental incompleto; 3 Fundamental completo; 4 Médio incompleto; 5 Médio completo; 6 Superior incompleto; 7 Superior completo |
| Educação | `VD3005` | Anos de estudo (5 anos ou mais) | 0 a 15; 16 = 16 anos ou mais |
| Trabalho | `VD4001` | Condição em relação à força de trabalho (14 anos ou mais) | 1 Na força de trabalho; 2 Fora da força de trabalho |
| Trabalho | `VD4002` | Condição de ocupação (14 anos ou mais) | 1 Ocupada; 2 Desocupada |
| Trabalho | `VD4009` | Posição na ocupação e categoria do emprego no trabalho principal | 1–2 Setor privado com e sem carteira; 3–4 Doméstico com e sem carteira; 5–6 Setor público com e sem carteira; 7 Militar e estatutário; 8 Empregador; 9 Conta própria; 10 Familiar auxiliar |
| Trabalho | `V4019` | O negócio era registrado no CNPJ? | 1 Sim; 2 Não |
| Trabalho | `VD4012` | Contribuição para a previdência em qualquer trabalho | 1 Contribuinte; 2 Não contribuinte |
| Trabalho | `VD4010` | Grupamento de atividade do trabalho principal | 12 grupamentos (ex.: 9 Educação, saúde humana e serviços sociais; 11 Serviços domésticos) |
| Trabalho | `VD4011` | Grupamento ocupacional do trabalho principal | 11 grupamentos (ex.: 1 Diretores e gerentes; 2 Profissionais das ciências e intelectuais) |
| Trabalho | `V4010` | Código da ocupação (cargo ou função) no trabalho principal, pela Classificação de Ocupações para Pesquisas Domiciliares (COD) | 4 dígitos; os 2 primeiros indicam o subgrupo (11 a 14 = diretores e gerentes) |
| Trabalho | `VD4019` | Rendimento mensal habitual de todos os trabalhos | Valor em R$ |
| Trabalho | `VD4031` | Horas habitualmente trabalhadas por semana em todos os trabalhos | 1 a 120 horas |
| Rendimento | `VD5008` | Rendimento domiciliar per capita: habitual de todos os trabalhos e efetivo de outras fontes (exclui pensionistas, empregados domésticos e seus parentes) | Valor em R$ |
| Afazeres | `V4117A` | Cuidou de moradores do domicílio (crianças, idosos, enfermos ou pessoas com necessidades especiais)? | 1 Sim; 2 Não |
| Afazeres | `V4119` | Cuidou de parentes que **não moravam** no domicílio e precisavam de cuidados? | 1 Sim; 2 Não |
| Afazeres | `V4120` | Fez tarefas domésticas para o próprio domicílio? | 1 Sim; 2 Não |
| Afazeres | `V4121A` | Fez tarefas domésticas em domicílio de parente? | 1 Sim; 2 Não |
| Afazeres | `V4121B` | Total de horas semanais dedicadas a cuidados de pessoas e/ou afazeres domésticos | 1 a 120 horas |
| Réplicas | `V1032001` a `V1032200` | Pesos replicados (bootstrap) da 5ª visita, com calibração | Arquivo separado |

: Fonte: IBGE, dicionário das variáveis da PNAD Contínua, 5ª visita. As descrições seguem o dicionário de 2022, usado como referência. Nas variáveis com "Não aplicável", o valor fica vazio (`NA`) para as pessoas fora do público da pergunta, por exemplo menores de 14 anos nas variáveis de trabalho.


::: {.cell}

```{.r .cell-code}
# Identificação da pessoa: chave para juntar a base principal e as réplicas
vars_chave <- c('Ano', 'Trimestre', 'UPA', 'V1008', 'V1014', 'V2003')

# Localização
# Capital e RM_RIDE não entram: a UF com a V1023 (tipo de área) já as identifica
vars_local <- c('UF', 'V1022', 'V1023')

# Desenho amostral (linearização com calibração por área geográfica e por sexo e idade)
vars_desenho <- c(
  'Estrato', 'ID_DOMICILIO', 'V1031', 'V1032',
  'posest', 'V1030', 'posest_sxi', 'V1034'
)

# Características da pessoa
vars_pessoa <- c('V2005', 'V2007', 'V2009', 'V2010')

# Educação
vars_educacao <- c('V3002', 'VD3004', 'VD3005')

# Trabalho e rendimento
vars_trabalho <- c(
  'VD4001', 'VD4002', 'VD4009', 'V4019', 'VD4012',
  'VD4010', 'VD4011', 'V4010', 'VD4019', 'VD4031',
  'VD5008' # rendimento domiciliar per capita
)

# Outras formas de trabalho (módulo da 5ª visita)
vars_afazeres <- c('V4117A', 'V4119', 'V4120', 'V4121A', 'V4121B')

# Pesos replicados (bootstrap)
vars_replicas <- sprintf('V1032%03d', 1:200)

vars_curso <- c(
  vars_chave, vars_local, vars_desenho, vars_pessoa,
  vars_educacao, vars_trabalho, vars_afazeres
)
```
:::


### Geração da base a partir dos microdados

Executado só com `gerar_base: true`. Gera a base do curso em `.csv.gz`, publicada no Zenodo e usada em todo o relatório, e o arquivo de pesos replicados, usado só na comparação de métodos do bloco 6. O desenho amostral é gerado e gravado no bloco 6, porque depende das variáveis criadas no bloco 4.


::: {.cell cache.extra='[2022,5,["Ano","Trimestre","UPA","V1008","V1014","V2003","UF","V1022","V1023","Estrato","ID_DOMICILIO","V1031","V1032","posest","V1030","posest_sxi","V1034","V2005","V2007","V2009","V2010","V3002","VD3004","VD3005","VD4001","VD4002","VD4009","V4019","VD4012","VD4010","VD4011","V4010","VD4019","VD4031","VD5008","V4117A","V4119","V4120","V4121A","V4121B"],["V1032001","V1032002","V1032003","V1032004","V1032005","V1032006","V1032007","V1032008","V1032009","V1032010","V1032011","V1032012","V1032013","V1032014","V1032015","V1032016","V1032017","V1032018","V1032019","V1032020","V1032021","V1032022","V1032023","V1032024","V1032025","V1032026","V1032027","V1032028","V1032029","V1032030","V1032031","V1032032","V1032033","V1032034","V1032035","V1032036","V1032037","V1032038","V1032039","V1032040","V1032041","V1032042","V1032043","V1032044","V1032045","V1032046","V1032047","V1032048","V1032049","V1032050","V1032051","V1032052","V1032053","V1032054","V1032055","V1032056","V1032057","V1032058","V1032059","V1032060","V1032061","V1032062","V1032063","V1032064","V1032065","V1032066","V1032067","V1032068","V1032069","V1032070","V1032071","V1032072","V1032073","V1032074","V1032075","V1032076","V1032077","V1032078","V1032079","V1032080","V1032081","V1032082","V1032083","V1032084","V1032085","V1032086","V1032087","V1032088","V1032089","V1032090","V1032091","V1032092","V1032093","V1032094","V1032095","V1032096","V1032097","V1032098","V1032099","V1032100","V1032101","V1032102","V1032103","V1032104","V1032105","V1032106","V1032107","V1032108","V1032109","V1032110","V1032111","V1032112","V1032113","V1032114","V1032115","V1032116","V1032117","V1032118","V1032119","V1032120","V1032121","V1032122","V1032123","V1032124","V1032125","V1032126","V1032127","V1032128","V1032129","V1032130","V1032131","V1032132","V1032133","V1032134","V1032135","V1032136","V1032137","V1032138","V1032139","V1032140","V1032141","V1032142","V1032143","V1032144","V1032145","V1032146","V1032147","V1032148","V1032149","V1032150","V1032151","V1032152","V1032153","V1032154","V1032155","V1032156","V1032157","V1032158","V1032159","V1032160","V1032161","V1032162","V1032163","V1032164","V1032165","V1032166","V1032167","V1032168","V1032169","V1032170","V1032171","V1032172","V1032173","V1032174","V1032175","V1032176","V1032177","V1032178","V1032179","V1032180","V1032181","V1032182","V1032183","V1032184","V1032185","V1032186","V1032187","V1032188","V1032189","V1032190","V1032191","V1032192","V1032193","V1032194","V1032195","V1032196","V1032197","V1032198","V1032199","V1032200"]]'}

```{.r .cell-code}
pnadc <- get_pnadc(
  year      = ano,
  interview = visita,
  vars      = c(vars_curso, vars_replicas),
  labels    = FALSE,  # mantém os códigos das categorias
  deflator  = FALSE,
  design    = FALSE   # data frame puro: o desenho é criado no bloco 6
)
```
:::



::: {.cell}

```{.r .cell-code}
vars_pedidas <- c(vars_curso, vars_replicas)
faltando     <- setdiff(vars_pedidas, names(pnadc))

if (length(faltando) > 0) {
  stop('Variáveis ausentes no arquivo da ', visita, 'ª visita de ', ano, ': ',
       paste(faltando, collapse = ', '),
       '. Confira o dicionário desse ano.', call. = FALSE)
}

cat('As', length(vars_pedidas), 'variáveis selecionadas estão no arquivo.\n')

# Variáveis que o get_pnadc() traz além das pedidas (não vão para os CSV)
extras <- setdiff(names(pnadc), vars_pedidas)
if (length(extras) > 0) {
  cat('Variáveis extras, descartadas:', paste(extras, collapse = ', '), '\n')
}
```
:::



::: {.cell}

```{.r .cell-code}
# A chave não pode ter valores ausentes...
chave_com_na <- pnadc |>
  filter(if_any(all_of(vars_chave), is.na)) |>
  nrow()

if (chave_com_na > 0) {
  stop(
    chave_com_na, ' linhas com valor ausente em alguma variável da chave (',
    paste(vars_chave, collapse = ', '), ').', 
    call. = FALSE
  )
}

# ...nem se repetir: cada combinação deve corresponder a uma única pessoa
chaves_repetidas <- pnadc |>
  count(across(all_of(vars_chave))) |>
  filter(n > 1) |>
  nrow()

if (chaves_repetidas > 0) {
  stop(
    chaves_repetidas, ' combinações da chave aparecem em mais de uma linha. ',
    'A junção com os pesos replicados não seria confiável.', 
    call. = FALSE
  )
}

cat(
  'A chave identifica de forma única as',
  format(nrow(pnadc), big.mark = '.', decimal.mark = ','), 
  'pessoas da amostra.\n'
)
```
:::



::: {.cell}

```{.r .cell-code}
# O peso calibrado deve existir e ser positivo para todas as pessoas
if (anyNA(pnadc$V1032) || any(pnadc$V1032 <= 0)) {
  stop('V1032 tem valores ausentes ou não positivos.', call. = FALSE)
}

# Soma dos pesos: população estimada pela amostra
pop_estimada <- sum(as.numeric(pnadc$V1032))

# Projeções de população usadas na calibração: um total por domínio,
# repetido em todas as pessoas do domínio
total_projecao <- function(dominio, total) {
  totais <- pnadc |> 
    distinct(.data[[dominio]], .data[[total]])
  if (anyDuplicated(totais[[dominio]])) {
    stop(
      'O domínio ', dominio, ' tem mais de um total em ', total, '.', 
      call. = FALSE
    )
  }
  sum(as.numeric(totais[[total]]))
}

pop_geografica <- total_projecao('posest', 'V1030')
pop_sexo_idade <- total_projecao('posest_sxi', 'V1034')

# Tolerância relativa de 0,01%, para absorver arredondamentos dos pesos
confere <- function(projecao) {
  abs(pop_estimada / projecao - 1) < 1e-4
} 

comparacao <- tibble(
  referencia = c(
    'Soma de V1032',
    'Projeção por domínio geográfico (V1030)',
    'Projeção por sexo e idade (V1034)'
  ),
  populacao  = c(pop_estimada, pop_geografica, pop_sexo_idade),
  confere    = c(NA, confere(pop_geografica), confere(pop_sexo_idade))
)
comparacao

if (!all(comparacao$confere, na.rm = TRUE)) {
  stop(
    'A soma de V1032 não bate com as projeções de população.', 
    call. = FALSE
  )
}
```
:::



::: {.cell}

```{.r .cell-code}
dir.create(pasta_dados, showWarnings = FALSE, recursive = TRUE)

# A extensão .gz faz o readr compactar o arquivo automaticamente.
# Valores ausentes são gravados como campo vazio, que o readr lê como NA.
pnadc |>
  select(all_of(vars_curso)) |>
  write_csv(arquivo_base, na = '')

pnadc |>
  select(all_of(c(vars_chave, vars_replicas))) |>
  write_csv(arquivo_replicas, na = '')
```
:::


### Leitura da base do curso


::: {.cell}

```{.r .cell-code}
# Tipos das colunas: sem essa definição, o readr adivinha e erra nos dois
# sentidos (identificadores viram número; códigos com zero à esquerda viram texto)
vars_texto <- c(
  'UPA', 'Estrato', 'ID_DOMICILIO', 'V1008', 'V1014', 'posest', 'posest_sxi',
  'V4010' # código da ocupação: os dígitos têm significado, não é uma quantidade
)
vars_decimais <- c('V1030', 'V1031', 'V1032', 'V1034', 'VD4019', 'VD5008')

tipos <- cols(.default = col_integer())
tipos$cols[vars_texto]    <- list(col_character())
tipos$cols[vars_decimais] <- list(col_double())

# Arquivo local, se existir; senão, o link do Zenodo
localiza_arquivo <- function(arquivo, url) {
  if (file.exists(arquivo)) {
    return(arquivo)
  }
  if (nzchar(url)) {
    # O link do Zenodo termina em '?download=1': baixar para um arquivo
    # temporário com a mesma extensão do original (.csv.gz ou .rds)
    extensao <- sub('^[^.]*', '', basename(arquivo))
    temporario <- tempfile(fileext = extensao)
    download.file(url, temporario, mode = 'wb', quiet = TRUE)
    return(temporario)
  }
  stop(
    'Arquivo não encontrado em ', arquivo, ' e o link do Zenodo está vazio.',
    call. = FALSE
  )
}

# Qualquer valor que não coube no tipo definido vira NA com aviso: melhor parar
confere_leitura <- function(dados) {
  if (nrow(problems(dados)) > 0) {
    print(problems(dados))
    stop('Problemas na leitura: veja a tabela acima.', call. = FALSE)
  }
}

# Base principal
pnadc <- read_csv(
  localiza_arquivo(arquivo_base, params$url_base),
  col_types = tipos,
  col_select = all_of(vars_curso),
  progress = FALSE
)
confere_leitura(pnadc)

cat(
  'Base lida:', format(nrow(pnadc), big.mark = '.', decimal.mark = ','),
  'pessoas e', ncol(pnadc), 'variáveis.\n'
)
```

::: {.cell-output .cell-output-stdout}

```
Base lida: 380.928 pessoas e 40 variáveis.
```


:::
:::


## 4. Recodificação e variáveis derivadas

A base guarda os códigos da PNAD. Aqui eles viram as categorias usadas nos indicadores, seguindo os agrupamentos da publicação *Estatísticas de Gênero* do IBGE. As variáveis originais continuam na base; as derivadas ganham nomes em português.

As variáveis derivadas de dois tipos de resposta, sim ou não, são criadas como **dummies**:

- **1** para quem tem a característica;
- **0** para quem não tem;
- **NA** para quem está fora da população a que a pergunta se aplica. Por exemplo, a informalidade só se aplica a quem está ocupado.

Com dummies, um total estimado é a soma dos pesos multiplicados pela dummy, como nas fórmulas do bloco 5.

### Características da pessoa e do território

| Variável derivada | Origem | Categorias |
|---|---|---|
| `sexo` | `V2007` | Homem; Mulher |
| `cor_raca` | `V2010` | Branca; Preta ou parda; Outras (amarela, indígena ou ignorada) |
| `faixa_etaria` | `V2009` | Menos de 16; 16 a 29; 30 a 49; 50 a 59; 60 ou mais |
| `escolaridade` | `VD3004` | 4 grupos de nível de instrução, como no informativo |
| `regiao` | `UF` | Grande região, pelo primeiro dígito do código da UF |
| `territorio` | `V1023` | Capital; Resto da RM; Interior (resto da RIDE e resto da UF) |
| `situacao` | `V1022` | Urbana; Rural |
| `condicao_atividade` | `V2009`, `VD4001`, `VD4002` | Menos de 14 anos; Fora da força de trabalho; Ocupada; Desocupada |
| `realizou_cuidados` | `V4117A`, `V4119` | Dummy: 1 = cuidou de moradores **ou** de parentes não moradores; 0 = não cuidou |
| `realizou_afazeres` | `V4120`, `V4121A` | Dummy: 1 = afazeres no próprio domicílio **ou** em domicílio de parente; 0 = não fez |


::: {.cell}

```{.r .cell-code}
pnadc <- pnadc |>
  mutate(
    sexo = factor(V2007, levels = 1:2, labels = c('Homem', 'Mulher')),

    # O informativo compara brancos com pretos ou pardos
    cor_raca = case_when(
      V2010 == 1 ~ 'Branca',
      V2010 %in% c(2, 4) ~ 'Preta ou parda',
      .default = 'Outras'
    ) |>
      factor(levels = c('Branca', 'Preta ou parda', 'Outras')),

    # Faixas gerais; indicadores com população específica (por exemplo,
    # 25 a 54 anos) filtram direto pela idade em V2009
    faixa_etaria = cut(
      V2009,
      breaks = c(-Inf, 15, 29, 49, 59, Inf),
      labels = c('Menos de 16', '16 a 29', '30 a 49', '50 a 59', '60 ou mais')
    ),

    # Nível de instrução agrupado como no informativo (definido para 5 anos ou mais)
    escolaridade = case_when(
      VD3004 %in% 1:2 ~ 'Sem instrução e fundamental incompleto',
      VD3004 %in% 3:4 ~ 'Fundamental completo e médio incompleto',
      VD3004 %in% 5:6 ~ 'Médio completo e superior incompleto',
      VD3004 == 7 ~ 'Superior completo'
    ) |>
      factor(levels = c(
        'Sem instrução e fundamental incompleto',
        'Fundamental completo e médio incompleto',
        'Médio completo e superior incompleto',
        'Superior completo'
      )),

    # O primeiro dígito do código da UF identifica a grande região
    regiao = factor(
      str_sub(UF, 1, 1),
      levels = 1:5,
      labels = c('Norte', 'Nordeste', 'Sudeste', 'Sul', 'Centro-Oeste')
    ),

    # Resto da RIDE e resto da UF formam o "interior"
    territorio = case_when(
      V1023 == 1 ~ 'Capital',
      V1023 == 2 ~ 'Resto da RM',
      V1023 %in% c(3, 4) ~ 'Interior'
    ) |>
      factor(levels = c('Capital', 'Resto da RM', 'Interior')),

    situacao = factor(V1022, levels = 1:2, labels = c('Urbana', 'Rural')),

    # Condição de atividade: população em idade de trabalhar a partir de 14 anos
    condicao_atividade = case_when(
      V2009 < 14 ~ 'Menos de 14 anos',
      VD4002 == 1 ~ 'Ocupada',
      VD4002 == 2 ~ 'Desocupada',
      VD4001 == 2 ~ 'Fora da força de trabalho'
    ) |>
      factor(levels = c(
        'Menos de 14 anos', 'Fora da força de trabalho',
        'Ocupada', 'Desocupada'
      )),

    # Cuidados e afazeres: dummies, com NA para quem não respondeu ao módulo
    realizou_cuidados = case_when(
      is.na(V4117A) & is.na(V4119) ~ NA,
      V4117A %in% 1 | V4119 %in% 1 ~ 1,
      .default = 0
    ),
    realizou_afazeres = case_when(
      is.na(V4120) & is.na(V4121A) ~ NA,
      V4120 %in% 1 | V4121A %in% 1 ~ 1,
      .default = 0
    )
  )
```
:::


### Criança de até 6 anos no domicílio

Uma informação de algumas pessoas (ter até 6 anos) passa a valer para todos os moradores do domicílio. É a base do indicador de nível de ocupação de pessoas de 25 a 54 anos com e sem crianças pequenas (CMIG 1.15). A dummy `crianca_ate_6` vale 1 para todos os moradores de domicílios com pelo menos uma criança de até 6 anos, e 0 para os demais.


::: {.cell}

```{.r .cell-code}
pnadc <- pnadc |>
  group_by(ID_DOMICILIO) |>
  mutate(crianca_ate_6 = if_else(any(V2009 <= 6), 1, 0)) |>
  ungroup()
```
:::


### Informalidade

Segue a definição usada pelo IBGE na publicação *Estatísticas de Gênero* para o indicador CMIG 1.9. Entre as pessoas ocupadas, são informais:

- os empregados sem carteira assinada, no setor privado, no trabalho doméstico e no setor público;
- os empregadores e trabalhadores por conta própria que não contribuem para a previdência;
- os trabalhadores familiares auxiliares.

O indicador é calculado só para o **trabalho não agrícola**, excluindo a agropecuária.

::: {.callout-note}
## Outra definição de informalidade
A divulgação mensal da PNAD Contínua usa o registro no CNPJ (`V4019`) em vez da contribuição para a previdência, não inclui o setor público e considera todas as atividades. As duas definições medem coisas diferentes e podem levar a conclusões diferentes sobre a desigualdade entre mulheres e homens. Por isso, todo resultado de informalidade precisa vir acompanhado da definição usada.
:::


::: {.cell}

```{.r .cell-code}
pnadc <- pnadc |>
  mutate(
    # Empregados sem carteira (privado 2, doméstico 4, público 6), familiar
    # auxiliar (10) e empregador ou conta própria não contribuinte (8 e 9)
    informal = case_when(
      condicao_atividade != 'Ocupada' ~ NA, # só se aplica a ocupados
      VD4009 %in% c(2, 4, 6, 10) ~ 1,
      VD4009 %in% c(8, 9) & VD4012 %in% 2 ~ 1,
      .default = 0
    ),

    # O indicador CMIG 1.9 considera só o trabalho não agrícola
    atividade_agricola = if_else(VD4010 == 1, 1, 0)
  )
```
:::


### Setor de atividade e cargos gerenciais

Duas classificações do trabalho principal das pessoas ocupadas:

- **Setor de atividade** (CMIG 1.8): os 12 grupamentos de `VD4010` reunidos em agropecuária, indústria (que inclui a construção) e serviços. As atividades mal definidas ficam sem setor.
- **Cargo gerencial** (CMIG 4.3): as ocupações de direção e gerência, identificadas pelos dois primeiros dígitos do código da ocupação (`V4010`). São duas variáveis: `cargo_gerencial`, só com a gerência sênior e intermediária, e `cargo_gerencial_total`, que inclui também a gerência júnior.

#### Por que só parte dos diretores e gerentes

O CMIG 4.3, que corresponde ao indicador 5.5.2 dos Objetivos de Desenvolvimento Sustentável, mede a presença de mulheres em posições de decisão. A Organização Internacional do Trabalho define essas posições pela Classificação Internacional Uniforme de Ocupações (CIUO-08, ou ISCO-08 em inglês). A classificação usada na PNAD Contínua, a COD, segue a mesma estrutura, de modo que os códigos são comparáveis.

O grande grupo 1 dessa classificação, "Diretores e gerentes", tem quatro subgrupos:

| Subgrupo | ISCO-08 | COD | Nível de gerência |
|---|---|---|---|
| 11 | Chief executives, senior officials and legislators | Diretores executivos, dirigentes da administração pública e membros do poder executivo e legislativo | Sênior e intermediária |
| 12 | Administrative and commercial managers | Dirigentes administrativos e comerciais | Sênior e intermediária |
| 13 | Production and specialized services managers | Dirigentes e gerentes de produção e operação | Sênior e intermediária |
| 14 | Hospitality, retail and other services managers | Gerentes de hotéis, restaurantes, comércio e outros serviços | Júnior |

O indicador considera os subgrupos **11, 12 e 13**, que reúnem a gerência sênior e intermediária: quem dirige organizações, define políticas e coordena áreas inteiras. O subgrupo **14** fica de fora porque é classificado como gerência júnior: reúne gerentes de estabelecimentos pequenos, como lojas, restaurantes e pousadas, que em geral acumulam a gerência com a operação do dia a dia e têm autonomia de decisão mais limitada.

O CMIG 4.3 tem duas séries: a proporção de mulheres em **todos os cargos gerenciais** (subgrupos 11 a 14) e a proporção de mulheres na **gerência sênior e intermediária** (subgrupos 11 a 13). O relatório cria uma variável para cada série:

| Variável | Subgrupos | Série do CMIG 4.3 |
|---|---|---|
| `cargo_gerencial` | 11, 12 e 13 | Gerência sênior e intermediária |
| `cargo_gerencial_total` | 11, 12, 13 e 14 | Todos os cargos gerenciais |

A distinção pode importar para a análise de gênero. Se as mulheres estiverem mais presentes na gerência de comércio e serviços do que nos demais subgrupos, incluir o subgrupo 14 aumenta a participação feminina medida, sem que isso reflita maior acesso aos postos onde as decisões de maior alcance são tomadas. Comparar o indicador calculado com as duas variáveis permite verificar essa hipótese nos dados.


::: {.cell}

```{.r .cell-code}
pnadc <- pnadc |>
  mutate(
    setor = case_when(
      VD4010 == 1 ~ 'Agropecuária',
      VD4010 %in% 2:3 ~ 'Indústria',
      VD4010 %in% 4:11 ~ 'Serviços'
    ) |>
      factor(levels = c('Agropecuária', 'Indústria', 'Serviços')),

    # Os dois primeiros dígitos do código da ocupação indicam o subgrupo
    subgrupo_ocupacao = str_sub(V4010, 1, 2),

    # Gerência sênior e intermediária: subgrupos 11, 12 e 13
    cargo_gerencial = case_when(
      condicao_atividade != 'Ocupada' ~ NA, # só se aplica a ocupados
      subgrupo_ocupacao %in% c('11', '12', '13') ~ 1,
      .default = 0
    ),

    # Todos os cargos gerenciais: inclui a gerência júnior (subgrupo 14)
    cargo_gerencial_total = case_when(
      condicao_atividade != 'Ocupada' ~ NA,
      subgrupo_ocupacao %in% c('11', '12', '13', '14') ~ 1,
      .default = 0
    )
  )
```
:::


### Das variáveis aos indicadores

Cada indicador do curso é uma razão entre um numerador e um denominador, calculados com as variáveis originais e as derivadas acima. Os blocos 5 a 7 calculam esses indicadores; a tabela mostra de onde cada um sai.

Os códigos entre parênteses seguem a numeração usada pelo IBGE na publicação *Estatísticas de Gênero*. Na lista da ONU, a dimensão aparece em algarismos romanos: o indicador 1.3 daqui é o I.3 de lá, e o 4.3 é o IV.3.

::: {.callout-important}
## Duas idades mínimas: 14 e 15 anos

Os indicadores de trabalho deste relatório usam **duas idades mínimas diferentes**, e é preciso atenção para não misturá-las.

- **14 anos ou mais** é o padrão do IBGE. É a partir dessa idade que a PNAD Contínua investiga o trabalho e classifica as pessoas em ocupadas, desocupadas ou fora da força de trabalho. A variável `condicao_atividade` segue esse padrão.
- **15 anos ou mais** é a idade usada pelo CMIG nos indicadores em que a lista da ONU fixa a idade no próprio nome. Entre os indicadores do curso, isso vale para a **taxa de participação na força de trabalho (1.3)**, calculada para 15 anos ou mais e para 15 a 24 anos.

A regra adotada: **só usam 15 anos os indicadores que dizem isso explicitamente; todos os outros seguem o padrão de 14 anos.**

Em qualquer caso, **numerador e denominador se referem sempre à mesma população**. Na taxa de participação, as pessoas de 14 anos saem tanto da força de trabalho (numerador) quanto da população (denominador). Na prática, isso significa filtrar por `V2009 >= 15` antes de calcular.

A idade mínima muda o resultado do indicador. A coluna "Denominador" da tabela informa a idade usada em cada um.
:::

| Indicador (CMIG) | Tipo | Numerador | Denominador | Variáveis |
|---|---|---|---|---|
| **Trabalho** | | | | |
| Taxa de participação na força de trabalho, 15 anos ou mais (1.3) | Taxa | Pessoas de **15 anos ou mais** na força de trabalho (ocupadas + desocupadas) | Pessoas de **15 anos ou mais** | `condicao_atividade`, `V2009` |
| Taxa de participação na força de trabalho, 15 a 24 anos (1.3) | Taxa | Pessoas de **15 a 24 anos** na força de trabalho | Pessoas de **15 a 24 anos** | `condicao_atividade`, `V2009` |
| Nível de ocupação | Taxa | Pessoas ocupadas de 14 anos ou mais | Pessoas de 14 anos ou mais | `condicao_atividade` |
| Nível de ocupação com e sem criança de até 6 anos (1.15) | Taxa | Pessoas ocupadas de 25 a 54 anos | Pessoas de 25 a 54 anos, com e sem criança no domicílio | `condicao_atividade`, `V2009`, `crianca_ate_6` |
| Taxa de desocupação (1.10) | Taxa | Pessoas desocupadas de 14 anos ou mais | Pessoas de 14 anos ou mais na força de trabalho | `condicao_atividade` |
| Informalidade (1.9) | Taxa | Ocupados informais em atividades não agrícolas | Ocupados em atividades não agrícolas | `informal`, `atividade_agricola` |
| Ocupação em tempo parcial (1.14) | Taxa | Ocupados com até 30 horas habituais por semana | Pessoas ocupadas | `VD4031`, `condicao_atividade` |
| Posição na ocupação: conta própria (1.4), trabalhador familiar auxiliar (1.5) e empregador (1.6) | Taxa | Ocupados em cada posição | Pessoas ocupadas | `VD4009` (9, 10 e 8), `condicao_atividade` |
| Ocupados por setor de atividade (1.8) | Distribuição | Ocupados em cada setor | Ocupados com setor definido | `setor` |
| Mulheres na gerência sênior e intermediária (4.3) | Taxa | Mulheres na gerência sênior e intermediária | Todas as pessoas na gerência sênior e intermediária | `cargo_gerencial`, `sexo` |
| Mulheres em todos os cargos gerenciais (4.3) | Taxa | Mulheres em cargos gerenciais, incluída a gerência júnior | Todas as pessoas em cargos gerenciais | `cargo_gerencial_total`, `sexo` |
| Mulheres entre os trabalhadores domésticos | Taxa | Mulheres no trabalho doméstico remunerado | Todas as pessoas no trabalho doméstico remunerado | `VD4009` (3 e 4), `sexo` |
| Carga total de trabalho (1.2) | Média | Soma das horas habituais de trabalho e das horas de cuidados e afazeres | Ocupados que realizaram cuidados ou afazeres | `VD4031`, `V4121B`, `condicao_atividade` |
| **Rendimento** | | | | |
| Rendimento médio habitual de todos os trabalhos | Média | Soma dos rendimentos | Ocupados com rendimento | `VD4019` |
| Razão de rendimento mulheres/homens (1.13) | Razão | Rendimento médio das mulheres | Rendimento médio dos homens | `VD4019`, `sexo`, `VD4011` (por grupo ocupacional) |
| **Educação** | | | | |
| Nível de instrução da população de 25 anos ou mais (2.11) | Distribuição | Pessoas em cada grupo de escolaridade | Pessoas de 25 anos ou mais | `escolaridade` |
| Frequência escolar bruta de 15 a 17 anos (2.3) | Taxa | Pessoas de 15 a 17 anos que frequentam escola | Pessoas de 15 a 17 anos | `V3002`, `V2009` |
| Frequência escolar bruta de 18 a 24 anos (2.4) | Taxa | Pessoas de 18 a 24 anos que frequentam escola | Pessoas de 18 a 24 anos | `V3002`, `V2009` |
| Taxa de conclusão do ensino fundamental (2.6) | Taxa | Pessoas de 17 a 19 anos com fundamental completo ou mais | Pessoas de 17 a 19 anos | `VD3004` (3 ou mais), `V2009` |
| Taxa de conclusão do ensino médio | Taxa | Pessoas de 20 a 22 anos com médio completo ou mais | Pessoas de 20 a 22 anos | `VD3004` (5 ou mais), `V2009` |
| Jovens que não estudam nem estão ocupados (1.7) | Taxa | Pessoas de 15 a 24 anos não ocupadas e que não frequentam escola | Pessoas de 15 a 24 anos | `condicao_atividade`, `V3002`, `V2009` |
| **Cuidados e afazeres domésticos** | | | | |
| Horas semanais em cuidados e afazeres (1.1) | Média | Soma das horas dedicadas | Pessoas de 14 anos ou mais que realizaram cuidados ou afazeres | `V4121B` |
| Taxa de realização de afazeres domésticos | Taxa | Pessoas que realizaram afazeres | Pessoas de 14 anos ou mais | `realizou_afazeres` |
| Taxa de realização de cuidados de pessoas | Taxa | Pessoas que realizaram cuidados | Pessoas de 14 anos ou mais | `realizou_cuidados` |

: Todos os indicadores podem ser desagregados por `cor_raca`, `faixa_etaria`, `regiao`, `territorio` e `situacao`, sempre cruzando com `sexo`.

::: {.callout-note}
## Cuidados na leitura da tabela
- **Pessoas ocupadas:** nos indicadores calculados entre os ocupados (informalidade, tempo parcial, posição na ocupação, setor, cargos gerenciais e rendimento), a população são os ocupados de 14 anos ou mais, o padrão do IBGE.
- **Carga total de trabalho:** calculada com as horas habituais de trabalho. É uma aproximação, porque a definição exata usada no informativo não foi identificada.
- **Indicadores de educação:** o informativo usa o 2º trimestre, que tem o módulo ampliado de educação. Com a 5ª visita, os resultados ficam próximos, mas não idênticos.
- **Horas em cuidados e afazeres:** o denominador é quem realizou as atividades, e não toda a população de 14 anos ou mais. A pergunta das horas (`V4121B`) só é feita a quem respondeu "sim" a alguma delas.
- **Jovens que não estudam nem estão ocupados:** o informativo também exclui quem estava em curso de qualificação profissional, informação que não está na base do curso. Por isso, o indicador calculado aqui inclui mais pessoas e tende a ficar acima do publicado.
- **Taxas de realização de afazeres e de cuidados:** não estão no informativo, mas complementam a média de horas: mostram quantas pessoas realizam as atividades, e não só quanto tempo dedicam.
:::

## 5. Primeiras estimativas e primeiros gráficos

Este bloco calcula todos os indicadores da tabela acima com o `dplyr`, para o Brasil e para as UFs escolhidas nos parâmetros. O `dplyr` é rápido e basta para obter as **estimativas pontuais**, desde que o peso amostral **com calibração** seja usado. O que ele não faz é dizer o quão preciso é cada número: isso fica para o bloco 6.

::: {.callout-note}
## Cálculo de estimativas usando o pacote `dplyr`
Sempre se usará o peso **com calibração** para o cálculo das estimativas pontuais usando o pacote `dplyr`. Não se deve usar o peso **sem calibração**. Isso levará a estimativas pontuais erradas.
:::

### Os estimadores

Todos os indicadores do relatório são construídos a partir de **totais estimados**. A notação usada a seguir:

- $s$ é a amostra, e $i$ é uma pessoa entrevistada;
- $\pi_i$ é a probabilidade de a pessoa $i$ ter sido sorteada;
- $w_i$ é o peso da pessoa $i$ (`V1032`);
- $y_i$ é o valor de uma variável para a pessoa $i$.

**Total.** O estimador de Horvitz-Thompson soma os valores da amostra, cada um multiplicado pelo inverso da sua probabilidade de seleção:

$$
\hat{Y}_{HT} = \sum_{i \in s} \frac{y_i}{\pi_i}
$$

Ele é **não viesado**: em média, sobre todas as amostras possíveis, acerta o total da população. A ideia é que cada pessoa entrevistada representa $1/\pi_i$ pessoas da população.

O peso `V1032` parte desse inverso da probabilidade e recebe dois ajustes do IBGE: a correção para os domicílios que não responderam e a **calibração**, que faz os totais da amostra baterem com as projeções de população. O total estimado no relatório é, então:

$$
\hat{Y} = \sum_{i \in s} w_i \, y_i
$$

Com a calibração, esse estimador deixa de ser exatamente o de Horvitz-Thompson, mas mantém a mesma lógica e é aproximadamente não viesado. Um caso particular é o **tamanho da população**, obtido com $y_i = 1$ para todos: $\hat{N} = \sum_{i \in s} w_i$.

**Média.** A média é a razão entre dois totais estimados, o total da variável e o tamanho da população:

$$
\hat{\bar{Y}} = \frac{\hat{Y}}{\hat{N}} = \frac{\sum_{i \in s} w_i \, y_i}{\sum_{i \in s} w_i}
$$

**Razão.** De forma geral, a razão entre os totais de duas variáveis é:

$$
\hat{R} = \frac{\hat{Y}}{\hat{X}} = \frac{\sum_{i \in s} w_i \, y_i}{\sum_{i \in s} w_i \, x_i}
$$

**Taxa e média num grupo da população.** Os indicadores não se referem à população inteira, mas a um grupo: as pessoas de 15 anos ou mais, os ocupados, as mulheres. Esse grupo é o **denominador** do indicador. Na amostra, ele é o conjunto $D$ das pessoas entrevistadas que pertencem ao grupo.

- **Taxa.** O **numerador** é o conjunto $N$ das pessoas do denominador que têm a característica medida. O numerador está sempre contido no denominador ($N \subseteq D$): a condição para estar no numerador é a condição do denominador **mais** a condição própria do indicador. A taxa é a razão entre o total estimado de pessoas do numerador e o total estimado de pessoas do denominador:

$$
\hat{T} = \frac{\sum_{i \in N} w_i}{\sum_{i \in D} w_i} \times 100, \qquad N \subseteq D
$$

- **Média no grupo.** A razão entre o total da variável e o total de pessoas, calculados só entre as pessoas do denominador:

$$
\hat{\bar{Y}}_D = \frac{\sum_{i \in D} w_i \, y_i}{\sum_{i \in D} w_i}
$$

Na taxa de participação na força de trabalho, por exemplo, o denominador $D$ são as pessoas de 15 anos ou mais, e o numerador $N$ são as pessoas de 15 anos ou mais **que estão na força de trabalho**. As funções `taxa()` e `media()`, mais adiante, são essas duas fórmulas escritas em código.

### Os recortes: Brasil e UFs escolhidas

O parâmetro `ufs` traz as siglas das UFs. Na base, a UF é um código numérico, e a tabela abaixo faz a ponte entre os dois.


::: {.cell}

```{.r .cell-code}
tabela_ufs <- tribble(
  ~UF, ~sigla, ~nome_uf,
  11, 'RO', 'Rondônia',
  12, 'AC', 'Acre',
  13, 'AM', 'Amazonas',
  14, 'RR', 'Roraima',
  15, 'PA', 'Pará',
  16, 'AP', 'Amapá',
  17, 'TO', 'Tocantins',
  21, 'MA', 'Maranhão',
  22, 'PI', 'Piauí',
  23, 'CE', 'Ceará',
  24, 'RN', 'Rio Grande do Norte',
  25, 'PB', 'Paraíba',
  26, 'PE', 'Pernambuco',
  27, 'AL', 'Alagoas',
  28, 'SE', 'Sergipe',
  29, 'BA', 'Bahia',
  31, 'MG', 'Minas Gerais',
  32, 'ES', 'Espírito Santo',
  33, 'RJ', 'Rio de Janeiro',
  35, 'SP', 'São Paulo',
  41, 'PR', 'Paraná',
  42, 'SC', 'Santa Catarina',
  43, 'RS', 'Rio Grande do Sul',
  50, 'MS', 'Mato Grosso do Sul',
  51, 'MT', 'Mato Grosso',
  52, 'GO', 'Goiás',
  53, 'DF', 'Distrito Federal'
)

# Confere as siglas informadas no parâmetro
siglas_invalidas <- setdiff(ufs, tabela_ufs$sigla)
if (length(siglas_invalidas) > 0) {
  stop(
    'Sigla de UF não reconhecida: ', paste(siglas_invalidas, collapse = ', '),
    '. Use siglas como RJ, SP ou BA.',
    call. = FALSE
  )
}

ufs_escolhidas <- tabela_ufs |>
  filter(sigla %in% ufs)
```
:::


Para calcular tudo de uma vez, a base é empilhada: uma cópia inteira com o rótulo "Brasil" e, para cada UF escolhida, as linhas daquela UF com o nome dela. A coluna `recorte` passa a dizer a que território cada linha pertence, e um `group_by(recorte)` calcula os indicadores de todos os territórios no mesmo comando.


::: {.cell}

```{.r .cell-code}
pnadc_recortes <- bind_rows(
  pnadc |>
    mutate(recorte = 'Brasil'),
  pnadc |>
    inner_join(ufs_escolhidas, by = 'UF') |>
    mutate(recorte = nome_uf)
) |>
  mutate(
    recorte = factor(recorte, levels = c('Brasil', ufs_escolhidas$nome_uf))
  )

pnadc_recortes |>
  count(recorte, name = 'pessoas_na_amostra') |>
  knitr::kable(
    format.args = list(big.mark = '.', decimal.mark = ','),
    col.names = c('Recorte', 'Pessoas na amostra')
  )
```

::: {.cell-output-display}


|Recorte        | Pessoas na amostra|
|:--------------|------------------:|
|Brasil         |            380.928|
|Rio de Janeiro |             26.616|


:::
:::


::: {.callout-note}
## Uma pessoa, dois recortes
Na base empilhada, quem mora numa UF escolhida aparece duas vezes: uma no Brasil e outra na sua UF. Isso é intencional, porque cada recorte é calculado em separado. A base empilhada serve só para os cálculos por recorte e não deve ser usada para totais.
:::

### A mesma pergunta, duas respostas

O primeiro indicador é a **taxa de participação na força de trabalho** (CMIG 1.3): entre as pessoas de 15 anos ou mais, a taxa das que estão na força de trabalho, ocupadas ou desocupadas. Como a idade é a de 15 anos, o filtro `V2009 >= 15` vem antes de tudo, e vale para o numerador e para o denominador.

A PNAD Contínua é uma amostra, e as pessoas não têm todas a mesma chance de serem sorteadas. Cada pessoa entrevistada representa um número diferente de pessoas da população, e esse número é o seu **peso com calibração** (`V1032`). O bloco abaixo calcula a taxa de duas formas:

- **sem peso**: a taxa entre as pessoas entrevistadas, como se cada uma valesse por uma;
- **com peso**: infere o que a amostra representa para a população.


::: {#tbl-participacao-sem-com-peso .cell tbl-cap='Taxa de participação na força de trabalho das pessoas de 15 anos ou mais (CMIG 1.3), sem peso e com peso, por sexo. Fonte: IBGE, PNAD Contínua, 5ª visita, 2022.'}

```{.r .cell-code}
participacao <- pnadc_recortes |>
  filter(V2009 >= 15) |>
  mutate(
    # Dummy: 1 para quem está na força de trabalho, 0 para quem não está
    na_forca_trabalho = if_else(
      condicao_atividade %in% c('Ocupada', 'Desocupada'), 1, 0
    )
  ) |>
  group_by(recorte, sexo) |>
  summarise(
    pessoas_na_amostra = n(),
    # Sem peso: cada pessoa entrevistada vale 1
    sem_peso = sum(na_forca_trabalho) / n() * 100,
    # Com peso: os dois totais estimados da fórmula da razão
    total_forca_trabalho = sum(V1032 * na_forca_trabalho), # Y chapéu
    total_populacao = sum(V1032), # N chapéu
    com_peso = total_forca_trabalho / total_populacao * 100,
    .groups = 'drop'
  ) |>
  mutate(diferenca = com_peso - sem_peso)

participacao |>
  knitr::kable(
    digits = c(0, 0, 0, 1, 0, 0, 1, 1),
    format.args = list(big.mark = '.', decimal.mark = ','),
    col.names = c(
      'Recorte', 'Sexo', 'Pessoas na amostra', 'Taxa sem peso (%)',
      'Pessoas na força de trabalho', 'Pessoas de 15 anos ou mais',
      'Taxa com peso (%)', 'Diferença (p.p.)'
    )
  )
```

::: {.cell-output-display}


|Recorte        |Sexo   | Pessoas na amostra| Taxa sem peso (%)| Pessoas na força de trabalho| Pessoas de 15 anos ou mais| Taxa com peso (%)| Diferença (p.p.)|
|:--------------|:------|------------------:|-----------------:|----------------------------:|--------------------------:|-----------------:|----------------:|
|Brasil         |Homem  |            147.308|              67,7|                   58.812.033|                 80.526.685|              73,0|              5,3|
|Brasil         |Mulher |            160.902|              47,3|                   46.258.719|                 86.670.579|              53,4|              6,0|
|Rio de Janeiro |Homem  |             10.236|              67,6|                    4.707.557|                  6.611.129|              71,2|              3,6|
|Rio de Janeiro |Mulher |             12.417|              48,7|                    4.015.605|                  7.711.972|              52,1|              3,4|


:::
:::


A coluna "Diferença" mostra o tamanho do erro de ignorar o peso. A estimativa correta é sempre a **com peso**: é ela que se refere à população, e não às pessoas que por acaso foram entrevistadas.

### Todos os indicadores

Todos os indicadores da tabela do bloco 4 são de dois tipos: uma **taxa ou razão** (quantas pessoas atendem a uma condição, entre as pessoas de uma população) ou uma **média** (o valor médio de uma variável numa população). Duas funções pequenas resolvem os dois casos, sempre com o peso:


::: {.cell}

```{.r .cell-code}
# Taxa, em %: soma dos pesos do numerador dividida pela soma dos pesos do
# denominador. O %in% TRUE trata como "não" os casos em que a condição não se
# aplica (NA).
taxa <- function(numerador, denominador, peso) {
  numerador <- numerador %in% TRUE
  denominador <- denominador %in% TRUE

  # O numerador tem que estar contido no denominador
  if (any(numerador & !denominador)) {
    stop(
      'O numerador tem pessoas que não estão no denominador. ',
      'Inclua no numerador a condição do denominador.',
      call. = FALSE
    )
  }

  sum(peso[numerador]) / sum(peso[denominador]) * 100
}

# Média ponderada da variável entre as pessoas do denominador com valor informado
media <- function(valor, denominador, peso) {
  denominador <- denominador %in% TRUE & !is.na(valor)
  sum(peso[denominador] * valor[denominador]) / sum(peso[denominador])
}
```
:::


As duas funções são as fórmulas da seção "Os estimadores": `taxa()` calcula $\hat{T}$, e `media()` calcula $\hat{\bar{Y}}_D$. Os argumentos `numerador` e `denominador` são condições que definem os conjuntos $N$ e $D$, e `peso` é o $w_i$. É a tabela do bloco 4 escrita em código.

Como o numerador está sempre contido no denominador, cada condição de numerador abaixo **repete a condição do denominador** e acrescenta a sua. Se a condição do denominador for esquecida, o numerador pode incluir pessoas de fora do grupo, e a taxa sai errada sem nenhum aviso. Por isso, a função `taxa()` confere essa regra e interrompe o cálculo quando ela não é cumprida.


::: {.cell}

```{.r .cell-code}
indicadores_sexo <- pnadc_recortes |>
  mutate(
    idade = V2009,
    # Dummies da condição de atividade (1 = sim, 0 = não)
    ocupada = if_else(condicao_atividade %in% 'Ocupada', 1, 0),
    desocupada = if_else(condicao_atividade %in% 'Desocupada', 1, 0),
    # Força de trabalho = ocupados + desocupados: a soma de duas dummies
    forca_trabalho = ocupada + desocupada,
    estuda = if_else(V3002 %in% 1, 1, 0)
  ) |>
  group_by(recorte, sexo) |>
  summarise(
    # Trabalho
    participacao_15 = taxa(
      numerador = idade >= 15 & forca_trabalho == 1,
      denominador = idade >= 15,
      peso = V1032
    ),
    participacao_15_24 = taxa(
      numerador = idade >= 15 & idade <= 24 & forca_trabalho == 1,
      denominador = idade >= 15 & idade <= 24,
      peso = V1032
    ),
    nivel_ocupacao = taxa(
      numerador = idade >= 14 & ocupada == 1,
      denominador = idade >= 14,
      peso = V1032
    ),
    ocupacao_com_crianca = taxa(
      numerador = idade >= 25 & idade <= 54 & crianca_ate_6 == 1 & ocupada == 1,
      denominador = idade >= 25 & idade <= 54 & crianca_ate_6 == 1,
      peso = V1032
    ),
    ocupacao_sem_crianca = taxa(
      numerador = idade >= 25 & idade <= 54 & crianca_ate_6 == 0 & ocupada == 1,
      denominador = idade >= 25 & idade <= 54 & crianca_ate_6 == 0,
      peso = V1032
    ),
    desocupacao = taxa(
      numerador = forca_trabalho == 1 & desocupada == 1,
      denominador = forca_trabalho == 1,
      peso = V1032
    ),
    informalidade = taxa(
      numerador = ocupada == 1 & atividade_agricola == 0 & informal == 1,
      denominador = ocupada == 1 & atividade_agricola == 0,
      peso = V1032
    ),
    tempo_parcial = taxa(
      numerador = ocupada == 1 & VD4031 <= 30,
      denominador = ocupada == 1,
      peso = V1032
    ),
    conta_propria = taxa(
      numerador = ocupada == 1 & VD4009 == 9,
      denominador = ocupada == 1,
      peso = V1032
    ),
    familiar_auxiliar = taxa(
      numerador = ocupada == 1 & VD4009 == 10,
      denominador = ocupada == 1,
      peso = V1032
    ),
    empregador = taxa(
      numerador = ocupada == 1 & VD4009 == 8,
      denominador = ocupada == 1,
      peso = V1032
    ),
    setor_agropecuaria = taxa(
      numerador = ocupada == 1 & !is.na(setor) & setor == 'Agropecuária',
      denominador = ocupada == 1 & !is.na(setor),
      peso = V1032
    ),
    setor_industria = taxa(
      numerador = ocupada == 1 & !is.na(setor) & setor == 'Indústria',
      denominador = ocupada == 1 & !is.na(setor),
      peso = V1032
    ),
    setor_servicos = taxa(
      numerador = ocupada == 1 & !is.na(setor) & setor == 'Serviços',
      denominador = ocupada == 1 & !is.na(setor),
      peso = V1032
    ),
    carga_total = media(
      valor = VD4031 + V4121B,
      denominador = ocupada == 1,
      peso = V1032
    ),

    # Rendimento
    rendimento = media(
      valor = VD4019,
      denominador = ocupada == 1,
      peso = V1032
    ),

    # Educação
    instrucao_fundamental_incompleto = taxa(
      numerador = idade >= 25 & VD3004 %in% 1:2,
      denominador = idade >= 25,
      peso = V1032
    ),
    instrucao_medio_incompleto = taxa(
      numerador = idade >= 25 & VD3004 %in% 3:4,
      denominador = idade >= 25,
      peso = V1032
    ),
    instrucao_superior_incompleto = taxa(
      numerador = idade >= 25 & VD3004 %in% 5:6,
      denominador = idade >= 25,
      peso = V1032
    ),
    instrucao_superior_completo = taxa(
      numerador = idade >= 25 & VD3004 == 7,
      denominador = idade >= 25,
      peso = V1032
    ),
    frequencia_15_17 = taxa(
      numerador = idade >= 15 & idade <= 17 & estuda == 1,
      denominador = idade >= 15 & idade <= 17,
      peso = V1032
    ),
    frequencia_18_24 = taxa(
      numerador = idade >= 18 & idade <= 24 & estuda == 1,
      denominador = idade >= 18 & idade <= 24,
      peso = V1032
    ),
    conclusao_fundamental = taxa(
      numerador = idade >= 17 & idade <= 19 & VD3004 >= 3,
      denominador = idade >= 17 & idade <= 19,
      peso = V1032
    ),
    conclusao_medio = taxa(
      numerador = idade >= 20 & idade <= 22 & VD3004 >= 5,
      denominador = idade >= 20 & idade <= 22,
      peso = V1032
    ),
    nao_estuda_nem_ocupado = taxa(
      numerador = idade >= 15 & idade <= 24 & estuda == 0 & ocupada == 0,
      denominador = idade >= 15 & idade <= 24,
      peso = V1032
    ),

    # Cuidados e afazeres domésticos
    horas_afazeres = media(
      valor = V4121B,
      denominador = idade >= 14,
      peso = V1032
    ),
    taxa_afazeres = taxa(
      numerador = idade >= 14 & realizou_afazeres == 1,
      denominador = idade >= 14,
      peso = V1032
    ),
    taxa_cuidados = taxa(
      numerador = idade >= 14 & realizou_cuidados == 1,
      denominador = idade >= 14,
      peso = V1032
    ),
    .groups = 'drop'
  )
```
:::


Quatro indicadores não se calculam para cada sexo, porque comparam os dois: a participação das mulheres num grupo e a razão entre os rendimentos.


::: {.cell}

```{.r .cell-code}
indicadores_comparacao <- pnadc_recortes |>
  mutate(
    mulher = if_else(sexo == 'Mulher', 1, 0),
    ocupada = if_else(condicao_atividade %in% 'Ocupada', 1, 0)
  ) |>
  group_by(recorte) |>
  summarise(
    mulheres_gerencia = taxa(
      numerador = cargo_gerencial == 1 & mulher == 1,
      denominador = cargo_gerencial == 1,
      peso = V1032
    ),
    mulheres_gerencia_total = taxa(
      numerador = cargo_gerencial_total == 1 & mulher == 1,
      denominador = cargo_gerencial_total == 1,
      peso = V1032
    ),
    mulheres_domesticas = taxa(
      numerador = ocupada == 1 & VD4009 %in% 3:4 & mulher == 1,
      denominador = ocupada == 1 & VD4009 %in% 3:4,
      peso = V1032
    ),
    # Razão entre duas médias: a das mulheres e a dos homens ocupados
    razao_rendimento = media(
      valor = VD4019,
      denominador = ocupada == 1 & mulher == 1,
      peso = V1032
    ) / media(
      valor = VD4019,
      denominador = ocupada == 1 & mulher == 0,
      peso = V1032
    ) * 100,
    .groups = 'drop'
  )
```
:::


Os nomes das colunas são curtos para facilitar o código. A tabela abaixo dá a cada um o nome completo, a dimensão e a unidade, e é usada nas tabelas e nos gráficos.


::: {.cell}

```{.r .cell-code}
nomes_indicadores <- tribble(
  ~variavel, ~dimensao, ~indicador, ~unidade,
  'participacao_15', 'Trabalho', 'Taxa de participação, 15 anos ou mais (1.3)', '%',
  'participacao_15_24', 'Trabalho', 'Taxa de participação, 15 a 24 anos (1.3)', '%',
  'nivel_ocupacao', 'Trabalho', 'Nível de ocupação, 14 anos ou mais', '%',
  'ocupacao_com_crianca', 'Trabalho', 'Nível de ocupação, 25 a 54 anos, com criança de até 6 anos (1.15)', '%',
  'ocupacao_sem_crianca', 'Trabalho', 'Nível de ocupação, 25 a 54 anos, sem criança de até 6 anos (1.15)', '%',
  'desocupacao', 'Trabalho', 'Taxa de desocupação (1.10)', '%',
  'informalidade', 'Trabalho', 'Informalidade no trabalho não agrícola (1.9)', '%',
  'tempo_parcial', 'Trabalho', 'Ocupação em tempo parcial (1.14)', '%',
  'conta_propria', 'Trabalho', 'Conta própria entre os ocupados (1.4)', '%',
  'familiar_auxiliar', 'Trabalho', 'Trabalhador familiar auxiliar entre os ocupados (1.5)', '%',
  'empregador', 'Trabalho', 'Empregador entre os ocupados (1.6)', '%',
  'setor_agropecuaria', 'Trabalho', 'Ocupados na agropecuária (1.8)', '%',
  'setor_industria', 'Trabalho', 'Ocupados na indústria (1.8)', '%',
  'setor_servicos', 'Trabalho', 'Ocupados nos serviços (1.8)', '%',
  'carga_total', 'Trabalho', 'Carga total de trabalho (1.2)', 'horas',
  'rendimento', 'Rendimento', 'Rendimento médio habitual de todos os trabalhos', 'R$',
  'instrucao_fundamental_incompleto', 'Educação', '25 anos ou mais: sem instrução e fundamental incompleto (2.11)', '%',
  'instrucao_medio_incompleto', 'Educação', '25 anos ou mais: fundamental completo e médio incompleto (2.11)', '%',
  'instrucao_superior_incompleto', 'Educação', '25 anos ou mais: médio completo e superior incompleto (2.11)', '%',
  'instrucao_superior_completo', 'Educação', '25 anos ou mais: superior completo (2.11)', '%',
  'frequencia_15_17', 'Educação', 'Frequência escolar, 15 a 17 anos (2.3)', '%',
  'frequencia_18_24', 'Educação', 'Frequência escolar, 18 a 24 anos (2.4)', '%',
  'conclusao_fundamental', 'Educação', 'Conclusão do ensino fundamental, 17 a 19 anos (2.6)', '%',
  'conclusao_medio', 'Educação', 'Conclusão do ensino médio, 20 a 22 anos', '%',
  'nao_estuda_nem_ocupado', 'Educação', 'Jovens de 15 a 24 anos que não estudam nem estão ocupados (1.7)', '%',
  'horas_afazeres', 'Cuidados e afazeres', 'Horas semanais em cuidados e afazeres (1.1)', 'horas',
  'taxa_afazeres', 'Cuidados e afazeres', 'Taxa de realização de afazeres domésticos', '%',
  'taxa_cuidados', 'Cuidados e afazeres', 'Taxa de realização de cuidados de pessoas', '%',
  'mulheres_gerencia', 'Comparação', 'Mulheres na gerência sênior e intermediária (4.3)', '%',
  'mulheres_gerencia_total', 'Comparação', 'Mulheres em todos os cargos gerenciais (4.3)', '%',
  'mulheres_domesticas', 'Comparação', 'Mulheres entre os trabalhadores domésticos', '%',
  'razao_rendimento', 'Comparação', 'Razão de rendimento mulheres/homens (1.13)', '%'
) |>
  mutate(
    dimensao = factor(dimensao, levels = unique(dimensao)),
    indicador = factor(indicador, levels = indicador)
  )

# Formato dos números: sem casas decimais para reais, uma casa para o resto
formata_valor <- function(valor, unidade) {
  if_else(
    unidade == 'R$',
    scales::number(valor, accuracy = 1, big.mark = '.', decimal.mark = ','),
    scales::number(valor, accuracy = 0.1, big.mark = '.', decimal.mark = ',')
  )
}
```
:::


Para a tabela e para os gráficos, os resultados passam do formato largo, com uma coluna por indicador, para o formato longo, com uma linha por indicador.


::: {.cell}

```{.r .cell-code}
indicadores_sexo_longo <- indicadores_sexo |>
  pivot_longer(
    cols = -c(recorte, sexo), names_to = 'variavel', values_to = 'valor'
  ) |>
  inner_join(nomes_indicadores, by = 'variavel')

indicadores_comparacao_longo <- indicadores_comparacao |>
  pivot_longer(cols = -recorte, names_to = 'variavel', values_to = 'valor') |>
  inner_join(nomes_indicadores, by = 'variavel')
```
:::



::: {#tbl-indicadores-sexo .cell tbl-cap='Indicadores por sexo, Brasil e UFs escolhidas. Fonte: IBGE, PNAD Contínua, 5ª visita, 2022.'}

```{.r .cell-code}
indicadores_sexo_longo |>
  mutate(
    valor = formata_valor(valor, unidade),
    coluna = paste(recorte, sexo, sep = ': ')
  ) |>
  arrange(indicador, recorte, sexo) |>
  select(dimensao, indicador, unidade, coluna, valor) |>
  pivot_wider(names_from = coluna, values_from = valor) |>
  rename(Dimensão = dimensao, Indicador = indicador, Unidade = unidade) |>
  knitr::kable(
    align = c('l', 'l', 'c', rep('r', 2 * nlevels(pnadc_recortes$recorte)))
  )
```

::: {.cell-output-display}


|Dimensão            |Indicador                                                         | Unidade | Brasil: Homem| Brasil: Mulher| Rio de Janeiro: Homem| Rio de Janeiro: Mulher|
|:-------------------|:-----------------------------------------------------------------|:-------:|-------------:|--------------:|---------------------:|----------------------:|
|Trabalho            |Taxa de participação, 15 anos ou mais (1.3)                       |    %    |          73,0|           53,4|                  71,2|                   52,1|
|Trabalho            |Taxa de participação, 15 a 24 anos (1.3)                          |    %    |          61,7|           50,1|                  53,0|                   47,1|
|Trabalho            |Nível de ocupação, 14 anos ou mais                                |    %    |          66,1|           46,4|                  62,3|                   43,3|
|Trabalho            |Nível de ocupação, 25 a 54 anos, com criança de até 6 anos (1.15) |    %    |          89,0|           56,6|                  88,9|                   57,8|
|Trabalho            |Nível de ocupação, 25 a 54 anos, sem criança de até 6 anos (1.15) |    %    |          82,8|           66,2|                  82,6|                   64,9|
|Trabalho            |Taxa de desocupação (1.10)                                        |    %    |           7,9|           11,8|                  11,2|                   15,7|
|Trabalho            |Informalidade no trabalho não agrícola (1.9)                      |    %    |          37,3|           39,7|                  35,3|                   38,8|
|Trabalho            |Ocupação em tempo parcial (1.14)                                  |    %    |          14,4|           28,1|                  13,1|                   27,2|
|Trabalho            |Conta própria entre os ocupados (1.4)                             |    %    |          29,9|           21,2|                  30,0|                   24,4|
|Trabalho            |Trabalhador familiar auxiliar entre os ocupados (1.5)             |    %    |           1,1|            2,6|                   0,2|                    0,5|
|Trabalho            |Empregador entre os ocupados (1.6)                                |    %    |           5,1|            3,0|                   3,7|                    2,3|
|Trabalho            |Ocupados na agropecuária (1.8)                                    |    %    |          12,4|            4,1|                   2,1|                    0,3|
|Trabalho            |Ocupados na indústria (1.8)                                       |    %    |          27,4|           10,7|                  22,8|                    7,0|
|Trabalho            |Ocupados nos serviços (1.8)                                       |    %    |          60,2|           85,1|                  75,1|                   92,7|
|Trabalho            |Carga total de trabalho (1.2)                                     |  horas  |          52,6|           55,0|                  53,5|                   54,9|
|Rendimento          |Rendimento médio habitual de todos os trabalhos                   |   R$    |         2.912|          2.293|                 3.491|                  2.876|
|Educação            |25 anos ou mais: sem instrução e fundamental incompleto (2.11)    |    %    |          35,3|           32,3|                  23,5|                   24,3|
|Educação            |25 anos ou mais: fundamental completo e médio incompleto (2.11)   |    %    |          13,6|           12,1|                  13,8|                   12,7|
|Educação            |25 anos ou mais: médio completo e superior incompleto (2.11)      |    %    |          34,3|           34,1|                  41,1|                   37,7|
|Educação            |25 anos ou mais: superior completo (2.11)                         |    %    |          16,8|           21,4|                  21,7|                   25,3|
|Educação            |Frequência escolar, 15 a 17 anos (2.3)                            |    %    |          92,1|           92,4|                  94,7|                   96,6|
|Educação            |Frequência escolar, 18 a 24 anos (2.4)                            |    %    |          29,7|           33,7|                  35,8|                   38,7|
|Educação            |Conclusão do ensino fundamental, 17 a 19 anos (2.6)               |    %    |          87,2|           92,5|                  90,1|                   93,5|
|Educação            |Conclusão do ensino médio, 20 a 22 anos                           |    %    |          68,6|           77,6|                  69,1|                   80,3|
|Educação            |Jovens de 15 a 24 anos que não estudam nem estão ocupados (1.7)   |    %    |          16,6|           25,9|                  20,9|                   28,7|
|Cuidados e afazeres |Horas semanais em cuidados e afazeres (1.1)                       |  horas  |          11,7|           21,3|                  12,5|                   20,1|
|Cuidados e afazeres |Taxa de realização de afazeres domésticos                         |    %    |          79,1|           91,4|                  84,1|                   91,0|
|Cuidados e afazeres |Taxa de realização de cuidados de pessoas                         |    %    |          23,1|           34,7|                  22,5|                   29,9|


:::
:::



::: {#tbl-indicadores-comparacao .cell tbl-cap='Indicadores de comparação entre mulheres e homens, Brasil e UFs escolhidas. Fonte: IBGE, PNAD Contínua, 5ª visita, 2022.'}

```{.r .cell-code}
indicadores_comparacao_longo |>
  mutate(valor = formata_valor(valor, unidade)) |>
  arrange(indicador, recorte) |>
  select(indicador, unidade, recorte, valor) |>
  pivot_wider(names_from = recorte, values_from = valor) |>
  rename(Indicador = indicador, Unidade = unidade) |>
  knitr::kable(
    align = c('l', 'c', rep('r', nlevels(pnadc_recortes$recorte)))
  )
```

::: {.cell-output-display}


|Indicador                                         | Unidade | Brasil| Rio de Janeiro|
|:-------------------------------------------------|:-------:|------:|--------------:|
|Mulheres na gerência sênior e intermediária (4.3) |    %    |   39,5|           38,0|
|Mulheres em todos os cargos gerenciais (4.3)      |    %    |   40,7|           37,7|
|Mulheres entre os trabalhadores domésticos        |    %    |   91,5|           90,7|
|Razão de rendimento mulheres/homens (1.13)        |    %    |   78,7|           82,4|


:::
:::


::: {.callout-warning}
## O peso acerta a estimativa, mas não diz o quão precisa ela é.
As tabelas trazem um número para cada indicador, sem erro-padrão, intervalo de confiança ou coeficiente de variação. Numa UF, a amostra é bem menor que a do Brasil, e alguns indicadores podem se apoiar em poucas pessoas entrevistadas. Antes de comparar dois números ou tirar conclusões, é preciso medir a precisão de cada estimador. Para isso, é preciso declarar o desenho amostral, que é o assunto do bloco 6.
:::

### Os gráficos

Os gráficos partem das tabelas no formato longo. As cores seguem a publicação do IBGE, com os homens em roxo e as mulheres em laranja, e são guardadas num objeto para todos os gráficos do relatório.

Uma função desenha o gráfico de uma dimensão: barras horizontais, um painel para cada recorte e uma barra para cada sexo. O `ggplotly()` converte o gráfico do `ggplot2` em gráfico interativo.


::: {.cell}

```{.r .cell-code}
cores_sexo <- c('Homem' = '#5b4a9b', 'Mulher' = '#e8793a')

# Legenda no topo, à esquerda dos painéis (acima dos nomes dos indicadores),
# para não cobrir os títulos dos painéis
legenda_topo <- list(
  orientation = 'h', x = 0, xanchor = 'right', y = 1, yanchor = 'bottom'
)

# A altura do gráfico vem da opção fig-height de cada bloco
grafico_indicadores <- function(dados, rotulo_eixo) {
  grafico <- dados |>
    mutate(
      # Os nomes longos são quebrados em linhas; a ordem segue a da tabela
      indicador = factor(
        str_wrap(indicador, 38),
        levels = rev(str_wrap(levels(droplevels(indicador)), 38))
      ),
      # Texto que o plotly mostra ao passar o mouse sobre a barra
      texto = paste0(
        recorte, '<br>', sexo, ': ', formata_valor(valor, unidade), ' ', unidade
      )
    ) |>
    ggplot(aes(x = valor, y = indicador, fill = sexo, text = texto)) +
    geom_col(position = position_dodge(width = 0.8), width = 0.7) +
    facet_wrap(vars(recorte)) +
    scale_fill_manual(values = cores_sexo) +
    labs(x = rotulo_eixo, y = NULL, fill = NULL) +
    theme_minimal() +
    theme(legend.position = 'top', panel.grid.major.y = element_blank())

  ggplotly(grafico, tooltip = 'text') |>
    layout(legend = legenda_topo) |>
    config(displayModeBar = FALSE)
}
```
:::



::: {.cell}

```{.r .cell-code}
indicadores_sexo_longo |>
  filter(dimensao == 'Trabalho', unidade == '%') |>
  grafico_indicadores(rotulo_eixo = '%')
```

::: {#fig-trabalho .cell-output-display}

```{=html}
<div class="plotly html-widget html-fill-item" id="htmlwidget-a83de33b9e6c4c249656" style="width:100%;height:882px;"></div>
<script type="application/json" data-for="htmlwidget-a83de33b9e6c4c249656">{"x":{"data":[{"orientation":"v","width":[73.034216043689526,61.652878785329825,66.128305822761519,88.956135874324204,82.844690664848798,7.8574652385282233,37.298452600181527,14.444618733546774,29.856882095393665,1.1481846277013592,5.1416856658817265,12.436075871023435,27.388194902488067,60.175729226488492],"base":[13.625,12.625,11.625,10.625,9.625,8.625,7.625,6.625,5.625,4.625,3.625,2.625,1.625,0.625],"x":[36.517108021844763,30.826439392664913,33.064152911380759,44.478067937162102,41.422345332424399,3.9287326192641117,18.649226300090763,7.2223093667733869,14.928441047696833,0.5740923138506796,2.5708428329408632,6.2180379355117177,13.694097451244033,30.087864613244246],"y":[0.35000000000000142,0.35000000000000142,0.35000000000000142,0.35000000000000142,0.35000000000000142,0.35000000000000142,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.35000000000000009,0.35000000000000009],"text":["Brasil<br>Homem: 73,0 %","Brasil<br>Homem: 61,7 %","Brasil<br>Homem: 66,1 %","Brasil<br>Homem: 89,0 %","Brasil<br>Homem: 82,8 %","Brasil<br>Homem: 7,9 %","Brasil<br>Homem: 37,3 %","Brasil<br>Homem: 14,4 %","Brasil<br>Homem: 29,9 %","Brasil<br>Homem: 1,1 %","Brasil<br>Homem: 5,1 %","Brasil<br>Homem: 12,4 %","Brasil<br>Homem: 27,4 %","Brasil<br>Homem: 60,2 %"],"type":"bar","textposition":"none","marker":{"autocolorscale":false,"color":"rgba(91,74,155,1)","line":{"width":1.8897637795275593,"color":"transparent"}},"name":"Homem","legendgroup":"Homem","showlegend":true,"xaxis":"x","yaxis":"y","hoverinfo":"text","frame":null},{"orientation":"v","width":[71.206551514720076,52.978590707630957,62.286031232853688,88.907698200669813,82.64895507750866,11.191449011782574,35.309119778368149,13.076800144339911,30.001373141436915,0.17732105633496931,3.681429965635667,2.0799948338936112,22.826010221079773,75.093994945026608],"base":[13.625,12.625,11.625,10.625,9.625,8.625,7.625,6.625,5.625,4.625,3.625,2.625,1.625,0.625],"x":[35.603275757360038,26.489295353815479,31.143015616426844,44.453849100334907,41.32447753875433,5.5957245058912868,17.654559889184075,6.5384000721699556,15.000686570718457,0.088660528167484653,1.8407149828178335,1.0399974169468056,11.413005110539887,37.546997472513304],"y":[0.35000000000000142,0.35000000000000142,0.35000000000000142,0.35000000000000142,0.35000000000000142,0.35000000000000142,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.35000000000000009,0.35000000000000009],"text":["Rio de Janeiro<br>Homem: 71,2 %","Rio de Janeiro<br>Homem: 53,0 %","Rio de Janeiro<br>Homem: 62,3 %","Rio de Janeiro<br>Homem: 88,9 %","Rio de Janeiro<br>Homem: 82,6 %","Rio de Janeiro<br>Homem: 11,2 %","Rio de Janeiro<br>Homem: 35,3 %","Rio de Janeiro<br>Homem: 13,1 %","Rio de Janeiro<br>Homem: 30,0 %","Rio de Janeiro<br>Homem: 0,2 %","Rio de Janeiro<br>Homem: 3,7 %","Rio de Janeiro<br>Homem: 2,1 %","Rio de Janeiro<br>Homem: 22,8 %","Rio de Janeiro<br>Homem: 75,1 %"],"type":"bar","textposition":"none","marker":{"autocolorscale":false,"color":"rgba(91,74,155,1)","line":{"width":1.8897637795275593,"color":"transparent"}},"name":"Homem","legendgroup":"Homem","showlegend":false,"xaxis":"x2","yaxis":"y","hoverinfo":"text","frame":null},{"orientation":"v","width":[53.373036144775675,50.086898163122193,46.358305010508651,56.633400762980216,66.188906853810877,11.771725743806797,39.681349392922755,28.065403989042849,21.196669980883989,2.6120233969045294,3.0042471474380368,4.1242517577968858,10.740382497690296,85.135365744512825],"base":[14.024999999999999,13.024999999999999,12.024999999999999,11.024999999999999,10.024999999999999,9.0249999999999986,8.0249999999999986,7.0250000000000004,6.0250000000000004,5.0250000000000004,4.0250000000000004,3.0250000000000004,2.0250000000000004,1.0249999999999999],"x":[26.686518072387837,25.043449081561096,23.179152505254326,28.316700381490108,33.094453426905439,5.8858628719033987,19.840674696461377,14.032701994521425,10.598334990441995,1.3060116984522647,1.5021235737190184,2.0621258788984429,5.3701912488451482,42.567682872256412],"y":[0.35000000000000142,0.35000000000000142,0.35000000000000142,0.35000000000000142,0.35000000000000142,0.35000000000000142,0.35000000000000142,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.35000000000000009],"text":["Brasil<br>Mulher: 53,4 %","Brasil<br>Mulher: 50,1 %","Brasil<br>Mulher: 46,4 %","Brasil<br>Mulher: 56,6 %","Brasil<br>Mulher: 66,2 %","Brasil<br>Mulher: 11,8 %","Brasil<br>Mulher: 39,7 %","Brasil<br>Mulher: 28,1 %","Brasil<br>Mulher: 21,2 %","Brasil<br>Mulher: 2,6 %","Brasil<br>Mulher: 3,0 %","Brasil<br>Mulher: 4,1 %","Brasil<br>Mulher: 10,7 %","Brasil<br>Mulher: 85,1 %"],"type":"bar","textposition":"none","marker":{"autocolorscale":false,"color":"rgba(232,121,58,1)","line":{"width":1.8897637795275593,"color":"transparent"}},"name":"Mulher","legendgroup":"Mulher","showlegend":true,"xaxis":"x","yaxis":"y","hoverinfo":"text","frame":null},{"orientation":"v","width":[52.069751952928826,47.123552378678355,43.28042189165938,57.779507379394914,64.923534827531142,15.729425520361339,38.798436479236898,27.186805393715758,24.403282529731886,0.53516238330194521,2.2899234493615581,0.30886959010823067,6.9662802632145455,92.724850146677227],"base":[14.024999999999999,13.024999999999999,12.024999999999999,11.024999999999999,10.024999999999999,9.0249999999999986,8.0249999999999986,7.0250000000000004,6.0250000000000004,5.0250000000000004,4.0250000000000004,3.0250000000000004,2.0250000000000004,1.0249999999999999],"x":[26.034875976464413,23.561776189339177,21.64021094582969,28.889753689697457,32.461767413765571,7.8647127601806694,19.399218239618449,13.593402696857879,12.201641264865943,0.26758119165097261,1.1449617246807791,0.15443479505411534,3.4831401316072728,46.362425073338613],"y":[0.35000000000000142,0.35000000000000142,0.35000000000000142,0.35000000000000142,0.35000000000000142,0.35000000000000142,0.35000000000000142,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.35000000000000009],"text":["Rio de Janeiro<br>Mulher: 52,1 %","Rio de Janeiro<br>Mulher: 47,1 %","Rio de Janeiro<br>Mulher: 43,3 %","Rio de Janeiro<br>Mulher: 57,8 %","Rio de Janeiro<br>Mulher: 64,9 %","Rio de Janeiro<br>Mulher: 15,7 %","Rio de Janeiro<br>Mulher: 38,8 %","Rio de Janeiro<br>Mulher: 27,2 %","Rio de Janeiro<br>Mulher: 24,4 %","Rio de Janeiro<br>Mulher: 0,5 %","Rio de Janeiro<br>Mulher: 2,3 %","Rio de Janeiro<br>Mulher: 0,3 %","Rio de Janeiro<br>Mulher: 7,0 %","Rio de Janeiro<br>Mulher: 92,7 %"],"type":"bar","textposition":"none","marker":{"autocolorscale":false,"color":"rgba(232,121,58,1)","line":{"width":1.8897637795275593,"color":"transparent"}},"name":"Mulher","legendgroup":"Mulher","showlegend":false,"xaxis":"x2","yaxis":"y","hoverinfo":"text","frame":null}],"layout":{"margin":{"t":33.072819033886091,"r":7.3059360730593621,"b":35.337659216534497,"l":233.05936073059365},"font":{"color":"rgba(0,0,0,1)","family":"","size":14.611872146118724},"xaxis":{"domain":[0,0.49592302674494454],"automargin":true,"type":"linear","autorange":false,"range":[-4.6362425073338613,97.361092654011088],"tickmode":"array","ticktext":["0","25","50","75"],"tickvals":[0,24.999999999999996,50,75],"categoryorder":"array","categoryarray":["0","25","50","75"],"nticks":null,"ticks":"","tickcolor":null,"ticklen":3.6529680365296811,"tickwidth":0,"showticklabels":true,"tickfont":{"color":"rgba(77,77,77,1)","family":"","size":11.689497716894984},"tickangle":-0,"showline":false,"linecolor":null,"linewidth":0,"showgrid":true,"gridcolor":"rgba(235,235,235,1)","gridwidth":0.66417600664176002,"zeroline":false,"anchor":"y","title":"","hoverformat":".2f"},"annotations":[{"text":"%","x":0.5,"y":0,"showarrow":false,"ax":0,"ay":0,"font":{"color":"rgba(0,0,0,1)","family":"","size":14.611872146118724},"xref":"paper","yref":"paper","textangle":-0,"xanchor":"center","yanchor":"top","annotationType":"axis","yshift":-21.917808219178081},{"text":"Brasil","x":0.24796151337247227,"y":1,"showarrow":false,"ax":0,"ay":0,"font":{"color":"rgba(26,26,26,1)","family":"","size":11.689497716894984},"xref":"paper","yref":"paper","textangle":-0,"xanchor":"center","yanchor":"bottom"},{"text":"Rio de Janeiro","x":0.7520384866275277,"y":1,"showarrow":false,"ax":0,"ay":0,"font":{"color":"rgba(26,26,26,1)","family":"","size":11.689497716894984},"xref":"paper","yref":"paper","textangle":-0,"xanchor":"center","yanchor":"bottom"}],"yaxis":{"domain":[0,1],"automargin":true,"type":"linear","autorange":false,"range":[0.40000000000000002,14.6],"tickmode":"array","ticktext":["Ocupados nos serviços (1.8)","Ocupados na indústria (1.8)","Ocupados na agropecuária (1.8)","Empregador entre os ocupados (1.6)","Trabalhador familiar auxiliar entre os<br />ocupados (1.5)","Conta própria entre os ocupados (1.4)","Ocupação em tempo parcial (1.14)","Informalidade no trabalho não agrícola<br />(1.9)","Taxa de desocupação (1.10)","Nível de ocupação, 25 a 54 anos, sem<br />criança de até 6 anos (1.15)","Nível de ocupação, 25 a 54 anos, com<br />criança de até 6 anos (1.15)","Nível de ocupação, 14 anos ou mais","Taxa de participação, 15 a 24 anos<br />(1.3)","Taxa de participação, 15 anos ou mais<br />(1.3)"],"tickvals":[1,2,3,3.9999999999999996,5,6,7,7.9999999999999991,9,10,11,12,13,14],"categoryorder":"array","categoryarray":["Ocupados nos serviços (1.8)","Ocupados na indústria (1.8)","Ocupados na agropecuária (1.8)","Empregador entre os ocupados (1.6)","Trabalhador familiar auxiliar entre os<br />ocupados (1.5)","Conta própria entre os ocupados (1.4)","Ocupação em tempo parcial (1.14)","Informalidade no trabalho não agrícola<br />(1.9)","Taxa de desocupação (1.10)","Nível de ocupação, 25 a 54 anos, sem<br />criança de até 6 anos (1.15)","Nível de ocupação, 25 a 54 anos, com<br />criança de até 6 anos (1.15)","Nível de ocupação, 14 anos ou mais","Taxa de participação, 15 a 24 anos<br />(1.3)","Taxa de participação, 15 anos ou mais<br />(1.3)"],"nticks":null,"ticks":"","tickcolor":null,"ticklen":3.6529680365296811,"tickwidth":0,"showticklabels":true,"tickfont":{"color":"rgba(77,77,77,1)","family":"","size":11.68949771689498},"tickangle":-0,"showline":false,"linecolor":null,"linewidth":0,"showgrid":false,"gridcolor":null,"gridwidth":0,"zeroline":false,"anchor":"x","title":"","hoverformat":".2f"},"shapes":[{"type":"rect","fillcolor":null,"line":{"color":null,"width":0,"linetype":[]},"yref":"paper","xref":"paper","layer":"below","x0":0,"x1":0.49592302674494454,"y0":0,"y1":1},{"type":"rect","fillcolor":null,"line":{"color":null,"width":0,"linetype":[]},"yref":"paper","xref":"paper","layer":"below","x0":0,"x1":0.49592302674494454,"y0":0,"y1":23.37899543378996,"yanchor":1,"ysizemode":"pixel"},{"type":"rect","fillcolor":null,"line":{"color":null,"width":0,"linetype":[]},"yref":"paper","xref":"paper","layer":"below","x0":0.5040769732550554,"x1":1,"y0":0,"y1":1},{"type":"rect","fillcolor":null,"line":{"color":null,"width":0,"linetype":[]},"yref":"paper","xref":"paper","layer":"below","x0":0.5040769732550554,"x1":1,"y0":0,"y1":23.37899543378996,"yanchor":1,"ysizemode":"pixel"}],"xaxis2":{"type":"linear","autorange":false,"range":[-4.6362425073338613,97.361092654011088],"tickmode":"array","ticktext":["0","25","50","75"],"tickvals":[0,24.999999999999996,50,75],"categoryorder":"array","categoryarray":["0","25","50","75"],"nticks":null,"ticks":"","tickcolor":null,"ticklen":3.6529680365296811,"tickwidth":0,"showticklabels":true,"tickfont":{"color":"rgba(77,77,77,1)","family":"","size":11.689497716894984},"tickangle":-0,"showline":false,"linecolor":null,"linewidth":0,"showgrid":true,"domain":[0.5040769732550554,1],"gridcolor":"rgba(235,235,235,1)","gridwidth":0.66417600664176002,"zeroline":false,"anchor":"y","title":"","hoverformat":".2f"},"showlegend":true,"legend":{"bgcolor":null,"bordercolor":null,"borderwidth":0,"font":{"color":"rgba(0,0,0,1)","family":"","size":11.689497716894984},"title":{"text":"","font":{"color":"rgba(0,0,0,1)","family":"","size":14.611872146118724}},"orientation":"h","x":0,"xanchor":"right","y":1,"yanchor":"bottom"},"hovermode":"closest","barmode":"relative"},"config":{"doubleClick":"reset","modeBarButtonsToAdd":["hoverclosest","hovercompare"],"showSendToCloud":false,"displayModeBar":false},"source":"A","attrs":{"243047e87bba":{"x":{},"y":{},"fill":{},"text":{},"type":"bar"}},"cur_data":"243047e87bba","visdat":{"243047e87bba":["function (y) ","x"]},"highlight":{"on":"plotly_click","persistent":false,"dynamic":false,"selectize":false,"opacityDim":0.20000000000000001,"selected":{"opacity":1},"debounce":0},"shinyEvents":["plotly_hover","plotly_click","plotly_selected","plotly_relayout","plotly_brushed","plotly_brushing","plotly_clickannotation","plotly_doubleclick","plotly_deselect","plotly_afterplot","plotly_sunburstclick"],"base_url":"https://plot.ly"},"evals":[],"jsHooks":[]}</script>
```


Indicadores de trabalho, por sexo. Fonte: IBGE, PNAD Contínua, 5ª visita, 2022.
:::
:::



::: {.cell}

```{.r .cell-code}
indicadores_sexo_longo |>
  filter(dimensao == 'Educação') |>
  grafico_indicadores(rotulo_eixo = '%')
```

::: {#fig-educacao .cell-output-display}

```{=html}
<div class="plotly html-widget html-fill-item" id="htmlwidget-0e0d1f8a1f512d7dfe11" style="width:100%;height:650px;"></div>
<script type="application/json" data-for="htmlwidget-0e0d1f8a1f512d7dfe11">{"x":{"data":[{"orientation":"v","width":[35.281401695684664,13.628152070491145,34.254311720965241,16.836134512858933,92.14963180929719,29.666874575504632,87.236396160826331,68.577601710931063,16.585514170050459],"base":[8.625,7.625,6.625,5.625,4.625,3.625,2.625,1.625,0.625],"x":[17.640700847842332,6.8140760352455727,17.12715586048262,8.4180672564294667,46.074815904648595,14.833437287752316,43.618198080413165,34.288800855465531,8.2927570850252295],"y":[0.35000000000000142,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.35000000000000009,0.35000000000000009],"text":["Brasil<br>Homem: 35,3 %","Brasil<br>Homem: 13,6 %","Brasil<br>Homem: 34,3 %","Brasil<br>Homem: 16,8 %","Brasil<br>Homem: 92,1 %","Brasil<br>Homem: 29,7 %","Brasil<br>Homem: 87,2 %","Brasil<br>Homem: 68,6 %","Brasil<br>Homem: 16,6 %"],"type":"bar","textposition":"none","marker":{"autocolorscale":false,"color":"rgba(91,74,155,1)","line":{"width":1.8897637795275593,"color":"transparent"}},"name":"Homem","legendgroup":"Homem","showlegend":true,"xaxis":"x","yaxis":"y","hoverinfo":"text","frame":null},{"orientation":"v","width":[23.466495654185731,13.779512828025583,41.09994611397326,21.654045403815427,94.661388590937349,35.764549828986105,90.061912887793753,69.149385231313218,20.899679391705661],"base":[8.625,7.625,6.625,5.625,4.625,3.625,2.625,1.625,0.625],"x":[11.733247827092866,6.8897564140127914,20.54997305698663,10.827022701907714,47.330694295468675,17.882274914493053,45.030956443896876,34.574692615656609,10.44983969585283],"y":[0.35000000000000142,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.35000000000000009,0.35000000000000009],"text":["Rio de Janeiro<br>Homem: 23,5 %","Rio de Janeiro<br>Homem: 13,8 %","Rio de Janeiro<br>Homem: 41,1 %","Rio de Janeiro<br>Homem: 21,7 %","Rio de Janeiro<br>Homem: 94,7 %","Rio de Janeiro<br>Homem: 35,8 %","Rio de Janeiro<br>Homem: 90,1 %","Rio de Janeiro<br>Homem: 69,1 %","Rio de Janeiro<br>Homem: 20,9 %"],"type":"bar","textposition":"none","marker":{"autocolorscale":false,"color":"rgba(91,74,155,1)","line":{"width":1.8897637795275593,"color":"transparent"}},"name":"Homem","legendgroup":"Homem","showlegend":false,"xaxis":"x2","yaxis":"y","hoverinfo":"text","frame":null},{"orientation":"v","width":[32.301033449787056,12.139820483925913,34.141718726062969,21.417427340224073,92.435527017143755,33.66056389190183,92.475868347436673,77.581154664078937,25.890016166718766],"base":[9.0249999999999986,8.0249999999999986,7.0250000000000004,6.0250000000000004,5.0250000000000004,4.0250000000000004,3.0250000000000004,2.0250000000000004,1.0249999999999999],"x":[16.150516724893528,6.0699102419629565,17.070859363031484,10.708713670112036,46.217763508571878,16.830281945950915,46.237934173718337,38.790577332039469,12.945008083359383],"y":[0.35000000000000142,0.35000000000000142,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.35000000000000009],"text":["Brasil<br>Mulher: 32,3 %","Brasil<br>Mulher: 12,1 %","Brasil<br>Mulher: 34,1 %","Brasil<br>Mulher: 21,4 %","Brasil<br>Mulher: 92,4 %","Brasil<br>Mulher: 33,7 %","Brasil<br>Mulher: 92,5 %","Brasil<br>Mulher: 77,6 %","Brasil<br>Mulher: 25,9 %"],"type":"bar","textposition":"none","marker":{"autocolorscale":false,"color":"rgba(232,121,58,1)","line":{"width":1.8897637795275593,"color":"transparent"}},"name":"Mulher","legendgroup":"Mulher","showlegend":true,"xaxis":"x","yaxis":"y","hoverinfo":"text","frame":null},{"orientation":"v","width":[24.306554034500778,12.655208228081385,37.698771441190736,25.339466296227098,96.620430139174545,38.732694564863777,93.488968634788193,80.259057532537454,28.652205386606806],"base":[9.0249999999999986,8.0249999999999986,7.0250000000000004,6.0250000000000004,5.0250000000000004,4.0250000000000004,3.0250000000000004,2.0250000000000004,1.0249999999999999],"x":[12.153277017250389,6.3276041140406925,18.849385720595368,12.669733148113549,48.310215069587272,19.366347282431889,46.744484317394097,40.129528766268727,14.326102693303403],"y":[0.35000000000000142,0.35000000000000142,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.34999999999999964,0.35000000000000009],"text":["Rio de Janeiro<br>Mulher: 24,3 %","Rio de Janeiro<br>Mulher: 12,7 %","Rio de Janeiro<br>Mulher: 37,7 %","Rio de Janeiro<br>Mulher: 25,3 %","Rio de Janeiro<br>Mulher: 96,6 %","Rio de Janeiro<br>Mulher: 38,7 %","Rio de Janeiro<br>Mulher: 93,5 %","Rio de Janeiro<br>Mulher: 80,3 %","Rio de Janeiro<br>Mulher: 28,7 %"],"type":"bar","textposition":"none","marker":{"autocolorscale":false,"color":"rgba(232,121,58,1)","line":{"width":1.8897637795275593,"color":"transparent"}},"name":"Mulher","legendgroup":"Mulher","showlegend":false,"xaxis":"x2","yaxis":"y","hoverinfo":"text","frame":null}],"layout":{"margin":{"t":34.995433789954348,"r":7.3059360730593621,"b":37.260273972602747,"l":233.05936073059365},"font":{"color":"rgba(0,0,0,1)","family":"","size":14.611872146118724},"xaxis":{"domain":[0,0.49592302674494454],"automargin":true,"type":"linear","autorange":false,"range":[-4.8310215069587272,101.45145164613328],"tickmode":"array","ticktext":["0","25","50","75","100"],"tickvals":[0,25,50,75,100],"categoryorder":"array","categoryarray":["0","25","50","75","100"],"nticks":null,"ticks":"","tickcolor":null,"ticklen":3.6529680365296811,"tickwidth":0,"showticklabels":true,"tickfont":{"color":"rgba(77,77,77,1)","family":"","size":11.68949771689498},"tickangle":-0,"showline":false,"linecolor":null,"linewidth":0,"showgrid":true,"gridcolor":"rgba(235,235,235,1)","gridwidth":0.66417600664176002,"zeroline":false,"anchor":"y","title":"","hoverformat":".2f"},"annotations":[{"text":"%","x":0.5,"y":0,"showarrow":false,"ax":0,"ay":0,"font":{"color":"rgba(0,0,0,1)","family":"","size":14.611872146118724},"xref":"paper","yref":"paper","textangle":-0,"xanchor":"center","yanchor":"top","annotationType":"axis","yshift":-21.917808219178081},{"text":"Brasil","x":0.24796151337247227,"y":1,"showarrow":false,"ax":0,"ay":0,"font":{"color":"rgba(26,26,26,1)","family":"","size":11.68949771689498},"xref":"paper","yref":"paper","textangle":-0,"xanchor":"center","yanchor":"bottom"},{"text":"Rio de Janeiro","x":0.7520384866275277,"y":1,"showarrow":false,"ax":0,"ay":0,"font":{"color":"rgba(26,26,26,1)","family":"","size":11.68949771689498},"xref":"paper","yref":"paper","textangle":-0,"xanchor":"center","yanchor":"bottom"}],"yaxis":{"domain":[0,1],"automargin":true,"type":"linear","autorange":false,"range":[0.40000000000000002,9.5999999999999996],"tickmode":"array","ticktext":["Jovens de 15 a 24 anos que não estudam<br />nem estão ocupados (1.7)","Conclusão do ensino médio, 20 a 22<br />anos","Conclusão do ensino fundamental, 17 a<br />19 anos (2.6)","Frequência escolar, 18 a 24 anos (2.4)","Frequência escolar, 15 a 17 anos (2.3)","25 anos ou mais: superior completo<br />(2.11)","25 anos ou mais: médio completo e<br />superior incompleto (2.11)","25 anos ou mais: fundamental completo<br />e médio incompleto (2.11)","25 anos ou mais: sem instrução e<br />fundamental incompleto (2.11)"],"tickvals":[1,2,3,4,5,6,6.9999999999999991,8,9],"categoryorder":"array","categoryarray":["Jovens de 15 a 24 anos que não estudam<br />nem estão ocupados (1.7)","Conclusão do ensino médio, 20 a 22<br />anos","Conclusão do ensino fundamental, 17 a<br />19 anos (2.6)","Frequência escolar, 18 a 24 anos (2.4)","Frequência escolar, 15 a 17 anos (2.3)","25 anos ou mais: superior completo<br />(2.11)","25 anos ou mais: médio completo e<br />superior incompleto (2.11)","25 anos ou mais: fundamental completo<br />e médio incompleto (2.11)","25 anos ou mais: sem instrução e<br />fundamental incompleto (2.11)"],"nticks":null,"ticks":"","tickcolor":null,"ticklen":3.6529680365296811,"tickwidth":0,"showticklabels":true,"tickfont":{"color":"rgba(77,77,77,1)","family":"","size":11.68949771689498},"tickangle":-0,"showline":false,"linecolor":null,"linewidth":0,"showgrid":false,"gridcolor":null,"gridwidth":0,"zeroline":false,"anchor":"x","title":"","hoverformat":".2f"},"shapes":[{"type":"rect","fillcolor":null,"line":{"color":null,"width":0,"linetype":[]},"yref":"paper","xref":"paper","layer":"below","x0":0,"x1":0.49592302674494454,"y0":0,"y1":1},{"type":"rect","fillcolor":null,"line":{"color":null,"width":0,"linetype":[]},"yref":"paper","xref":"paper","layer":"below","x0":0,"x1":0.49592302674494454,"y0":0,"y1":23.37899543378996,"yanchor":1,"ysizemode":"pixel"},{"type":"rect","fillcolor":null,"line":{"color":null,"width":0,"linetype":[]},"yref":"paper","xref":"paper","layer":"below","x0":0.5040769732550554,"x1":1,"y0":0,"y1":1},{"type":"rect","fillcolor":null,"line":{"color":null,"width":0,"linetype":[]},"yref":"paper","xref":"paper","layer":"below","x0":0.5040769732550554,"x1":1,"y0":0,"y1":23.37899543378996,"yanchor":1,"ysizemode":"pixel"}],"xaxis2":{"type":"linear","autorange":false,"range":[-4.8310215069587272,101.45145164613328],"tickmode":"array","ticktext":["0","25","50","75","100"],"tickvals":[0,25,50,75,100],"categoryorder":"array","categoryarray":["0","25","50","75","100"],"nticks":null,"ticks":"","tickcolor":null,"ticklen":3.6529680365296811,"tickwidth":0,"showticklabels":true,"tickfont":{"color":"rgba(77,77,77,1)","family":"","size":11.68949771689498},"tickangle":-0,"showline":false,"linecolor":null,"linewidth":0,"showgrid":true,"domain":[0.5040769732550554,1],"gridcolor":"rgba(235,235,235,1)","gridwidth":0.66417600664176002,"zeroline":false,"anchor":"y","title":"","hoverformat":".2f"},"showlegend":true,"legend":{"bgcolor":null,"bordercolor":null,"borderwidth":0,"font":{"color":"rgba(0,0,0,1)","family":"","size":11.68949771689498},"title":{"text":"","font":{"color":"rgba(0,0,0,1)","family":"","size":14.611872146118724}},"orientation":"h","x":0,"xanchor":"right","y":1,"yanchor":"bottom"},"hovermode":"closest","barmode":"relative"},"config":{"doubleClick":"reset","modeBarButtonsToAdd":["hoverclosest","hovercompare"],"showSendToCloud":false,"displayModeBar":false},"source":"A","attrs":{"243030f46031":{"x":{},"y":{},"fill":{},"text":{},"type":"bar"}},"cur_data":"243030f46031","visdat":{"243030f46031":["function (y) ","x"]},"highlight":{"on":"plotly_click","persistent":false,"dynamic":false,"selectize":false,"opacityDim":0.20000000000000001,"selected":{"opacity":1},"debounce":0},"shinyEvents":["plotly_hover","plotly_click","plotly_selected","plotly_relayout","plotly_brushed","plotly_brushing","plotly_clickannotation","plotly_doubleclick","plotly_deselect","plotly_afterplot","plotly_sunburstclick"],"base_url":"https://plot.ly"},"evals":[],"jsHooks":[]}</script>
```


Indicadores de educação, por sexo. Fonte: IBGE, PNAD Contínua, 5ª visita, 2022.
:::
:::



::: {.cell}

```{.r .cell-code}
indicadores_sexo_longo |>
  filter(dimensao == 'Cuidados e afazeres', unidade == '%') |>
  grafico_indicadores(rotulo_eixo = '%')
```

::: {#fig-afazeres .cell-output-display}

```{=html}
<div class="plotly html-widget html-fill-item" id="htmlwidget-831839019765629064ab" style="width:100%;height:325px;"></div>
<script type="application/json" data-for="htmlwidget-831839019765629064ab">{"x":{"data":[{"orientation":"v","width":[79.08330338832576,23.14146911396373],"base":[1.625,0.625],"x":[39.54165169416288,11.570734556981865],"y":[0.35000000000000009,0.35000000000000009],"text":["Brasil<br>Homem: 79,1 %","Brasil<br>Homem: 23,1 %"],"type":"bar","textposition":"none","marker":{"autocolorscale":false,"color":"rgba(91,74,155,1)","line":{"width":1.8897637795275593,"color":"transparent"}},"name":"Homem","legendgroup":"Homem","showlegend":true,"xaxis":"x","yaxis":"y","hoverinfo":"text","frame":null},{"orientation":"v","width":[84.140678915807371,22.450976418854719],"base":[1.625,0.625],"x":[42.070339457903685,11.225488209427359],"y":[0.35000000000000009,0.35000000000000009],"text":["Rio de Janeiro<br>Homem: 84,1 %","Rio de Janeiro<br>Homem: 22,5 %"],"type":"bar","textposition":"none","marker":{"autocolorscale":false,"color":"rgba(91,74,155,1)","line":{"width":1.8897637795275593,"color":"transparent"}},"name":"Homem","legendgroup":"Homem","showlegend":false,"xaxis":"x2","yaxis":"y","hoverinfo":"text","frame":null},{"orientation":"v","width":[91.3672881671406,34.698984593647225],"base":[2.0250000000000004,1.0249999999999999],"x":[45.6836440835703,17.349492296823612],"y":[0.34999999999999964,0.35000000000000009],"text":["Brasil<br>Mulher: 91,4 %","Brasil<br>Mulher: 34,7 %"],"type":"bar","textposition":"none","marker":{"autocolorscale":false,"color":"rgba(232,121,58,1)","line":{"width":1.8897637795275593,"color":"transparent"}},"name":"Mulher","legendgroup":"Mulher","showlegend":true,"xaxis":"x","yaxis":"y","hoverinfo":"text","frame":null},{"orientation":"v","width":[90.961321084473056,29.864897823046419],"base":[2.0250000000000004,1.0249999999999999],"x":[45.480660542236528,14.93244891152321],"y":[0.34999999999999964,0.35000000000000009],"text":["Rio de Janeiro<br>Mulher: 91,0 %","Rio de Janeiro<br>Mulher: 29,9 %"],"type":"bar","textposition":"none","marker":{"autocolorscale":false,"color":"rgba(232,121,58,1)","line":{"width":1.8897637795275593,"color":"transparent"}},"name":"Mulher","legendgroup":"Mulher","showlegend":false,"xaxis":"x2","yaxis":"y","hoverinfo":"text","frame":null}],"layout":{"margin":{"t":42.301369863013704,"r":7.3059360730593621,"b":44.56621004566211,"l":203.83561643835623},"font":{"color":"rgba(0,0,0,1)","family":"","size":14.611872146118724},"xaxis":{"domain":[0,0.49592302674494454],"automargin":true,"type":"linear","autorange":false,"range":[-4.5683644083570298,95.935652575497627],"tickmode":"array","ticktext":["0","25","50","75"],"tickvals":[0,25.000000000000004,50,75],"categoryorder":"array","categoryarray":["0","25","50","75"],"nticks":null,"ticks":"","tickcolor":null,"ticklen":3.6529680365296811,"tickwidth":0,"showticklabels":true,"tickfont":{"color":"rgba(77,77,77,1)","family":"","size":11.68949771689498},"tickangle":-0,"showline":false,"linecolor":null,"linewidth":0,"showgrid":true,"gridcolor":"rgba(235,235,235,1)","gridwidth":0.66417600664176002,"zeroline":false,"anchor":"y","title":"","hoverformat":".2f"},"annotations":[{"text":"%","x":0.5,"y":0,"showarrow":false,"ax":0,"ay":0,"font":{"color":"rgba(0,0,0,1)","family":"","size":14.611872146118724},"xref":"paper","yref":"paper","textangle":-0,"xanchor":"center","yanchor":"top","annotationType":"axis","yshift":-21.917808219178081},{"text":"Brasil","x":0.24796151337247227,"y":1,"showarrow":false,"ax":0,"ay":0,"font":{"color":"rgba(26,26,26,1)","family":"","size":11.68949771689498},"xref":"paper","yref":"paper","textangle":-0,"xanchor":"center","yanchor":"bottom"},{"text":"Rio de Janeiro","x":0.7520384866275277,"y":1,"showarrow":false,"ax":0,"ay":0,"font":{"color":"rgba(26,26,26,1)","family":"","size":11.68949771689498},"xref":"paper","yref":"paper","textangle":-0,"xanchor":"center","yanchor":"bottom"}],"yaxis":{"domain":[0,1],"automargin":true,"type":"linear","autorange":false,"range":[0.40000000000000002,2.6000000000000001],"tickmode":"array","ticktext":["Taxa de realização de cuidados de<br />pessoas","Taxa de realização de afazeres<br />domésticos"],"tickvals":[1,2],"categoryorder":"array","categoryarray":["Taxa de realização de cuidados de<br />pessoas","Taxa de realização de afazeres<br />domésticos"],"nticks":null,"ticks":"","tickcolor":null,"ticklen":3.6529680365296811,"tickwidth":0,"showticklabels":true,"tickfont":{"color":"rgba(77,77,77,1)","family":"","size":11.68949771689498},"tickangle":-0,"showline":false,"linecolor":null,"linewidth":0,"showgrid":false,"gridcolor":null,"gridwidth":0,"zeroline":false,"anchor":"x","title":"","hoverformat":".2f"},"shapes":[{"type":"rect","fillcolor":null,"line":{"color":null,"width":0,"linetype":[]},"yref":"paper","xref":"paper","layer":"below","x0":0,"x1":0.49592302674494454,"y0":0,"y1":1},{"type":"rect","fillcolor":null,"line":{"color":null,"width":0,"linetype":[]},"yref":"paper","xref":"paper","layer":"below","x0":0,"x1":0.49592302674494454,"y0":0,"y1":23.37899543378996,"yanchor":1,"ysizemode":"pixel"},{"type":"rect","fillcolor":null,"line":{"color":null,"width":0,"linetype":[]},"yref":"paper","xref":"paper","layer":"below","x0":0.5040769732550554,"x1":1,"y0":0,"y1":1},{"type":"rect","fillcolor":null,"line":{"color":null,"width":0,"linetype":[]},"yref":"paper","xref":"paper","layer":"below","x0":0.5040769732550554,"x1":1,"y0":0,"y1":23.37899543378996,"yanchor":1,"ysizemode":"pixel"}],"xaxis2":{"type":"linear","autorange":false,"range":[-4.5683644083570298,95.935652575497627],"tickmode":"array","ticktext":["0","25","50","75"],"tickvals":[0,25.000000000000004,50,75],"categoryorder":"array","categoryarray":["0","25","50","75"],"nticks":null,"ticks":"","tickcolor":null,"ticklen":3.6529680365296811,"tickwidth":0,"showticklabels":true,"tickfont":{"color":"rgba(77,77,77,1)","family":"","size":11.68949771689498},"tickangle":-0,"showline":false,"linecolor":null,"linewidth":0,"showgrid":true,"domain":[0.5040769732550554,1],"gridcolor":"rgba(235,235,235,1)","gridwidth":0.66417600664176002,"zeroline":false,"anchor":"y","title":"","hoverformat":".2f"},"showlegend":true,"legend":{"bgcolor":null,"bordercolor":null,"borderwidth":0,"font":{"color":"rgba(0,0,0,1)","family":"","size":11.68949771689498},"title":{"text":"","font":{"color":"rgba(0,0,0,1)","family":"","size":14.611872146118724}},"orientation":"h","x":0,"xanchor":"right","y":1,"yanchor":"bottom"},"hovermode":"closest","barmode":"relative"},"config":{"doubleClick":"reset","modeBarButtonsToAdd":["hoverclosest","hovercompare"],"showSendToCloud":false,"displayModeBar":false},"source":"A","attrs":{"243037f8395":{"x":{},"y":{},"fill":{},"text":{},"type":"bar"}},"cur_data":"243037f8395","visdat":{"243037f8395":["function (y) ","x"]},"highlight":{"on":"plotly_click","persistent":false,"dynamic":false,"selectize":false,"opacityDim":0.20000000000000001,"selected":{"opacity":1},"debounce":0},"shinyEvents":["plotly_hover","plotly_click","plotly_selected","plotly_relayout","plotly_brushed","plotly_brushing","plotly_clickannotation","plotly_doubleclick","plotly_deselect","plotly_afterplot","plotly_sunburstclick"],"base_url":"https://plot.ly"},"evals":[],"jsHooks":[]}</script>
```


Taxas de realização de cuidados e de afazeres domésticos, por sexo. Fonte: IBGE, PNAD Contínua, 5ª visita, 2022.
:::
:::



::: {.cell}

```{.r .cell-code}
indicadores_sexo_longo |>
  filter(unidade == 'horas') |>
  grafico_indicadores(rotulo_eixo = 'Horas por semana')
```

::: {#fig-horas .cell-output-display}

```{=html}
<div class="plotly html-widget html-fill-item" id="htmlwidget-d96490452ec53a90b5a4" style="width:100%;height:325px;"></div>
<script type="application/json" data-for="htmlwidget-d96490452ec53a90b5a4">{"x":{"data":[{"orientation":"v","width":[52.615087299576764,11.707596154477692],"base":[1.625,0.625],"x":[26.307543649788382,5.8537980772388458],"y":[0.35000000000000009,0.35000000000000009],"text":["Brasil<br>Homem: 52,6 horas","Brasil<br>Homem: 11,7 horas"],"type":"bar","textposition":"none","marker":{"autocolorscale":false,"color":"rgba(91,74,155,1)","line":{"width":1.8897637795275593,"color":"transparent"}},"name":"Homem","legendgroup":"Homem","showlegend":true,"xaxis":"x","yaxis":"y","hoverinfo":"text","frame":null},{"orientation":"v","width":[53.45234968633541,12.469567721615723],"base":[1.625,0.625],"x":[26.726174843167705,6.2347838608078616],"y":[0.35000000000000009,0.35000000000000009],"text":["Rio de Janeiro<br>Homem: 53,5 horas","Rio de Janeiro<br>Homem: 12,5 horas"],"type":"bar","textposition":"none","marker":{"autocolorscale":false,"color":"rgba(91,74,155,1)","line":{"width":1.8897637795275593,"color":"transparent"}},"name":"Homem","legendgroup":"Homem","showlegend":false,"xaxis":"x2","yaxis":"y","hoverinfo":"text","frame":null},{"orientation":"v","width":[54.997720560131953,21.255009097076762],"base":[2.0250000000000004,1.0249999999999999],"x":[27.498860280065976,10.627504548538381],"y":[0.34999999999999964,0.35000000000000009],"text":["Brasil<br>Mulher: 55,0 horas","Brasil<br>Mulher: 21,3 horas"],"type":"bar","textposition":"none","marker":{"autocolorscale":false,"color":"rgba(232,121,58,1)","line":{"width":1.8897637795275593,"color":"transparent"}},"name":"Mulher","legendgroup":"Mulher","showlegend":true,"xaxis":"x","yaxis":"y","hoverinfo":"text","frame":null},{"orientation":"v","width":[54.867112317003347,20.100618061566788],"base":[2.0250000000000004,1.0249999999999999],"x":[27.433556158501673,10.050309030783394],"y":[0.34999999999999964,0.35000000000000009],"text":["Rio de Janeiro<br>Mulher: 54,9 horas","Rio de Janeiro<br>Mulher: 20,1 horas"],"type":"bar","textposition":"none","marker":{"autocolorscale":false,"color":"rgba(232,121,58,1)","line":{"width":1.8897637795275593,"color":"transparent"}},"name":"Mulher","legendgroup":"Mulher","showlegend":false,"xaxis":"x2","yaxis":"y","hoverinfo":"text","frame":null}],"layout":{"margin":{"t":42.301369863013704,"r":7.3059360730593621,"b":44.56621004566211,"l":227.21461187214618},"font":{"color":"rgba(0,0,0,1)","family":"","size":14.611872146118724},"xaxis":{"domain":[0,0.49592302674494454],"automargin":true,"type":"linear","autorange":false,"range":[-2.749886028006598,57.747606588138552],"tickmode":"array","ticktext":["0","20","40"],"tickvals":[0,20,40],"categoryorder":"array","categoryarray":["0","20","40"],"nticks":null,"ticks":"","tickcolor":null,"ticklen":3.6529680365296811,"tickwidth":0,"showticklabels":true,"tickfont":{"color":"rgba(77,77,77,1)","family":"","size":11.68949771689498},"tickangle":-0,"showline":false,"linecolor":null,"linewidth":0,"showgrid":true,"gridcolor":"rgba(235,235,235,1)","gridwidth":0.66417600664176002,"zeroline":false,"anchor":"y","title":"","hoverformat":".2f"},"annotations":[{"text":"Horas por semana","x":0.5,"y":0,"showarrow":false,"ax":0,"ay":0,"font":{"color":"rgba(0,0,0,1)","family":"","size":14.611872146118724},"xref":"paper","yref":"paper","textangle":-0,"xanchor":"center","yanchor":"top","annotationType":"axis","yshift":-21.917808219178081},{"text":"Brasil","x":0.24796151337247227,"y":1,"showarrow":false,"ax":0,"ay":0,"font":{"color":"rgba(26,26,26,1)","family":"","size":11.68949771689498},"xref":"paper","yref":"paper","textangle":-0,"xanchor":"center","yanchor":"bottom"},{"text":"Rio de Janeiro","x":0.7520384866275277,"y":1,"showarrow":false,"ax":0,"ay":0,"font":{"color":"rgba(26,26,26,1)","family":"","size":11.68949771689498},"xref":"paper","yref":"paper","textangle":-0,"xanchor":"center","yanchor":"bottom"}],"yaxis":{"domain":[0,1],"automargin":true,"type":"linear","autorange":false,"range":[0.40000000000000002,2.6000000000000001],"tickmode":"array","ticktext":["Horas semanais em cuidados e afazeres<br />(1.1)","Carga total de trabalho (1.2)"],"tickvals":[1,2],"categoryorder":"array","categoryarray":["Horas semanais em cuidados e afazeres<br />(1.1)","Carga total de trabalho (1.2)"],"nticks":null,"ticks":"","tickcolor":null,"ticklen":3.6529680365296811,"tickwidth":0,"showticklabels":true,"tickfont":{"color":"rgba(77,77,77,1)","family":"","size":11.68949771689498},"tickangle":-0,"showline":false,"linecolor":null,"linewidth":0,"showgrid":false,"gridcolor":null,"gridwidth":0,"zeroline":false,"anchor":"x","title":"","hoverformat":".2f"},"shapes":[{"type":"rect","fillcolor":null,"line":{"color":null,"width":0,"linetype":[]},"yref":"paper","xref":"paper","layer":"below","x0":0,"x1":0.49592302674494454,"y0":0,"y1":1},{"type":"rect","fillcolor":null,"line":{"color":null,"width":0,"linetype":[]},"yref":"paper","xref":"paper","layer":"below","x0":0,"x1":0.49592302674494454,"y0":0,"y1":23.37899543378996,"yanchor":1,"ysizemode":"pixel"},{"type":"rect","fillcolor":null,"line":{"color":null,"width":0,"linetype":[]},"yref":"paper","xref":"paper","layer":"below","x0":0.5040769732550554,"x1":1,"y0":0,"y1":1},{"type":"rect","fillcolor":null,"line":{"color":null,"width":0,"linetype":[]},"yref":"paper","xref":"paper","layer":"below","x0":0.5040769732550554,"x1":1,"y0":0,"y1":23.37899543378996,"yanchor":1,"ysizemode":"pixel"}],"xaxis2":{"type":"linear","autorange":false,"range":[-2.749886028006598,57.747606588138552],"tickmode":"array","ticktext":["0","20","40"],"tickvals":[0,20,40],"categoryorder":"array","categoryarray":["0","20","40"],"nticks":null,"ticks":"","tickcolor":null,"ticklen":3.6529680365296811,"tickwidth":0,"showticklabels":true,"tickfont":{"color":"rgba(77,77,77,1)","family":"","size":11.68949771689498},"tickangle":-0,"showline":false,"linecolor":null,"linewidth":0,"showgrid":true,"domain":[0.5040769732550554,1],"gridcolor":"rgba(235,235,235,1)","gridwidth":0.66417600664176002,"zeroline":false,"anchor":"y","title":"","hoverformat":".2f"},"showlegend":true,"legend":{"bgcolor":null,"bordercolor":null,"borderwidth":0,"font":{"color":"rgba(0,0,0,1)","family":"","size":11.68949771689498},"title":{"text":"","font":{"color":"rgba(0,0,0,1)","family":"","size":14.611872146118724}},"orientation":"h","x":0,"xanchor":"right","y":1,"yanchor":"bottom"},"hovermode":"closest","barmode":"relative"},"config":{"doubleClick":"reset","modeBarButtonsToAdd":["hoverclosest","hovercompare"],"showSendToCloud":false,"displayModeBar":false},"source":"A","attrs":{"24302f3e5f2b":{"x":{},"y":{},"fill":{},"text":{},"type":"bar"}},"cur_data":"24302f3e5f2b","visdat":{"24302f3e5f2b":["function (y) ","x"]},"highlight":{"on":"plotly_click","persistent":false,"dynamic":false,"selectize":false,"opacityDim":0.20000000000000001,"selected":{"opacity":1},"debounce":0},"shinyEvents":["plotly_hover","plotly_click","plotly_selected","plotly_relayout","plotly_brushed","plotly_brushing","plotly_clickannotation","plotly_doubleclick","plotly_deselect","plotly_afterplot","plotly_sunburstclick"],"base_url":"https://plot.ly"},"evals":[],"jsHooks":[]}</script>
```


Horas semanais de trabalho e de cuidados e afazeres, por sexo. Fonte: IBGE, PNAD Contínua, 5ª visita, 2022.
:::
:::



::: {.cell}

```{.r .cell-code}
indicadores_sexo_longo |>
  filter(unidade == 'R$') |>
  grafico_indicadores(rotulo_eixo = 'R$ por mês')
```

::: {#fig-rendimento .cell-output-display}

```{=html}
<div class="plotly html-widget html-fill-item" id="htmlwidget-665a3529ae3a60e4f15e" style="width:100%;height:278px;"></div>
<script type="application/json" data-for="htmlwidget-665a3529ae3a60e4f15e">{"x":{"data":[{"orientation":"v","width":2911.5501927390765,"base":0.625,"x":[1455.7750963695382],"y":[0.35000000000000009],"text":"Brasil<br>Homem: 2.912 R$","type":"bar","textposition":"none","marker":{"autocolorscale":false,"color":"rgba(91,74,155,1)","line":{"width":1.8897637795275593,"color":"transparent"}},"name":"Homem","legendgroup":"Homem","showlegend":true,"xaxis":"x","yaxis":"y","hoverinfo":"text","frame":null},{"orientation":"v","width":3491.1376969512376,"base":0.625,"x":[1745.5688484756188],"y":[0.35000000000000009],"text":"Rio de Janeiro<br>Homem: 3.491 R$","type":"bar","textposition":"none","marker":{"autocolorscale":false,"color":"rgba(91,74,155,1)","line":{"width":1.8897637795275593,"color":"transparent"}},"name":"Homem","legendgroup":"Homem","showlegend":false,"xaxis":"x2","yaxis":"y","hoverinfo":"text","frame":null},{"orientation":"v","width":2292.7465917007071,"base":1.0249999999999999,"x":[1146.3732958503535],"y":[0.35000000000000009],"text":"Brasil<br>Mulher: 2.293 R$","type":"bar","textposition":"none","marker":{"autocolorscale":false,"color":"rgba(232,121,58,1)","line":{"width":1.8897637795275593,"color":"transparent"}},"name":"Mulher","legendgroup":"Mulher","showlegend":true,"xaxis":"x","yaxis":"y","hoverinfo":"text","frame":null},{"orientation":"v","width":2876.4491458722318,"base":1.0249999999999999,"x":[1438.2245729361159],"y":[0.35000000000000009],"text":"Rio de Janeiro<br>Mulher: 2.876 R$","type":"bar","textposition":"none","marker":{"autocolorscale":false,"color":"rgba(232,121,58,1)","line":{"width":1.8897637795275593,"color":"transparent"}},"name":"Mulher","legendgroup":"Mulher","showlegend":false,"xaxis":"x2","yaxis":"y","hoverinfo":"text","frame":null}],"layout":{"margin":{"t":44.736681887366814,"r":7.3059360730593621,"b":47.001522070015227,"l":227.21461187214618},"font":{"color":"rgba(0,0,0,1)","family":"","size":14.611872146118724},"xaxis":{"domain":[0,0.49592302674494454],"automargin":true,"type":"linear","autorange":false,"range":[-174.55688484756189,3665.6945817987994],"tickmode":"array","ticktext":["0","1000","2000","3000"],"tickvals":[0,1000,2000,3000],"categoryorder":"array","categoryarray":["0","1000","2000","3000"],"nticks":null,"ticks":"","tickcolor":null,"ticklen":3.6529680365296811,"tickwidth":0,"showticklabels":true,"tickfont":{"color":"rgba(77,77,77,1)","family":"","size":11.68949771689498},"tickangle":-0,"showline":false,"linecolor":null,"linewidth":0,"showgrid":true,"gridcolor":"rgba(235,235,235,1)","gridwidth":0.66417600664176002,"zeroline":false,"anchor":"y","title":"","hoverformat":".2f"},"annotations":[{"text":"R$ por mês","x":0.5,"y":0,"showarrow":false,"ax":0,"ay":0,"font":{"color":"rgba(0,0,0,1)","family":"","size":14.611872146118724},"xref":"paper","yref":"paper","textangle":-0,"xanchor":"center","yanchor":"top","annotationType":"axis","yshift":-21.917808219178081},{"text":"Brasil","x":0.24796151337247227,"y":1,"showarrow":false,"ax":0,"ay":0,"font":{"color":"rgba(26,26,26,1)","family":"","size":11.68949771689498},"xref":"paper","yref":"paper","textangle":-0,"xanchor":"center","yanchor":"bottom"},{"text":"Rio de Janeiro","x":0.7520384866275277,"y":1,"showarrow":false,"ax":0,"ay":0,"font":{"color":"rgba(26,26,26,1)","family":"","size":11.68949771689498},"xref":"paper","yref":"paper","textangle":-0,"xanchor":"center","yanchor":"bottom"}],"yaxis":{"domain":[0,1],"automargin":true,"type":"linear","autorange":false,"range":[0.40000000000000002,1.6000000000000001],"tickmode":"array","ticktext":["Rendimento médio habitual de todos os<br />trabalhos"],"tickvals":[1],"categoryorder":"array","categoryarray":["Rendimento médio habitual de todos os<br />trabalhos"],"nticks":null,"ticks":"","tickcolor":null,"ticklen":3.6529680365296811,"tickwidth":0,"showticklabels":true,"tickfont":{"color":"rgba(77,77,77,1)","family":"","size":11.68949771689498},"tickangle":-0,"showline":false,"linecolor":null,"linewidth":0,"showgrid":false,"gridcolor":null,"gridwidth":0,"zeroline":false,"anchor":"x","title":"","hoverformat":".2f"},"shapes":[{"type":"rect","fillcolor":null,"line":{"color":null,"width":0,"linetype":[]},"yref":"paper","xref":"paper","layer":"below","x0":0,"x1":0.49592302674494454,"y0":0,"y1":1},{"type":"rect","fillcolor":null,"line":{"color":null,"width":0,"linetype":[]},"yref":"paper","xref":"paper","layer":"below","x0":0,"x1":0.49592302674494454,"y0":0,"y1":23.37899543378996,"yanchor":1,"ysizemode":"pixel"},{"type":"rect","fillcolor":null,"line":{"color":null,"width":0,"linetype":[]},"yref":"paper","xref":"paper","layer":"below","x0":0.5040769732550554,"x1":1,"y0":0,"y1":1},{"type":"rect","fillcolor":null,"line":{"color":null,"width":0,"linetype":[]},"yref":"paper","xref":"paper","layer":"below","x0":0.5040769732550554,"x1":1,"y0":0,"y1":23.37899543378996,"yanchor":1,"ysizemode":"pixel"}],"xaxis2":{"type":"linear","autorange":false,"range":[-174.55688484756189,3665.6945817987994],"tickmode":"array","ticktext":["0","1000","2000","3000"],"tickvals":[0,1000,2000,3000],"categoryorder":"array","categoryarray":["0","1000","2000","3000"],"nticks":null,"ticks":"","tickcolor":null,"ticklen":3.6529680365296811,"tickwidth":0,"showticklabels":true,"tickfont":{"color":"rgba(77,77,77,1)","family":"","size":11.68949771689498},"tickangle":-0,"showline":false,"linecolor":null,"linewidth":0,"showgrid":true,"domain":[0.5040769732550554,1],"gridcolor":"rgba(235,235,235,1)","gridwidth":0.66417600664176002,"zeroline":false,"anchor":"y","title":"","hoverformat":".2f"},"showlegend":true,"legend":{"bgcolor":null,"bordercolor":null,"borderwidth":0,"font":{"color":"rgba(0,0,0,1)","family":"","size":11.68949771689498},"title":{"text":"","font":{"color":"rgba(0,0,0,1)","family":"","size":14.611872146118724}},"orientation":"h","x":0,"xanchor":"right","y":1,"yanchor":"bottom"},"hovermode":"closest","barmode":"relative"},"config":{"doubleClick":"reset","modeBarButtonsToAdd":["hoverclosest","hovercompare"],"showSendToCloud":false,"displayModeBar":false},"source":"A","attrs":{"24303a162b6e":{"x":{},"y":{},"fill":{},"text":{},"type":"bar"}},"cur_data":"24303a162b6e","visdat":{"24303a162b6e":["function (y) ","x"]},"highlight":{"on":"plotly_click","persistent":false,"dynamic":false,"selectize":false,"opacityDim":0.20000000000000001,"selected":{"opacity":1},"debounce":0},"shinyEvents":["plotly_hover","plotly_click","plotly_selected","plotly_relayout","plotly_brushed","plotly_brushing","plotly_clickannotation","plotly_doubleclick","plotly_deselect","plotly_afterplot","plotly_sunburstclick"],"base_url":"https://plot.ly"},"evals":[],"jsHooks":[]}</script>
```


Rendimento médio habitual de todos os trabalhos, por sexo. Fonte: IBGE, PNAD Contínua, 5ª visita, 2022.
:::
:::


Os indicadores de comparação já resumem a diferença entre mulheres e homens num número só. Três deles medem a participação das mulheres num grupo de trabalhadores. O gráfico tem uma barra para cada recorte, e uma linha vertical marca os 50%, o ponto em que mulheres e homens estariam em igual número. A razão de rendimento fica só na tabela, porque a sua referência de igualdade é outra: 100%.


::: {.cell}

```{.r .cell-code}
cores_recorte <- c(
  '#8c8c8c',
  scales::brewer_pal(palette = 'Dark2')(8)[seq_len(nrow(ufs_escolhidas))]
) |>
  setNames(levels(pnadc_recortes$recorte))

grafico_comparacao <- indicadores_comparacao_longo |>
  filter(variavel != 'razao_rendimento') |>
  mutate(
    indicador = factor(
      str_wrap(indicador, 38),
      levels = rev(str_wrap(levels(droplevels(indicador)), 38))
    ),
    texto = paste0(recorte, ': ', formata_valor(valor, unidade), '%')
  ) |>
  ggplot(aes(x = valor, y = indicador, fill = recorte, text = texto)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  geom_vline(xintercept = 50, linetype = 'dashed', colour = 'grey40') +
  scale_fill_manual(values = cores_recorte) +
  labs(x = '%', y = NULL, fill = NULL) +
  theme_minimal() +
  theme(legend.position = 'top', panel.grid.major.y = element_blank())

ggplotly(grafico_comparacao, tooltip = 'text') |>
  layout(legend = legenda_topo) |>
  config(displayModeBar = FALSE)
```

::: {#fig-comparacao .cell-output-display}

```{=html}
<div class="plotly html-widget html-fill-item" id="htmlwidget-e551bf8b1b296912bfcb" style="width:100%;height:390px;"></div>
<script type="application/json" data-for="htmlwidget-e551bf8b1b296912bfcb">{"x":{"data":[{"orientation":"v","width":[39.532924603302,40.683453203033082,91.505185339660699],"base":[2.625,1.625,0.625],"x":[19.766462301651,20.341726601516541,45.752592669830349],"y":[0.34999999999999964,0.35000000000000009,0.35000000000000009],"text":["Brasil: 39,5%","Brasil: 40,7%","Brasil: 91,5%"],"type":"bar","textposition":"none","marker":{"autocolorscale":false,"color":"rgba(140,140,140,1)","line":{"width":1.8897637795275593,"color":"transparent"}},"name":"Brasil","legendgroup":"Brasil","showlegend":true,"xaxis":"x","yaxis":"y","hoverinfo":"text","frame":null},{"orientation":"v","width":[38.027029611536371,37.682753822698487,90.65357620726418],"base":[3.0250000000000004,2.0250000000000004,1.0249999999999999],"x":[19.013514805768185,18.841376911349244,45.32678810363209],"y":[0.34999999999999964,0.34999999999999964,0.35000000000000009],"text":["Rio de Janeiro: 38,0%","Rio de Janeiro: 37,7%","Rio de Janeiro: 90,7%"],"type":"bar","textposition":"none","marker":{"autocolorscale":false,"color":"rgba(27,158,119,1)","line":{"width":1.8897637795275593,"color":"transparent"}},"name":"Rio de Janeiro","legendgroup":"Rio de Janeiro","showlegend":true,"xaxis":"x","yaxis":"y","hoverinfo":"text","frame":null},{"x":[50,50],"y":[0.40000000000000002,3.6000000000000001],"text":"","type":"scatter","mode":"lines","line":{"width":1.8897637795275593,"color":"rgba(102,102,102,1)","dash":"dash"},"hoveron":"points","showlegend":false,"xaxis":"x","yaxis":"y","hoverinfo":"text","frame":null}],"layout":{"margin":{"t":28.182603079642412,"r":7.3059360730593621,"b":42.136940979185795,"l":233.05936073059365},"font":{"color":"rgba(0,0,0,1)","family":"","size":14.611872146118724},"xaxis":{"domain":[0,1],"automargin":true,"type":"linear","autorange":false,"range":[-4.5752592669830348,96.080444606643738],"tickmode":"array","ticktext":["0","25","50","75"],"tickvals":[0,25,50,75],"categoryorder":"array","categoryarray":["0","25","50","75"],"nticks":null,"ticks":"","tickcolor":null,"ticklen":3.6529680365296811,"tickwidth":0,"showticklabels":true,"tickfont":{"color":"rgba(77,77,77,1)","family":"","size":11.68949771689498},"tickangle":-0,"showline":false,"linecolor":null,"linewidth":0,"showgrid":true,"gridcolor":"rgba(235,235,235,1)","gridwidth":0.66417600664176002,"zeroline":false,"anchor":"y","title":{"text":"%","font":{"color":"rgba(0,0,0,1)","family":"","size":14.611872146118724}},"hoverformat":".2f"},"yaxis":{"domain":[0,1],"automargin":true,"type":"linear","autorange":false,"range":[0.40000000000000002,3.6000000000000001],"tickmode":"array","ticktext":["Mulheres entre os trabalhadores<br />domésticos","Mulheres em todos os cargos gerenciais<br />(4.3)","Mulheres na gerência sênior e<br />intermediária (4.3)"],"tickvals":[1,2,3],"categoryorder":"array","categoryarray":["Mulheres entre os trabalhadores<br />domésticos","Mulheres em todos os cargos gerenciais<br />(4.3)","Mulheres na gerência sênior e<br />intermediária (4.3)"],"nticks":null,"ticks":"","tickcolor":null,"ticklen":3.6529680365296811,"tickwidth":0,"showticklabels":true,"tickfont":{"color":"rgba(77,77,77,1)","family":"","size":11.68949771689498},"tickangle":-0,"showline":false,"linecolor":null,"linewidth":0,"showgrid":false,"gridcolor":null,"gridwidth":0,"zeroline":false,"anchor":"x","title":{"text":"","font":{"color":"rgba(0,0,0,1)","family":"","size":14.611872146118724}},"hoverformat":".2f"},"shapes":[{"type":"rect","fillcolor":null,"line":{"color":null,"width":0,"linetype":[]},"yref":"paper","xref":"paper","layer":"below","x0":0,"x1":1,"y0":0,"y1":1}],"showlegend":true,"legend":{"bgcolor":null,"bordercolor":null,"borderwidth":0,"font":{"color":"rgba(0,0,0,1)","family":"","size":11.68949771689498},"title":{"text":"","font":{"color":"rgba(0,0,0,1)","family":"","size":14.611872146118724}},"orientation":"h","x":0,"xanchor":"right","y":1,"yanchor":"bottom"},"hovermode":"closest","barmode":"relative"},"config":{"doubleClick":"reset","modeBarButtonsToAdd":["hoverclosest","hovercompare"],"showSendToCloud":false,"displayModeBar":false},"source":"A","attrs":{"24301d28217e":{"x":{},"y":{},"fill":{},"text":{},"type":"bar"},"24304e8a7f2":{"xintercept":{}}},"cur_data":"24301d28217e","visdat":{"24301d28217e":["function (y) ","x"],"24304e8a7f2":["function (y) ","x"]},"highlight":{"on":"plotly_click","persistent":false,"dynamic":false,"selectize":false,"opacityDim":0.20000000000000001,"selected":{"opacity":1},"debounce":0},"shinyEvents":["plotly_hover","plotly_click","plotly_selected","plotly_relayout","plotly_brushed","plotly_brushing","plotly_clickannotation","plotly_doubleclick","plotly_deselect","plotly_afterplot","plotly_sunburstclick"],"base_url":"https://plot.ly"},"evals":[],"jsHooks":[]}</script>
```


Participação das mulheres em grupos de trabalhadores. Fonte: IBGE, PNAD Contínua, 5ª visita, 2022.
:::
:::


::: {.callout-tip}
## O que o gráfico interativo permite
- **Passar o mouse** sobre uma barra mostra o recorte, o sexo e o valor exato.
- **Clicar num item da legenda** esconde ou mostra aquela série.
- **Clicar duas vezes** num item da legenda isola só ele.

Para um relatório em PDF ou Word, basta fazer a função devolver o objeto `grafico` em vez de chamar o `ggplotly()`: o gráfico sai estático.
:::

## 6. O desenho amostral

O bloco 5 calculou as estimativas pontuais com o `dplyr`. Este bloco responde à pergunta que ficou em aberto: **o quanto confiar em cada número?** Para isso, é preciso dizer ao R como a amostra da PNAD Contínua foi sorteada.

### Por que o desenho importa

A PNAD Contínua não sorteia pessoas uma a uma. A amostra é selecionada em etapas:

- **Estratos:** o país é dividido em estratos geográficos, e cada estrato tem a sua própria amostra.
- **Unidades primárias de amostragem (UPA):** dentro de cada estrato, são sorteados setores censitários.
- **Domicílios:** dentro de cada UPA, são sorteados domicílios, e todos os moradores são entrevistados.

Pessoas da mesma UPA e do mesmo domicílio tendem a ser parecidas entre si: moram perto, têm renda próxima, dividem as tarefas da casa. Por isso, cada pessoa entrevistada traz menos informação nova do que traria numa amostra sorteada pessoa a pessoa. Ignorar essa estrutura faz o erro-padrão parecer **menor do que é**, e a estimativa parecer mais precisa do que é.

O pacote `srvyr` guarda essa estrutura num objeto de **desenho amostral**, e calcula as estimativas e as medidas de precisão levando-a em conta.

### O desenho com a calibração refeita

O desenho deste relatório parte do peso sem calibração (`V1031`), declara os dois estágios de seleção (`UPA` e `ID_DOMICILIO`) e os estratos (`Estrato`), e **refaz a calibração** pelas projeções de população: por domínio geográfico (`posest`, com os totais de `V1030`) e por sexo e idade (`posest_sxi`, com os totais de `V1034`). É o que faz a função `pnadc_design()`, do pacote `PNADcIBGE`. A calibração faz os totais estimados baterem com as projeções e reduz a variância das estimativas.

Criar esse desenho leva alguns minutos, porque a calibração é refeita para as 380 mil pessoas da amostra. Por isso, ele é criado uma única vez, gravado num arquivo `.rds` e publicado no Zenodo junto com a base. Em sala, o desenho é só lido.


::: {.cell}

```{.r .cell-code}
# Executado só com gerar_base: true, depois das variáveis do bloco 4
desenho_calibrado <- pnadc |>
  mutate(
    ocupada = if_else(condicao_atividade %in% 'Ocupada', 1, 0),
    desocupada = if_else(condicao_atividade %in% 'Desocupada', 1, 0),
    forca_trabalho = ocupada + desocupada,
    idade_15_mais = if_else(V2009 >= 15, 1, 0)
  ) |>
  PNADcIBGE::pnadc_design()

saveRDS(desenho_calibrado, arquivo_desenho)
```
:::


::: {.callout-warning}
## O desenho guarda as variáveis do bloco 4
O arquivo do desenho é gravado depois do bloco 4 e leva junto as variáveis derivadas (sexo, cor ou raça, condição de atividade, informalidade e as demais) e as dummies acima. Se o código do bloco 4 mudar, o desenho precisa ser gerado de novo, com `gerar_base: true`.
:::


::: {.cell}

```{.r .cell-code}
# Arquivo local, se existir; senão, o link do Zenodo
desenho <- localiza_arquivo(arquivo_desenho, params$url_desenho) |>
  readRDS() |>
  as_survey() # converte o objeto do pacote survey para usar com o srvyr

desenho
```

::: {.cell-output .cell-output-stdout}

```
Stratified 2 - level Cluster Sampling design (with replacement)
With (12018, 135510) clusters.
Called via srvyr
Data variables: 
  - Ano (int), Trimestre (int), UPA (chr), V1008 (chr), V1014 (chr), V2003
    (int), UF (int), V1022 (int), V1023 (int), Estrato (chr), ID_DOMICILIO
    (chr), V1031 (dbl), V1032 (dbl), posest (chr), V1030 (dbl), posest_sxi
    (chr), V1034 (dbl), V2005 (int), V2007 (int), V2009 (int), V2010 (int),
    V3002 (int), VD3004 (int), VD3005 (int), VD4001 (int), VD4002 (int), VD4009
    (int), V4019 (int), VD4012 (int), VD4010 (int), VD4011 (int), V4010 (chr),
    VD4019 (dbl), VD4031 (int), VD5008 (dbl), V4117A (int), V4119 (int), V4120
    (int), V4121A (int), V4121B (int), sexo (fct), cor_raca (fct), faixa_etaria
    (fct), escolaridade (fct), regiao (fct), territorio (fct), situacao (fct),
    condicao_atividade (fct), realizou_cuidados (dbl), realizou_afazeres (dbl),
    crianca_ate_6 (dbl), informal (dbl), atividade_agricola (dbl), setor (fct),
    subgrupo_ocupacao (chr), cargo_gerencial (dbl), cargo_gerencial_total
    (dbl), ocupada (dbl), desocupada (dbl), forca_trabalho (dbl), idade_15_mais
    (dbl)
```


:::
:::


::: {.callout-note}
## Um erro-padrão um pouco diferente do divulgado pelo IBGE
O IBGE calcula a precisão das suas estimativas com **200 pesos replicados**, obtidos por *bootstrap*. Este relatório refaz a calibração e calcula a variância por **linearização**. Os dois métodos estimam a mesma variância por caminhos diferentes, e por isso os erros-padrão, os intervalos de confiança e os coeficientes de variação daqui podem ficar um pouco diferentes dos divulgados. **Essa diferença não é um erro.** As estimativas pontuais são idênticas. A seção "Três formas de calcular a precisão", no fim deste bloco, compara os métodos.
:::

### A mesma taxa, agora com a precisão

A taxa de participação na força de trabalho do bloco 5, calculada agora no desenho. O `survey_mean()` de uma dummy é a sua média ponderada, ou seja, a taxa. Junto com ela, o `srvyr` devolve:

- o **erro-padrão (EP)**: o tamanho típico do erro da estimativa, por ela vir de uma amostra;
- o **intervalo de confiança de 95% (IC)**: a faixa de valores que, em 95% das amostras possíveis, conteria o valor da população;
- o **coeficiente de variação (CV)**: o erro-padrão como porcentagem da estimativa. Ele permite comparar a precisão de estimativas de tamanhos diferentes.

Para as UFs, o recorte é feito **no desenho**, e não na base. A base empilhada do bloco 5 não serve aqui: nela, as pessoas das UFs escolhidas aparecem duas vezes, e o desenho as contaria em dobro.

No desenho, cada UF é um **domínio**. Um `filter()` no desenho não apaga as pessoas de fora: elas continuam lá, com peso zero, porque o erro-padrão depende de toda a amostra (estratos e UPAs). Por isso, um `filter()` seguido de `group_by(UF)` ainda cria um grupo para cada UF do país, e os grupos sem peso dão erro. O código junta as UFs que não estão na lista num só domínio (com a `UF` igual a `NA`), estima tudo de uma vez e descarta esse domínio no fim.


::: {.cell}

```{.r .cell-code}
# Estimativa com erro-padrão, intervalo de confiança e CV, por sexo
estima_participacao <- function(desenho) {
  desenho |>
    filter(V2009 >= 15) |>
    group_by(sexo, .add = TRUE) |>
    summarise(
      taxa = survey_mean(forca_trabalho, vartype = c('se', 'ci', 'cv'))
    )
}

participacao_desenho <- bind_rows(
  desenho |>
    estima_participacao() |>
    mutate(recorte = 'Brasil'),
  desenho |>
    # UFs fora da lista viram um só domínio (NA), descartado no inner_join
    mutate(UF = if_else(UF %in% ufs_escolhidas$UF, UF, NA)) |>
    group_by(UF) |>
    estima_participacao() |>
    inner_join(ufs_escolhidas, by = 'UF') |>
    mutate(recorte = nome_uf)
) |>
  mutate(
    recorte = factor(recorte, levels = levels(pnadc_recortes$recorte)),
    # Taxa, erro-padrão, limites do IC e CV passam para %
    across(starts_with('taxa'), \(valor) valor * 100)
  ) |>
  select(recorte, sexo, starts_with('taxa'))
```
:::



::: {#tbl-participacao-desenho .cell tbl-cap='Taxa de participação na força de trabalho das pessoas de 15 anos ou mais (CMIG 1.3), com medidas de precisão, por sexo. Fonte: IBGE, PNAD Contínua, 5ª visita, 2022.'}

```{.r .cell-code}
participacao_desenho |>
  # A taxa calculada com o dplyr no bloco 5, para comparar
  left_join(
    participacao |> select(recorte, sexo, com_peso),
    by = c('recorte', 'sexo')
  ) |>
  arrange(recorte, sexo) |>
  select(
    recorte, sexo, com_peso, taxa, taxa_se, taxa_low, taxa_upp, taxa_cv
  ) |>
  knitr::kable(
    digits = c(0, 0, 1, 1, 2, 1, 1, 2),
    format.args = list(decimal.mark = ','),
    col.names = c(
      'Recorte', 'Sexo', 'Taxa com dplyr (%)', 'Taxa com srvyr (%)',
      'EP (p.p.)', 'IC 95%: inferior', 'IC 95%: superior', 'CV (%)'
    )
  )
```

::: {.cell-output-display}


|Recorte        |Sexo   | Taxa com dplyr (%)| Taxa com srvyr (%)| EP (p.p.)| IC 95%: inferior| IC 95%: superior| CV (%)|
|:--------------|:------|------------------:|------------------:|---------:|----------------:|----------------:|------:|
|Brasil         |Homem  |               73,0|               73,0|      0,14|             72,8|             73,3|   0,19|
|Brasil         |Mulher |               53,4|               53,4|      0,17|             53,0|             53,7|   0,32|
|Rio de Janeiro |Homem  |               71,2|               71,2|      0,54|             70,1|             72,3|   0,76|
|Rio de Janeiro |Mulher |               52,1|               52,1|      0,65|             50,8|             53,3|   1,24|


:::
:::


As colunas "Taxa com dplyr" e "Taxa com srvyr" são iguais: o peso já acertava a estimativa pontual. O que o desenho acrescenta são as outras colunas. Na UF, a amostra é menor, e o erro-padrão e o CV são maiores que os do Brasil.

### A taxa como razão

Na seção "Os estimadores", a taxa foi escrita como a razão entre dois totais: o total de pessoas do numerador e o total de pessoas do denominador. O `survey_ratio()` calcula exatamente essa razão, com as dummies do numerador e do denominador, sem precisar de `filter()`:


::: {.cell}

```{.r .cell-code}
desenho |>
  group_by(sexo) |>
  summarise(
    taxa = survey_ratio(
      numerator = forca_trabalho * idade_15_mais, # numerador: N
      denominator = idade_15_mais, # denominador: D
      vartype = c('se', 'cv')
    )
  ) |>
  mutate(across(starts_with('taxa'), \(valor) valor * 100)) |>
  knitr::kable(
    digits = c(0, 1, 2, 2),
    format.args = list(decimal.mark = ','),
    col.names = c('Sexo', 'Taxa (%)', 'EP (p.p.)', 'CV (%)')
  )
```

::: {.cell-output-display}


|Sexo   | Taxa (%)| EP (p.p.)| CV (%)|
|:------|--------:|---------:|------:|
|Homem  |     73,0|      0,14|   0,19|
|Mulher |     53,4|      0,17|   0,32|


:::
:::


O resultado é o mesmo da tabela anterior para o Brasil, inclusive o erro-padrão. Calcular uma taxa num grupo da população é calcular uma razão: as duas formas são equivalentes.

### Os intervalos de confiança no gráfico

O gráfico mostra cada taxa como um ponto, e o intervalo de confiança como uma linha horizontal em torno dele. Intervalos mais longos indicam estimativas menos precisas.


::: {.cell}

```{.r .cell-code}
grafico_ic <- participacao_desenho |>
  mutate(
    recorte = factor(recorte, levels = rev(levels(recorte))),
    unidade = '%',
    texto = paste0(
      recorte, '<br>', sexo, ': ', formata_valor(taxa, unidade), '%',
      '<br>IC 95%: ', formata_valor(taxa_low, unidade), '% a ',
      formata_valor(taxa_upp, unidade), '%'
    )
  ) |>
  ggplot(aes(
    x = taxa, xmin = taxa_low, xmax = taxa_upp, y = recorte,
    colour = sexo, text = texto
  )) +
  geom_pointrange(position = position_dodge(width = 0.5)) +
  scale_colour_manual(values = cores_sexo) +
  labs(x = 'Taxa de participação (%)', y = NULL, colour = NULL) +
  theme_minimal() +
  theme(panel.grid.major.y = element_blank())

ggplotly(grafico_ic, tooltip = 'text') |>
  layout(legend = legenda_topo) |>
  config(displayModeBar = FALSE)
```

::: {#fig-participacao-ic .cell-output-display}

```{=html}
<div class="plotly html-widget html-fill-item" id="htmlwidget-f99397a7812a7eb351e4" style="width:100%;height:278px;"></div>
<script type="application/json" data-for="htmlwidget-f99397a7812a7eb351e4">{"x":{"data":[{"x":[73.034216043691444,71.206551514726101],"y":[1.875,0.875],"text":["Brasil<br>Homem: 73,0%<br>IC 95%: 72,8% a 73,3%","Rio de Janeiro<br>Homem: 71,2%<br>IC 95%: 70,1% a 72,3%"],"type":"scatter","mode":"lines+markers","opacity":1,"line":{"color":"transparent"},"error_x":{"array":[0.27910490607912664,1.0583541719663714],"arrayminus":[0.27910490607912664,1.0583541719663714],"type":"data","width":0,"symmetric":false,"color":"rgba(91,74,155,1)"},"name":"Homem","legendgroup":"Homem","showlegend":true,"xaxis":"x","yaxis":"y","hoverinfo":"text","marker":{"autocolorscale":false,"color":"rgba(91,74,155,1)","opacity":1,"size":1.8897637795275593,"symbol":"circle","line":{"width":3.7795275590551185,"color":"rgba(91,74,155,1)"}},"hoveron":"points","frame":null},{"x":[53.373036144775554,52.069751952938489],"y":[2.125,1.125],"text":["Brasil<br>Mulher: 53,4%<br>IC 95%: 53,0% a 53,7%","Rio de Janeiro<br>Mulher: 52,1%<br>IC 95%: 50,8% a 53,3%"],"type":"scatter","mode":"lines+markers","opacity":1,"line":{"color":"transparent"},"error_x":{"array":[0.33539567075791865,1.2696648434706219],"arrayminus":[0.33539567075791865,1.2696648434706148],"type":"data","width":0,"symmetric":false,"color":"rgba(232,121,58,1)"},"name":"Mulher","legendgroup":"Mulher","showlegend":true,"xaxis":"x","yaxis":"y","hoverinfo":"text","marker":{"autocolorscale":false,"color":"rgba(232,121,58,1)","opacity":1,"size":1.8897637795275593,"symbol":"circle","line":{"width":3.7795275590551185,"color":"rgba(232,121,58,1)"}},"hoveron":"points","frame":null}],"layout":{"margin":{"t":33.047184170471837,"r":7.3059360730593621,"b":47.001522070015227,"l":92.785388127853906},"font":{"color":"rgba(0,0,0,1)","family":"","size":14.611872146118724},"xaxis":{"domain":[0,1],"automargin":true,"type":"linear","autorange":false,"range":[49.674425417452738,74.438982641785699],"tickmode":"array","ticktext":["50","55","60","65","70"],"tickvals":[50,55,60,65,70],"categoryorder":"array","categoryarray":["50","55","60","65","70"],"nticks":null,"ticks":"","tickcolor":null,"ticklen":3.6529680365296811,"tickwidth":0,"showticklabels":true,"tickfont":{"color":"rgba(77,77,77,1)","family":"","size":11.68949771689498},"tickangle":-0,"showline":false,"linecolor":null,"linewidth":0,"showgrid":true,"gridcolor":"rgba(235,235,235,1)","gridwidth":0.66417600664176002,"zeroline":false,"anchor":"y","title":{"text":"Taxa de participação (%)","font":{"color":"rgba(0,0,0,1)","family":"","size":14.611872146118724}},"hoverformat":".2f"},"yaxis":{"domain":[0,1],"automargin":true,"type":"linear","autorange":false,"range":[0.40000000000000002,2.6000000000000001],"tickmode":"array","ticktext":["Rio de Janeiro","Brasil"],"tickvals":[1,2],"categoryorder":"array","categoryarray":["Rio de Janeiro","Brasil"],"nticks":null,"ticks":"","tickcolor":null,"ticklen":3.6529680365296811,"tickwidth":0,"showticklabels":true,"tickfont":{"color":"rgba(77,77,77,1)","family":"","size":11.68949771689498},"tickangle":-0,"showline":false,"linecolor":null,"linewidth":0,"showgrid":false,"gridcolor":null,"gridwidth":0,"zeroline":false,"anchor":"x","title":{"text":"","font":{"color":"rgba(0,0,0,1)","family":"","size":14.611872146118724}},"hoverformat":".2f"},"shapes":[{"type":"rect","fillcolor":null,"line":{"color":null,"width":0,"linetype":[]},"yref":"paper","xref":"paper","layer":"below","x0":0,"x1":1,"y0":0,"y1":1}],"showlegend":true,"legend":{"bgcolor":null,"bordercolor":null,"borderwidth":0,"font":{"color":"rgba(0,0,0,1)","family":"","size":11.68949771689498},"title":{"text":"","font":{"color":"rgba(0,0,0,1)","family":"","size":14.611872146118724}},"orientation":"h","x":0,"xanchor":"right","y":1,"yanchor":"bottom"},"hovermode":"closest","barmode":"relative"},"config":{"doubleClick":"reset","modeBarButtonsToAdd":["hoverclosest","hovercompare"],"showSendToCloud":false,"displayModeBar":false},"source":"A","attrs":{"24304f6a371":{"x":{},"y":{},"xmin":{},"xmax":{},"colour":{},"text":{},"type":"scatter"}},"cur_data":"24304f6a371","visdat":{"24304f6a371":["function (y) ","x"]},"highlight":{"on":"plotly_click","persistent":false,"dynamic":false,"selectize":false,"opacityDim":0.20000000000000001,"selected":{"opacity":1},"debounce":0},"shinyEvents":["plotly_hover","plotly_click","plotly_selected","plotly_relayout","plotly_brushed","plotly_brushing","plotly_clickannotation","plotly_doubleclick","plotly_deselect","plotly_afterplot","plotly_sunburstclick"],"base_url":"https://plot.ly"},"evals":[],"jsHooks":[]}</script>
```


Taxa de participação na força de trabalho das pessoas de 15 anos ou mais, por sexo, com intervalo de confiança de 95%. Fonte: IBGE, PNAD Contínua, 5ª visita, 2022.
:::
:::


### Três formas de calcular a precisão

A calibração refeita não é a única forma de calcular a precisão com esta base. Há outras duas:

- **pesos replicados**: os 200 pesos obtidos pelo IBGE por *bootstrap*, cada um já calibrado. É o método das divulgações oficiais. Exige um arquivo à parte, com os 200 pesos de cada pessoa, e cada estimativa é calculada 201 vezes;
- **`V1032` direto**: o desenho declara estratos e UPAs e usa o peso já calibrado, sem refazer a calibração. É a forma mais simples, e o erro-padrão sai um pouco maior que o oficial, ou seja, conservador.

O bloco abaixo compara as três formas para a mesma estimativa: as horas semanais em cuidados e afazeres domésticos, por sexo, no Brasil.

Pré-calculado: só roda com `gerar_base: true`, porque usa os pesos replicados e refaz a calibração, o que leva alguns minutos. Em sala, os alunos veem o resultado guardado.


::: {.cell cache.extra='[2022,5,["Ano","Trimestre","UPA","V1008","V1014","V2003","UF","V1022","V1023","Estrato","ID_DOMICILIO","V1031","V1032","posest","V1030","posest_sxi","V1034","V2005","V2007","V2009","V2010","V3002","VD3004","VD3005","VD4001","VD4002","VD4009","V4019","VD4012","VD4010","VD4011","V4010","VD4019","VD4031","VD5008","V4117A","V4119","V4120","V4121A","V4121B"]]'}

```{.r .cell-code}
# Mede o tempo de uma expressão, em segundos
cronometra <- function(expressao) {
  system.time(expressao)[['elapsed']]
}

# A estimativa a comparar, para qualquer desenho
horas_afazeres <- function(desenho) {
  desenho |>
    filter(V2009 >= 14) |>
    group_by(sexo) |>
    summarise(horas = survey_mean(V4121B, na.rm = TRUE, vartype = c('se', 'cv')))
}

# Pesos replicados: a chave da pessoa e os 200 pesos, gravados no bloco 3
tipos_replicas <- cols(.default = col_double())
tipos_replicas$cols[intersect(vars_chave, vars_texto)] <- list(col_character())
tipos_replicas$cols[setdiff(vars_chave, vars_texto)] <- list(col_integer())

replicas <- read_csv(
  arquivo_replicas,
  col_types = tipos_replicas,
  col_select = all_of(c(vars_chave, vars_replicas)),
  progress = FALSE
)

# 1. Calibração refeita: o desenho usado em sala, recriado para medir o tempo
#    (a base vai sem as réplicas: com elas, o pnadc_design() usaria as réplicas)
tempo_criar_1 <- cronometra(
  desenho_1 <- as_survey(PNADcIBGE::pnadc_design(pnadc))
)
tempo_estimar_1 <- cronometra(resultado_1 <- horas_afazeres(desenho_1))

# 2. Pesos replicados (bootstrap), o método do IBGE
tempo_criar_2 <- cronometra(desenho_2 <- as_survey_rep(
  pnadc |> inner_join(replicas, by = vars_chave),
  weights = V1032, repweights = matches('^V1032[0-9]{3}$'),
  type = 'bootstrap', mse = TRUE
))
tempo_estimar_2 <- cronometra(resultado_2 <- horas_afazeres(desenho_2))

# 3. V1032 direto, sem refazer a calibração. Estratos com uma única UPA na
#    amostra: a variância é aproximada a partir da média geral
options(survey.lonely.psu = 'adjust')
tempo_criar_3 <- cronometra(desenho_3 <- as_survey_design(
  pnadc,
  ids = c(UPA, ID_DOMICILIO), strata = Estrato, weights = V1032, nest = TRUE
))
tempo_estimar_3 <- cronometra(resultado_3 <- horas_afazeres(desenho_3))

comparacao_metodos <- bind_rows(
  resultado_1 |> mutate(metodo = 'Calibração refeita (em sala)',
                        criar = tempo_criar_1, estimar = tempo_estimar_1),
  resultado_2 |> mutate(metodo = 'Pesos replicados (IBGE)',
                        criar = tempo_criar_2, estimar = tempo_estimar_2),
  resultado_3 |> mutate(metodo = 'V1032 direto',
                        criar = tempo_criar_3, estimar = tempo_estimar_3)
) |>
  mutate(horas_cv = horas_cv * 100) |>
  select(metodo, sexo, horas, horas_se, horas_cv, criar, estimar)

comparacao_metodos |>
  knitr::kable(
    digits = c(0, 0, 2, 4, 2, 0, 0),
    format.args = list(decimal.mark = ','),
    col.names = c(
      'Método', 'Sexo', 'Horas por semana', 'EP (horas)', 'CV (%)',
      'Tempo para criar o desenho (s)', 'Tempo para estimar (s)'
    )
  )
```
:::


As estimativas são idênticas nos três métodos, porque todos usam o mesmo peso calibrado. O erro-padrão muda pouco, e o tempo de processamento muda bastante. O relatório usa a calibração refeita porque ela fica próxima do método do IBGE e permite estimar em segundos, com o desenho gravado num arquivo e só lido em sala.

## 7. Indicadores

### Trabalho e renda


::: {.cell}

```{.r .cell-code}
# TODO: taxa de participação (1.8), taxa de desocupação (1.10),
#       informalidade (1.9) e razão de rendimentos por grupo ocupacional (1.13)
```
:::


### Educação


::: {.cell}

```{.r .cell-code}
# TODO: nível de instrução da população de 25 anos ou mais (2.11)
```
:::


### Trabalho não remunerado e domicílio


::: {.cell}

```{.r .cell-code}
# TODO: horas semanais em cuidados e afazeres domésticos (1.1), também por
#       classes de rendimento domiciliar per capita (VD5008)
```
:::


### Validação com o IBGE


::: {.cell}

```{.r .cell-code}
# TODO: comparar os resultados calculados com os números do informativo.
#       A publicação se refere a 2022: rodar só quando params$ano == 2022
```
:::


## 8. Comparações

### Recorte territorial e precisão


::: {.cell}

```{.r .cell-code}
# TODO: Brasil, UFs selecionadas e capital, resto da RM e interior,
#       com semáforo de CV
```
:::


### Testes de hipóteses


::: {.cell}

```{.r .cell-code}
# TODO: teste t com desenho e qui-quadrado de Rao-Scott
```
:::


### Regressão com desenho amostral


::: {.cell}

```{.r .cell-code}
# TODO: sequência de modelos com svyglm e gráfico de coeficientes
```
:::


## 9. Seu indicador

*Espaço para o indicador criado na atividade do Dia 2.*


::: {.cell}

```{.r .cell-code}
# TODO: indicador criado pela dupla
```
:::


