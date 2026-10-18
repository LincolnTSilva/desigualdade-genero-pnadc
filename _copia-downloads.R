# Roda depois de cada renderização (post-render no _quarto.yml).
# Copia o relatório para a pasta downloads/ do site, para que o link
# "Baixar o relatório" entregue o arquivo .qmd, e não a página .html.

pasta_site <- Sys.getenv('QUARTO_PROJECT_OUTPUT_DIR', '_site')
pasta_downloads <- file.path(pasta_site, 'downloads')

dir.create(pasta_downloads, showWarnings = FALSE, recursive = TRUE)
file.copy('relatorio.qmd', pasta_downloads, overwrite = TRUE)
