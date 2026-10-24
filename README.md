# Indicadores de desigualdade de gênero com a PNAD Contínua em R

**[Acesse o site do minicurso para os materiais completos.](https://lincolntsilva.github.io/desigualdade-genero-pnadc/)**

## Sobre o minicurso

Minicurso de 6 horas, em 2 encontros de 3 horas, sobre como construir, estimar e interpretar indicadores de desigualdade de gênero com os microdados da PNAD Contínua do IBGE, em um fluxo reprodutível com R e Quarto.

Os indicadores seguem o Conjunto Mínimo de Indicadores de Gênero (CMIG) das Nações Unidas e a publicação *Estatísticas de Gênero* do IBGE. O curso usa os microdados trimestrais da PNAD Contínua e trata o desenho amostral com os pacotes `survey` e `srvyr`.

## Estrutura do repositório

| Arquivo | Conteúdo |
|---|---|
| `index.qmd` | Página inicial do site |
| `dia1.qmd`, `dia2.qmd` | Material de aula de cada dia |
| `relatorio.qmd` | Relatório final, parametrizado por ano, trimestre e UF |
| `preparacao.qmd`, `dados.qmd`, `materiais.qmd`, `referencias.qmd`, `about.qmd` | Demais páginas do site |
| `_quarto.yml`, `tema.scss`, `styles.css` | Configuração e aparência do site |
| `_freeze/` | Resultados guardados dos cálculos, usados na publicação do site |

Os dados não ficam no repositório: a base do curso e o desenho amostral são publicados no [Zenodo](https://doi.org/10.5281/zenodo.23552883).

## Como gerar o site

Com R, Quarto e os pacotes do curso instalados (veja a página [Preparação](https://lincolntsilva.github.io/desigualdade-genero-pnadc/preparacao.html)):

```bash
quarto render
```
